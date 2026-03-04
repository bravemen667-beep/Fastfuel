// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — HealthSyncService
//
//  Unified abstraction over:
//    • Google Health Connect  (Android 9+ via `health` plugin)
//    • Apple HealthKit        (iOS via `health` plugin)
//    • Web / unsupported      (graceful no-op with manual fallback)
//
//  Data types read:
//    STEPS               — com.google.step_count.delta / HKQuantityTypeIdentifierStepCount
//    ACTIVE_ENERGY       — health.READ_ACTIVE_CALORIES_BURNED / ActiveEnergyBurned
//    SLEEP_ASLEEP        — health.READ_SLEEP / SleepAnalysis
//    HEART_RATE          — health.READ_HEART_RATE / HeartRate
//    TOTAL_CALORIES      — health.READ_TOTAL_CALORIES_BURNED / BasalEnergyBurned
//
//  Permission lifecycle:
//    1. checkPermission()  → HealthPermissionStatus
//    2. requestPermission() → bool (granted / denied)
//    3. fetchTodayData()   → HealthSyncSnapshot
//    4. fetchWeeklySleep() → List<double> (7 normalised quality scores 0-1)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

// ── Enums & Data classes ──────────────────────────────────────────────────────

enum HealthPermissionStatus { unknown, granted, denied, notAvailable }

/// Snapshot of today's real health data
class HealthSyncSnapshot {
  final int     steps;
  final double  caloriesBurned;    // active calories kcal
  final int     activeMinutes;
  final double  heartRateBpm;      // avg, 0 if unavailable
  final double  sleepScore;        // 0-100
  final String  sleepDuration;     // "7h 42m"
  final String  bedtime;           // "11:15 PM"
  final String  wakeTime;          // "06:57 AM"
  final double  sleepEfficiency;   // 0.0-1.0
  final List<double> sleepWeekly;  // 7 normalised scores
  final DateTime syncedAt;
  final String  source;            // "Health Connect" | "HealthKit" | "Manual"

  const HealthSyncSnapshot({
    required this.steps,
    required this.caloriesBurned,
    required this.activeMinutes,
    required this.heartRateBpm,
    required this.sleepScore,
    required this.sleepDuration,
    required this.bedtime,
    required this.wakeTime,
    required this.sleepEfficiency,
    required this.sleepWeekly,
    required this.syncedAt,
    required this.source,
  });

  factory HealthSyncSnapshot.empty() => HealthSyncSnapshot(
    steps: 0, caloriesBurned: 0, activeMinutes: 0, heartRateBpm: 0,
    sleepScore: 0, sleepDuration: '--', bedtime: '--', wakeTime: '--',
    sleepEfficiency: 0, sleepWeekly: List.filled(7, 0),
    syncedAt: DateTime.now(), source: 'Manual',
  );

  /// Human-readable "Synced X ago" label
  String get syncLabel {
    final diff = DateTime.now().difference(syncedAt);
    if (diff.inSeconds < 60)  return 'Synced just now';
    if (diff.inMinutes < 60)  return 'Synced ${diff.inMinutes} min ago';
    if (diff.inHours   < 24)  return 'Synced ${diff.inHours}h ago';
    return 'Synced ${diff.inDays}d ago';
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class HealthSyncService {
  HealthSyncService._();
  static final HealthSyncService instance = HealthSyncService._();

  final Health _health = Health();

  // Data types we request
  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.HEART_RATE,
    HealthDataType.TOTAL_CALORIES_BURNED,
  ];

  // ── Platform check ─────────────────────────────────────────────────────────

  bool get _isSupported {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get platformName {
    if (!_isSupported) return 'Unsupported';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'Apple HealthKit'
        : 'Health Connect';
  }

  // ── Permission handling ────────────────────────────────────────────────────

  Future<HealthPermissionStatus> checkPermission() async {
    if (!_isSupported) return HealthPermissionStatus.notAvailable;
    try {
      final hasPerms = await _health.hasPermissions(_types) ?? false;
      return hasPerms
          ? HealthPermissionStatus.granted
          : HealthPermissionStatus.unknown;
    } catch (e) {
      debugPrint('[HealthSync] checkPermission error: $e');
      return HealthPermissionStatus.unknown;
    }
  }

  /// Requests permissions. Returns true if all (or partial) granted.
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    try {
      // Configure for Android Health Connect
      await _health.configure();
      final granted = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      debugPrint('[HealthSync] Permission granted: $granted');
      return granted;
    } catch (e) {
      debugPrint('[HealthSync] requestPermission error: $e');
      return false;
    }
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────

  /// Fetches today's full snapshot from Health Connect / HealthKit
  Future<HealthSyncSnapshot> fetchTodaySnapshot() async {
    if (!_isSupported) return HealthSyncSnapshot.empty();

    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime:   now,
        types:     _types,
      );

      final deduped = _health.removeDuplicates(points);
      return _buildSnapshot(deduped, start, now);
    } catch (e) {
      debugPrint('[HealthSync] fetchTodaySnapshot error: $e');
      return HealthSyncSnapshot.empty();
    }
  }

