// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — GoogleFitnessService
//
//  Reads real fitness data (steps, calories, active minutes, heart rate)
//  from Google Fitness REST API using platform-specific API keys:
//
//    iOS    → AIzaSyBNtUPSjiSxEBmg86CxJt1n194GJ93v9ts
//    Android → AIzaSyAWykgqQEIc9EEcIQ_9mC_LK7RA_m7gVYU
//
//  Auth flow:
//    1. google_sign_in signs user in with FITNESS scopes
//    2. getAuthHeaders() returns Bearer token
//    3. REST calls to https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate
//
//  Data returned:
//    • steps          — com.google.step_count.delta
//    • calories       — com.google.calories.expended
//    • active minutes — com.google.active_minutes
//    • heart rate     — com.google.heart_rate.bpm
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// Fitness data snapshot for a single day
class FitnessSnapshot {
  final int    steps;
  final double caloriesBurned;
  final int    activeMinutes;
  final double heartRateBpm;   // 0 if unavailable
  final DateTime fetchedAt;

  const FitnessSnapshot({
    required this.steps,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.heartRateBpm,
    required this.fetchedAt,
  });

  factory FitnessSnapshot.empty() => FitnessSnapshot(
    steps: 0, caloriesBurned: 0, activeMinutes: 0,
    heartRateBpm: 0, fetchedAt: DateTime.now(),
  );
}

class GoogleFitnessService {
  GoogleFitnessService._();
  static final GoogleFitnessService instance = GoogleFitnessService._();

  // ── Platform-specific API keys ───────────────────────────────────────────
  static const _iosApiKey     = 'AIzaSyBNtUPSjiSxEBmg86CxJt1n194GJ93v9ts';
  static const _androidApiKey = 'AIzaSyAWykgqQEIc9EEcIQ_9mC_LK7RA_m7gVYU';

