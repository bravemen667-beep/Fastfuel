// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — FirestoreService
//  Central service for all Firestore reads and writes.
//
//  Firestore schema
//  ├── users/{uid}/
//  │   ├── profile          (doc)   — name, phone, authMethod, goals
//  │   ├── daily/{date}/
//  │   │   ├── water        (doc)   — consumed, goal, logs[], reminders
//  │   │   ├── calories     (doc)   — consumed, burned, goal, macros
//  │   │   ├── sleep        (doc)   — score, bedtime, wakeTime, duration, weekly[]
//  │   │   └── vitamins     (doc)   — list of {name,dose,benefit,taken,colorHex}
//  │   └── streaks          (doc)   — waterStreak, vitaminStreak, lastUpdated
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final _db = FirebaseFirestore.instance;

  // ── Helpers ──────────────────────────────────────────────────────────────
  String get _today {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  DocumentReference _daily(String uid, String doc) =>
      _db.collection('users').doc(uid)
         .collection('daily').doc(_today)
         .collection('metrics').doc(doc);

  DocumentReference _profile(String uid) =>
      _db.collection('users').doc(uid).collection('meta').doc('profile');

  DocumentReference _streaks(String uid) =>
      _db.collection('users').doc(uid).collection('meta').doc('streaks');

  // ── Init user docs (called after login) ─────────────────────────────────
  Future<void> initUserDocs(String uid, String name, String phone) async {
    try {
      final profileRef = _profile(uid);
      final snap = await profileRef.get();
      if (!snap.exists) {
        await profileRef.set({
          'name': name,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'goals': {
            'waterGoal': 2500,
            'caloriesGoal': 2200,
            'sleepGoal': 8.0,
            'vitaminStreak': 30,
          },
        });
      }
      // Ensure today's docs exist
      await _ensureDailyDocs(uid);
    } catch (e) {
      debugPrint('[Firestore] initUserDocs error: $e');
    }
  }

  Future<void> _ensureDailyDocs(String uid) async {
    final waterRef    = _daily(uid, 'water');
    final caloriesRef = _daily(uid, 'calories');
    final sleepRef    = _daily(uid, 'sleep');
    final vitaminsRef = _daily(uid, 'vitamins');

    final futures = await Future.wait([
      waterRef.get(), caloriesRef.get(), sleepRef.get(), vitaminsRef.get(),
    ]);

    if (!futures[0].exists) {
      await waterRef.set({
        'consumed': 1250.0,
        'goal': 2500.0,
        'reminders': true,
        'logs': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (!futures[1].exists) {
      await caloriesRef.set({
        'consumed': 1200.0,
        'burned': 750.0,
        'goal': 2200.0,
        'steps': 8432,
        'activeMinutes': 45,
        'protein': 120.0,
        'carbs': 105.0,
        'fats': 35.0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (!futures[2].exists) {
      await sleepRef.set({
        'score': 82.0,
        'bedtime': '11:15 PM',
        'wakeTime': '06:57 AM',
        'duration': '7h 42m',
        'efficiency': 0.88,
        'weekly': [0.65, 0.78, 0.55, 0.82, 0.70, 0.72, 0.68],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    if (!futures[3].exists) {
      await vitaminsRef.set({
        'vitamins': [
          {'name': 'Vitamin C',   'dose': '500mg',    'benefit': 'Immunity Support', 'taken': true,  'colorHex': 'FF6B00'},
          {'name': 'Vitamin B12', 'dose': '1000mcg',  'benefit': 'Energy & Focus',   'taken': true,  'colorHex': 'FFB347'},
          {'name': 'Vitamin D3',  'dose': '2000 IU',  'benefit': 'Bone Strength',    'taken': false, 'colorHex': 'FFC107'},
          {'name': 'Omega-3',     'dose': '1000mg',   'benefit': 'Heart & Brain',    'taken': false, 'colorHex': '4CAF50'},
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Streaks
    final streakSnap = await _streaks(uid).get();
    if (!streakSnap.exists) {
      await _streaks(uid).set({
        'waterStreak': 5,
        'vitaminStreak': 14,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  // ── Streams (real-time) ──────────────────────────────────────────────────

  /// Home dashboard: listens to water + calories + sleep + vitamins at once
  Stream<Map<String, dynamic>> dashboardStream(String uid) {
    return _db.collection('users').doc(uid)
        .collection('daily').doc(_today)
        .collection('metrics')
        .snapshots()
        .map((qs) {
          final map = <String, dynamic>{};
          for (final doc in qs.docs) {
            map[doc.id] = doc.data();
          }
          return map;
        });
  }

  /// Hydration screen — live water doc
  Stream<DocumentSnapshot<Map<String, dynamic>>> waterStream(String uid) =>
      (_daily(uid, 'water') as DocumentReference<Map<String, dynamic>>).snapshots();

  /// Vitamins screen — live vitamins doc
  Stream<DocumentSnapshot<Map<String, dynamic>>> vitaminsStream(String uid) =>
      (_daily(uid, 'vitamins') as DocumentReference<Map<String, dynamic>>).snapshots();

  /// Sleep screen — live sleep doc
  Stream<DocumentSnapshot<Map<String, dynamic>>> sleepStream(String uid) =>
      (_daily(uid, 'sleep') as DocumentReference<Map<String, dynamic>>).snapshots();

  /// Profile — live profile + streaks
  Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(String uid) =>
      (_profile(uid) as DocumentReference<Map<String, dynamic>>).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> streaksStream(String uid) =>
      (_streaks(uid) as DocumentReference<Map<String, dynamic>>).snapshots();

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Add water — increments consumed, appends log entry
  Future<void> addWater(String uid, double ml) async {
    try {
      final ref = _daily(uid, 'water');
      await ref.update({
        'consumed': FieldValue.increment(ml),
        'logs': FieldValue.arrayUnion([{
          'ml': ml,
          'time': DateTime.now().toIso8601String(),
        }]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _updateWaterStreak(uid);
    } catch (e) {
      debugPrint('[Firestore] addWater error: $e');
    }
  }

  Future<void> setWaterReminders(String uid, bool enabled) async {
    try {
      await _daily(uid, 'water').update({'reminders': enabled});
    } catch (e) {
      debugPrint('[Firestore] setWaterReminders error: $e');
    }
  }

  /// Toggle vitamin taken state
  Future<void> toggleVitamin(String uid, int index, bool newState) async {
    try {
      final ref = _daily(uid, 'vitamins');
      final snap = await ref.get();
      if (!snap.exists) { return; }
      final data = snap.data() as Map<String, dynamic>;
      final list = List<Map<String, dynamic>>.from(
        (data['vitamins'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      if (index < list.length) {
        list[index]['taken'] = newState;
        await ref.update({
          'vitamins': list,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (newState) { await _updateVitaminStreak(uid); }
      }
    } catch (e) {
      debugPrint('[Firestore] toggleVitamin error: $e');
    }
  }

  /// Update sleep data
  Future<void> updateSleep(String uid, {
    double? score,
    String? bedtime,
    String? wakeTime,
    String? duration,
    double? efficiency,
    List<double>? weekly,
  }) async {
    try {
      final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (score      != null) { updates['score']      = score; }
      if (bedtime    != null) { updates['bedtime']     = bedtime; }
      if (wakeTime   != null) { updates['wakeTime']    = wakeTime; }
      if (duration   != null) { updates['duration']    = duration; }
      if (efficiency != null) { updates['efficiency']  = efficiency; }
      if (weekly     != null) { updates['weekly']      = weekly; }
      await _daily(uid, 'sleep').update(updates);
    } catch (e) {
      debugPrint('[Firestore] updateSleep error: $e');
    }
  }

  /// Update profile / goals
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _profile(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] updateProfile error: $e');
    }
  }

  Future<void> updateGoals(String uid, Map<String, dynamic> goals) async {
    try {
      await _profile(uid).update({
        'goals': goals,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] updateGoals error: $e');
    }
  }

  // ── Streak helpers ───────────────────────────────────────────────────────
  Future<void> _updateWaterStreak(String uid) async {
    try {
      await _streaks(uid).update({
        'waterStreak': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] _updateWaterStreak: $e');
    }
  }

  Future<void> _updateVitaminStreak(String uid) async {
    try {
      await _streaks(uid).update({
        'vitaminStreak': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] _updateVitaminStreak: $e');
    }
  }

  // ── GoFaster Score ───────────────────────────────────────────────────────
  Future<void> saveScore(String uid, double score) async {
    try {
      await _db.collection('users').doc(uid).collection('meta').doc('score').set({
        'score': score,
        'date': _today,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] saveScore error: $e');
    }
  }

  // ── Google Fitness sync ───────────────────────────────────────────────────
  /// Writes real step/calorie/active-minute data from Google Fit back to Firestore
  Future<void> updateCaloriesFromFitness(
    String uid, {
    required int    steps,
    required double burned,
    required int    activeMinutes,
  }) async {
    try {
      await _daily(uid, 'calories').update({
        'burned':        burned,
        'steps':         steps,
        'activeMinutes': activeMinutes,
        'fitnessSync':   true,
        'updatedAt':     FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] updateCaloriesFromFitness error: $e');
    }
  }

  // ── Log meal calories from Scan Food ─────────────────────────────────────
  Future<void> logMealCalories(String uid, {
    required double calories,
    required String foodName,
  }) async {
    try {
      final ref = _daily(uid, 'calories');
      await ref.set({
        'consumed':  FieldValue.increment(calories),
        'mealLog': FieldValue.arrayUnion([{
          'food':      foodName,
          'calories':  calories,
          'loggedAt':  DateTime.now().toIso8601String(),
        }]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] logMealCalories error: $e');
    }
  }

  // ── Log detailed meal with macros ─────────────────────────────────────────
  Future<void> logMeal(String uid, String dateKey, Map<String, dynamic> meal) async {
    try {
      final ref = _db
          .collection('users').doc(uid)
          .collection('calories').doc(dateKey);
      await ref.set({
        'consumed': FieldValue.increment((meal['calories'] as num?)?.toDouble() ?? 0),
        'meals':    FieldValue.arrayUnion([meal]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] logMeal error: $e');
    }
  }

  // ── FCM token ────────────────────────────────────────────────────────────
  Future<void> saveFcmToken(String uid, String token) async {
    try {
      await _profile(uid).update({
        'fcmToken': token,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Profile may not exist yet — use set with merge
      try {
        await _profile(uid).set({
          'fcmToken': token,
          'fcmUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e2) {
        debugPrint('[Firestore] saveFcmToken error: $e2');
      }
    }
  }
}