  /// Fetches 7 days of sleep data for the weekly trend chart
  Future<List<double>> fetchWeeklySleep() async {
    if (!_isSupported) return List.filled(7, 0);

    final now   = DateTime.now();
    final start = now.subtract(const Duration(days: 7));

    try {
      final sleepTypes = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
      ];

      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime:   now,
        types:     sleepTypes,
      );

      return _buildWeeklySleepScores(points, start, now);
    } catch (e) {
      debugPrint('[HealthSync] fetchWeeklySleep error: $e');
      return List.filled(7, 0);
    }
  }

  // ── Parsing helpers ────────────────────────────────────────────────────────

  HealthSyncSnapshot _buildSnapshot(
    List<HealthDataPoint> points,
    DateTime start,
    DateTime end,
  ) {
    int    steps          = 0;
    double activeCalories = 0;
    double totalCalories  = 0;
    double heartRateSum   = 0;
    int    heartRateCount = 0;

    // Sleep buckets
    Duration sleepAsleep   = Duration.zero;
    Duration sleepInBed    = Duration.zero;
    Duration sleepDeep     = Duration.zero;
    Duration sleepRem      = Duration.zero;
    Duration sleepAwake    = Duration.zero;
    DateTime? sleepStart;
    DateTime? sleepEnd;

    for (final pt in points) {
      final val = pt.value;
      switch (pt.type) {
        case HealthDataType.STEPS:
          if (val is NumericHealthValue) {
            steps += val.numericValue.toInt();
          }
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          if (val is NumericHealthValue) {
            activeCalories += val.numericValue.toDouble();
          }
        case HealthDataType.TOTAL_CALORIES_BURNED:
          if (val is NumericHealthValue) {
            totalCalories += val.numericValue.toDouble();
          }
        case HealthDataType.HEART_RATE:
          if (val is NumericHealthValue) {
            heartRateSum   += val.numericValue.toDouble();
            heartRateCount++;
          }
        case HealthDataType.SLEEP_ASLEEP:
          final dur = pt.dateTo.difference(pt.dateFrom);
          sleepAsleep += dur;
          if (sleepStart == null || pt.dateFrom.isBefore(sleepStart)) {
            sleepStart = pt.dateFrom;
          }
          if (sleepEnd == null || pt.dateTo.isAfter(sleepEnd)) {
            sleepEnd = pt.dateTo;
          }
        case HealthDataType.SLEEP_IN_BED:
          sleepInBed += pt.dateTo.difference(pt.dateFrom);
        case HealthDataType.SLEEP_DEEP:
          sleepDeep += pt.dateTo.difference(pt.dateFrom);
        case HealthDataType.SLEEP_REM:
          sleepRem  += pt.dateTo.difference(pt.dateFrom);
        case HealthDataType.SLEEP_AWAKE:
          sleepAwake += pt.dateTo.difference(pt.dateFrom);
        default:
          break;
      }
    }

    // Compute active minutes from active calories (1 active minute ≈ 5-8 kcal)
    final activeMinutes = activeCalories > 0
        ? (activeCalories / 6.5).round()
        : 0;

    // Sleep score (0-100)
    final totalSleepHours = sleepAsleep.inMinutes / 60.0;
    final sleepScore      = _computeSleepScore(
      totalHours:    totalSleepHours,
      deepMinutes:   sleepDeep.inMinutes,
      remMinutes:    sleepRem.inMinutes,
      awakeMinutes:  sleepAwake.inMinutes,
      inBedMinutes:  sleepInBed.inMinutes,
    );

    // Sleep efficiency
    final efficiency = (sleepInBed.inMinutes > 0)
        ? (sleepAsleep.inMinutes / sleepInBed.inMinutes).clamp(0.0, 1.0)
        : 0.88;

    // Format duration
    final h = sleepAsleep.inHours;
    final m = sleepAsleep.inMinutes % 60;
    final durationStr = (sleepAsleep.inMinutes > 0)
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : '--';

    // Format bedtime / wake time
    final bedtimeStr  = sleepStart != null ? _formatTime(sleepStart) : '--';
    final wakeTimeStr = sleepEnd   != null ? _formatTime(sleepEnd)   : '--';

    final effectiveCalories = activeCalories > 0
        ? activeCalories
        : (totalCalories * 0.3); // estimate 30% active from total

    return HealthSyncSnapshot(
      steps:           steps,
      caloriesBurned:  effectiveCalories,
      activeMinutes:   activeMinutes,
      heartRateBpm:    heartRateCount > 0
          ? heartRateSum / heartRateCount
          : 0,
      sleepScore:      sleepScore,
      sleepDuration:   durationStr,
      bedtime:         bedtimeStr,
      wakeTime:        wakeTimeStr,
      sleepEfficiency: efficiency,
      sleepWeekly:     List.filled(7, 0), // filled by fetchWeeklySleep()
      syncedAt:        DateTime.now(),
      source:          platformName,
    );
  }

  List<double> _buildWeeklySleepScores(
    List<HealthDataPoint> points,
    DateTime start,
    DateTime now,
  ) {
    // Group sleep duration by calendar day (index 0 = oldest)
    final scores = <double>[];
    for (int d = 6; d >= 0; d--) {
      final dayStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: d));
      final dayEnd = dayStart.add(const Duration(days: 1));

      double totalMins = 0;
      for (final pt in points) {
        if (pt.dateFrom.isAfter(dayStart) && pt.dateTo.isBefore(dayEnd)) {
          totalMins += pt.dateTo.difference(pt.dateFrom).inMinutes;
        }
      }
      // Normalise: 8 hours = 1.0
      scores.add(math.min(totalMins / 480, 1.0));
    }
    return scores;
  }

  double _computeSleepScore({
    required double totalHours,
    required int    deepMinutes,
    required int    remMinutes,
    required int    awakeMinutes,
    required int    inBedMinutes,
  }) {
    if (totalHours <= 0) return 0;

    // Duration score: 7-9 hours = 100, linear below/above
    final durationScore = totalHours >= 9.0 ? 100.0
        : totalHours >= 7.0 ? 100.0
        : totalHours >= 6.0 ? 80.0
        : totalHours >= 5.0 ? 60.0
        : 40.0;

    // Deep sleep score: 90 mins ideal
    final deepScore = deepMinutes > 0
        ? math.min(deepMinutes / 90.0, 1.0) * 100
        : 70.0; // assume decent if not tracked

    // REM score: 90 mins ideal
    final remScore = remMinutes > 0
        ? math.min(remMinutes / 90.0, 1.0) * 100
        : 70.0;

    // Awake penalty
    final awakePenalty = awakeMinutes > 30 ? 10.0 : 0.0;

    return ((durationScore * 0.5 + deepScore * 0.25 + remScore * 0.25) - awakePenalty)
        .clamp(0.0, 100.0);
  }

  String _formatTime(DateTime dt) {
    final hour   = dt.hour;
    final minute = dt.minute;
    final isPM   = hour >= 12;
    final h12    = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final amPm   = isPM ? 'PM' : 'AM';
    return '$h12:${minute.toString().padLeft(2, '0')} $amPm';
  }
}