  static String get _apiKey {
    // Web preview always uses Android key as fallback
    if (kIsWeb) return _androidApiKey;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _iosApiKey;
      default:
        return _androidApiKey;
    }
  }

  // ── Google Sign-In scopes for Fitness API ────────────────────────────────
  static const _fitnessScopes = [
    'https://www.googleapis.com/auth/fitness.activity.read',
    'https://www.googleapis.com/auth/fitness.body.read',
    'https://www.googleapis.com/auth/fitness.heart_rate.read',
  ];

  late final GoogleSignIn _gsi = GoogleSignIn(
    scopes: _fitnessScopes,
  );

  GoogleSignInAccount? _account;
  bool get isSignedIn => _account != null;

  // ── Sign in / Sign out ───────────────────────────────────────────────────

  /// Sign in silently first (re-use existing session); falls back to interactive.
  Future<bool> signIn() async {
    try {
      _account = await _gsi.signInSilently();
      _account ??= await _gsi.signIn();
      debugPrint('[Fitness] Signed in as: ${_account?.email}');
      return _account != null;
    } catch (e) {
      debugPrint('[Fitness] signIn error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _gsi.signOut();
    _account = null;
  }

  // ── Auth headers ─────────────────────────────────────────────────────────
  Future<Map<String, String>?> _getHeaders() async {
    if (_account == null) return null;
    try {
      final auth = await _account!.authentication;
      final token = auth.accessToken;
      if (token == null) return null;
      return {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      };
    } catch (e) {
      debugPrint('[Fitness] getHeaders error: $e');
      return null;
    }
  }

  // ── Fitness REST API ─────────────────────────────────────────────────────

  static const _baseUrl =
      'https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate';

  /// Fetch today's fitness snapshot (steps, calories, active mins, heart rate)
  Future<FitnessSnapshot> fetchTodaySnapshot() async {
    if (_account == null) {
      debugPrint('[Fitness] Not signed in — returning empty snapshot');
      return FitnessSnapshot.empty();
    }

    final headers = await _getHeaders();
    if (headers == null) return FitnessSnapshot.empty();

    // Time range: start of today → now (nanoseconds)
    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final startNs = start.millisecondsSinceEpoch * 1000000;
    final endNs   = now.millisecondsSinceEpoch   * 1000000;

    final body = jsonEncode({
      'aggregateBy': [
        {'dataTypeName': 'com.google.step_count.delta'},
        {'dataTypeName': 'com.google.calories.expended'},
        {'dataTypeName': 'com.google.active_minutes'},
        {'dataTypeName': 'com.google.heart_rate.bpm'},
      ],
      'bucketByTime': {'durationMillis': 86400000}, // 1 day bucket
      'startTimeMillis': start.millisecondsSinceEpoch,
      'endTimeMillis': now.millisecondsSinceEpoch,
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseSnapshot(response.body, startNs, endNs);
      } else {
        debugPrint('[Fitness] API error ${response.statusCode}: ${response.body}');
        return FitnessSnapshot.empty();
      }
    } catch (e) {
      debugPrint('[Fitness] fetchTodaySnapshot error: $e');
      return FitnessSnapshot.empty();
    }
  }

  /// Fetch 7-day step counts for the weekly trend chart
  Future<List<int>> fetchWeeklySteps() async {
    if (_account == null) return List.filled(7, 0);

    final headers = await _getHeaders();
    if (headers == null) return List.filled(7, 0);

    final now   = DateTime.now();
    final start = now.subtract(const Duration(days: 7));

    final body = jsonEncode({
      'aggregateBy': [
        {'dataTypeName': 'com.google.step_count.delta'},
      ],
      'bucketByTime': {'durationMillis': 86400000}, // daily buckets
      'startTimeMillis': start.millisecondsSinceEpoch,
      'endTimeMillis': now.millisecondsSinceEpoch,
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return List.filled(7, 0);

      final Map<String, dynamic> json = jsonDecode(response.body) as Map<String, dynamic>;
      final buckets = json['bucket'] as List<dynamic>? ?? [];
      final steps   = <int>[];

      for (final bucket in buckets) {
        final datasets = bucket['dataset'] as List<dynamic>? ?? [];
        int daySteps = 0;
        for (final ds in datasets) {
          final points = ds['point'] as List<dynamic>? ?? [];
          for (final pt in points) {
            final values = pt['value'] as List<dynamic>? ?? [];
            for (final v in values) {
              daySteps += ((v['intVal'] as int?) ?? 0);
            }
          }
        }
        steps.add(daySteps);
      }

      // Pad / trim to exactly 7 entries
      while (steps.length < 7) { steps.insert(0, 0); }
      return steps.length > 7 ? steps.sublist(steps.length - 7) : steps;
    } catch (e) {
      debugPrint('[Fitness] fetchWeeklySteps error: $e');
      return List.filled(7, 0);
    }
  }

  // ── Parse response ───────────────────────────────────────────────────────
  FitnessSnapshot _parseSnapshot(String responseBody, int startNs, int endNs) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(responseBody) as Map<String, dynamic>;
      final buckets = json['bucket'] as List<dynamic>? ?? [];

      int    steps         = 0;
      double calories      = 0;
      int    activeMins    = 0;
      double heartRate     = 0;
      int    heartRateCount = 0;

      for (final bucket in buckets) {
        final datasets = bucket['dataset'] as List<dynamic>? ?? [];
        for (final ds in datasets) {
          final dataType = ds['dataSourceId'] as String? ?? '';
          final points   = ds['point'] as List<dynamic>? ?? [];

          for (final pt in points) {
            final values = pt['value'] as List<dynamic>? ?? [];

            if (dataType.contains('step_count')) {
              for (final v in values) {
                steps += ((v['intVal'] as int?) ?? 0);
              }
            } else if (dataType.contains('calories')) {
              for (final v in values) {
                calories += ((v['fpVal'] as num?)?.toDouble() ?? 0.0);
              }
            } else if (dataType.contains('active_minutes')) {
              for (final v in values) {
                activeMins += ((v['intVal'] as int?) ?? 0);
              }
            } else if (dataType.contains('heart_rate')) {
              for (final v in values) {
                final hr = (v['fpVal'] as num?)?.toDouble() ?? 0.0;
                if (hr > 0) {
                  heartRate += hr;
                  heartRateCount++;
                }
              }
            }
          }
        }
      }

      return FitnessSnapshot(
        steps:          steps,
        caloriesBurned: calories,
        activeMinutes:  activeMins,
        heartRateBpm:   heartRateCount > 0 ? heartRate / heartRateCount : 0,
        fetchedAt:      DateTime.now(),
      );
    } catch (e) {
      debugPrint('[Fitness] parse error: $e');
      return FitnessSnapshot.empty();
    }
  }
}
