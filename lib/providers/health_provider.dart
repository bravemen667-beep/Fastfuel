// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — HealthProvider (Firestore-backed)
//
//  Single source of truth for all 5 screens.
//  Streams live data from Firestore; exposes write methods that
//  update Firestore immediately and the local state optimistically.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/health_sync_service.dart';
import '../services/google_fitness_service.dart';

class HealthProvider extends ChangeNotifier {
  String? _uid;
  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error  => _error;
  String get uid     => _uid ?? '';

  // ── Stream subscriptions ─────────────────────────────────────────────────
  StreamSubscription<Map<String, dynamic>>? _dashSub;
  StreamSubscription<DocumentSnapshot>?    _streakSub;
  StreamSubscription<DocumentSnapshot>?    _profileSub;

  // ── Google Fitness API state ──────────────────────────────────────────────
  bool   _fitnessConnected  = false;
  bool   _fitnessFetching   = false;
  String? _fitnessError;
  List<int> _weeklySteps    = [0, 0, 0, 0, 0, 0, 0];

  bool   get fitnessConnected => _fitnessConnected;
  bool   get fitnessFetching  => _fitnessFetching;
  String? get fitnessError    => _fitnessError;
  List<int> get weeklySteps   => _weeklySteps;

  // ── Health Connect (Android) / HealthKit (iOS) state ─────────────────────
  HealthPermissionStatus _healthPermStatus = HealthPermissionStatus.unknown;
  bool   _healthSyncing   = false;
  String? _healthSyncError;
  DateTime? _lastSyncTime;
  String _healthSource    = '';          // "Health Connect" | "Apple HealthKit"

  HealthPermissionStatus get healthPermStatus => _healthPermStatus;
  bool   get healthSyncing   => _healthSyncing;
  String? get healthSyncError => _healthSyncError;
  DateTime? get lastSyncTime  => _lastSyncTime;
  String get healthSource    => _healthSource;

  /// e.g. "Synced 2 min ago"  or "" if never synced
  String get syncLabel => _lastSyncTime != null
      ? HealthSyncSnapshot(
          steps: 0, caloriesBurned: 0, activeMinutes: 0, heartRateBpm: 0,
          sleepScore: 0, sleepDuration: '', bedtime: '', wakeTime: '',
          sleepEfficiency: 0, sleepWeekly: [], syncedAt: _lastSyncTime!,
          source: _healthSource,
        ).syncLabel
      : '';

  // ── Water ────────────────────────────────────────────────────────────────
  double _waterConsumed  = 1250;
  double _waterGoal      = 2500;
  bool   _waterReminders = true;

  double get waterConsumed  => _waterConsumed;
  double get waterGoal      => _waterGoal;
  double get waterProgress  => (_waterConsumed / _waterGoal).clamp(0, 1);
  bool   get waterReminders => _waterReminders;
  String get waterRemaining => '${(_waterGoal - _waterConsumed).toInt()} ml';

  // ── Calories ─────────────────────────────────────────────────────────────
  double _caloriesConsumed  = 1200;
  double _caloriesBurned    = 750;
  double _caloriesGoal      = 2200;
  int    _steps             = 8432;
  int    _activeMinutes     = 45;
  double _heartRateBpm      = 0;
  double _proteinG          = 120;
  double _carbsG            = 105;
  double _fatsG             = 35;

  double get caloriesConsumed  => _caloriesConsumed;
  double get caloriesBurned    => _caloriesBurned;
  double get caloriesGoal      => _caloriesGoal;
  double get caloriesProgress  => (_caloriesBurned / 900).clamp(0, 1);
  double get caloriesRemaining => _caloriesGoal - _caloriesConsumed;
  int    get steps             => _steps;
  int    get activeMinutes     => _activeMinutes;
  double get heartRateBpm      => _heartRateBpm;
  double get proteinG          => _proteinG;
  double get carbsG            => _carbsG;
  double get fatsG             => _fatsG;

  // ── Sleep ────────────────────────────────────────────────────────────────
  double       _sleepScore      = 82;
  String       _bedtime         = '11:15 PM';
  String       _wakeTime        = '06:57 AM';
  String       _sleepDuration   = '7h 42m';
  double       _sleepEfficiency = 0.88;
  List<double> _sleepWeekly    = [0.65, 0.78, 0.55, 0.82, 0.70, 0.72, 0.68];

  double       get sleepScore      => _sleepScore;
  double       get sleepProgress   => _sleepScore / 100;
  String       get bedtime         => _bedtime;
  String       get wakeTime        => _wakeTime;
  String       get sleepDuration   => _sleepDuration;
  double       get sleepEfficiency => _sleepEfficiency;
  List<double> get sleepWeekly     => _sleepWeekly;

  List<SleepStage> get sleepStages => [
    SleepStage('Awake', 0.20, 0.05, AppColors.sleepAwake),
    SleepStage('Core',  0.60, 0.15, AppColors.sleepCore),
    SleepStage('REM',   0.75, 0.10, AppColors.sleepRem),
    SleepStage('Deep',  0.40, 0.20, AppColors.sleepDeep),
    SleepStage('REM',   0.75, 0.12, AppColors.sleepRem),
    SleepStage('Core',  0.60, 0.18, AppColors.sleepCore),
    SleepStage('Deep',  0.35, 0.10, AppColors.sleepDeep),
    SleepStage('Awake', 0.15, 0.10, AppColors.sleepAwake),
  ];

  // ── Vitamins ─────────────────────────────────────────────────────────────
  List<Vitamin> _vitamins = [
    Vitamin(name: 'Vitamin C',   dose: '500mg',   benefit: 'Immunity Support', taken: true,  color: AppColors.primary, icon: Icons.shield_rounded),
    Vitamin(name: 'Vitamin B12', dose: '1000mcg', benefit: 'Energy & Focus',   taken: true,  color: AppColors.accent,  icon: Icons.bolt_rounded),
    Vitamin(name: 'Vitamin D3',  dose: '2000 IU', benefit: 'Bone Strength',    taken: false, color: AppColors.warning, icon: Icons.wb_sunny_rounded),
    Vitamin(name: 'Omega-3',     dose: '1000mg',  benefit: 'Heart & Brain',    taken: false, color: AppColors.success, icon: Icons.favorite_rounded),
  ];

  List<Vitamin> get vitamins     => _vitamins;
  int get vitaminsDone           => _vitamins.where((v) => v.taken).length;
  int get tabletsLeft            => 12;

  // ── Score & Streaks ──────────────────────────────────────────────────────
  double _score         = 88;
  double get score      => _score;
  double get scoreDelta => 12;

  int _waterStreak   = 5;
  int _vitaminStreak = 14;
  int get waterStreak   => _waterStreak;
  int get vitaminStreak => _vitaminStreak;
  int get streakDays    => _vitaminStreak;

  // ── Profile / Goals ──────────────────────────────────────────────────────
  String _profileName  = '';
  String get profileName => _profileName;

  // ── Fitness Preferences (from Firestore / FitnessPreferencesScreen) ──────
  String _fitnessGoal    = 'General Wellness';
  String _fitnessLevel   = 'Intermediate';
  String _workoutType    = 'HIIT';
  String get fitnessGoal  => _fitnessGoal;
  String get fitnessLevel => _fitnessLevel;
  String get workoutType  => _workoutType;

  // ── Workouts (static) ────────────────────────────────────────────────────
  final List<WorkoutCategory> workoutCategories = [
    WorkoutCategory('HIIT', true),
    WorkoutCategory('Strength', false),
    WorkoutCategory('Cardio', false),
    WorkoutCategory('Recovery', false),
    WorkoutCategory('Yoga', false),
    WorkoutCategory('Mobility', false),
  ];

  final List<WorkoutCard> workoutCards = [
    WorkoutCard(title: 'Explosive HIIT',     level: 'Advanced',     tag: 'Top Pick',     duration: 25, calories: 320, isLarge: true,  gradientColors: [Color(0xFF2A1000), Color(0xFF3D1800)]),
    WorkoutCard(title: 'Deep Recovery Flow', level: 'Beginner',     tag: 'Recommended',  duration: 15, calories: 90,  isLarge: false, gradientColors: [Color(0xFF1A1A1A), Color(0xFF252525)]),
    WorkoutCard(title: 'Power Strength',     level: 'Intermediate', tag: 'Popular',      duration: 35, calories: 480, isLarge: false, gradientColors: [Color(0xFF1E0A00), Color(0xFF2A1200)]),
  ];

  // ── Firestore init ───────────────────────────────────────────────────────
  /// Call when a user logs in. Starts all real-time listeners.
  Future<void> initForUser(String uid, String name) async {
    _uid  = uid;
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Ensure user docs exist in Firestore
    await FirestoreService.instance.initUserDocs(uid, name, '');

    // Start streams
    _startStreams(uid);
  }

  void _startStreams(String uid) {
    _dashSub?.cancel();
    _streakSub?.cancel();
    _profileSub?.cancel();

    // Dashboard stream — water + calories + sleep + vitamins
    _dashSub = FirestoreService.instance.dashboardStream(uid).listen(
      (data) {
        _applyWater(data['water']       as Map<String, dynamic>?);
        _applyCalories(data['calories'] as Map<String, dynamic>?);
        _applySleep(data['sleep']       as Map<String, dynamic>?);
        _applyVitamins(data['vitamins'] as Map<String, dynamic>?);
        _recomputeScore();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load health data. Check your connection.';
        _isLoading = false;
        notifyListeners();
      },
    );

    // Streaks stream
    _streakSub = FirestoreService.instance.streaksStream(uid).listen(
      (snap) {
        if (snap.exists) {
          final d = snap.data() as Map<String, dynamic>;
          _waterStreak   = (d['waterStreak']   as num?)?.toInt()   ?? _waterStreak;
          _vitaminStreak = (d['vitaminStreak'] as num?)?.toInt()   ?? _vitaminStreak;
          notifyListeners();
        }
      },
    );

    // Profile stream
    _profileSub = FirestoreService.instance.profileStream(uid).listen(
      (snap) {
        if (snap.exists) {
          final d = snap.data() as Map<String, dynamic>;
          _profileName = (d['name'] as String?) ?? _profileName;
          final goals = d['goals'] as Map<String, dynamic>?;
          if (goals != null) {
            _waterGoal      = (goals['waterGoal']    as num?)?.toDouble() ?? _waterGoal;
            _caloriesGoal   = (goals['caloriesGoal'] as num?)?.toDouble() ?? _caloriesGoal;
            // Fitness preferences saved by FitnessPreferencesScreen
            _fitnessGoal    = (goals['fitnessGoal']     as String?) ?? _fitnessGoal;
            _fitnessLevel   = (goals['fitnessLevel']    as String?) ?? _fitnessLevel;
            _workoutType    = (goals['preferredWorkout'] as String?) ?? _workoutType;
          }
          notifyListeners();
        }
      },
    );
  }

  // ── Firestore data parsers ───────────────────────────────────────────────
  void _applyWater(Map<String, dynamic>? d) {
    if (d == null) { return; }
    _waterConsumed  = (d['consumed']  as num?)?.toDouble() ?? _waterConsumed;
    _waterGoal      = (d['goal']      as num?)?.toDouble() ?? _waterGoal;
    _waterReminders = (d['reminders'] as bool?) ?? _waterReminders;
  }

  void _applyCalories(Map<String, dynamic>? d) {
    if (d == null) { return; }
    _caloriesConsumed = (d['consumed']      as num?)?.toDouble() ?? _caloriesConsumed;
    _caloriesBurned   = (d['burned']        as num?)?.toDouble() ?? _caloriesBurned;
    _caloriesGoal     = (d['goal']          as num?)?.toDouble() ?? _caloriesGoal;
    _steps            = (d['steps']         as num?)?.toInt()    ?? _steps;
    _activeMinutes    = (d['activeMinutes'] as num?)?.toInt()    ?? _activeMinutes;
    _proteinG         = (d['protein']       as num?)?.toDouble() ?? _proteinG;
    _carbsG           = (d['carbs']         as num?)?.toDouble() ?? _carbsG;
    _fatsG            = (d['fats']          as num?)?.toDouble() ?? _fatsG;
  }

  void _applySleep(Map<String, dynamic>? d) {
    if (d == null) { return; }
    _sleepScore      = (d['score']      as num?)?.toDouble() ?? _sleepScore;
    _bedtime         = (d['bedtime']    as String?) ?? _bedtime;
    _wakeTime        = (d['wakeTime']   as String?) ?? _wakeTime;
    _sleepDuration   = (d['duration']   as String?) ?? _sleepDuration;
    _sleepEfficiency = (d['efficiency'] as num?)?.toDouble() ?? _sleepEfficiency;
    final raw = d['weekly'];
    if (raw is List) {
      _sleepWeekly = raw.map((e) => (e as num).toDouble()).toList();
    }
  }

  void _applyVitamins(Map<String, dynamic>? d) {
    if (d == null) { return; }
    final raw = d['vitamins'];
    if (raw is! List) { return; }

    _vitamins = raw.map((e) {
      final m = e as Map<String, dynamic>;
      final colorHex = m['colorHex'] as String? ?? 'FF6B00';
      final color = Color(int.parse('FF$colorHex', radix: 16));
      return Vitamin(
        name:    (m['name']    as String?) ?? 'Vitamin',
        dose:    (m['dose']    as String?) ?? '',
        benefit: (m['benefit'] as String?) ?? '',
        taken:   (m['taken']   as bool?)   ?? false,
        color:   color,
        icon:    _iconForVitamin((m['name'] as String?) ?? ''),
      );
    }).toList();
  }

  IconData _iconForVitamin(String name) {
    if (name.contains('C'))    { return Icons.shield_rounded; }
    if (name.contains('B12'))  { return Icons.bolt_rounded; }
    if (name.contains('D3'))   { return Icons.wb_sunny_rounded; }
    if (name.contains('Omega'))  { return Icons.favorite_rounded; }
    return Icons.medication_rounded;
  }

  void _recomputeScore() {
    final waterPct = waterProgress;
    final vitPct   = vitaminsDone / max(_vitamins.length, 1);
    final calPct   = (caloriesBurned / 900).clamp(0.0, 1.0);
    _score = (waterPct * 25 + vitPct * 25 + calPct * 20 + sleepProgress * 30)
        .clamp(0.0, 100.0);
    if (_uid != null) {
      FirestoreService.instance.saveScore(_uid!, _score);
    }
  }

  // ── Public write actions ─────────────────────────────────────────────────

  void addWater(double ml) {
    // Optimistic update
    _waterConsumed = min(_waterConsumed + ml, _waterGoal);
    _recomputeScore();
    notifyListeners();
    // Persist
    if (_uid != null) {
      FirestoreService.instance.addWater(_uid!, ml);
    }
  }

  void toggleWaterReminders(bool v) {
    _waterReminders = v;
    notifyListeners();
    if (_uid != null) {
      FirestoreService.instance.setWaterReminders(_uid!, v);
      NotificationService.instance.setHydrationReminders(v);
    }
  }

  void toggleVitamin(int index) {
    final v       = _vitamins[index];
    final newTaken = !v.taken;
    // Optimistic update
    _vitamins[index] = Vitamin(
      name: v.name, dose: v.dose, benefit: v.benefit,
      taken: newTaken, color: v.color, icon: v.icon,
    );
    _recomputeScore();
    notifyListeners();
    // Persist
    if (_uid != null) {
      FirestoreService.instance.toggleVitamin(_uid!, index, newTaken);
    }
  }

  Future<void> updateSleepData({
    double? score, String? bedtime, String? wakeTime,
    String? duration, double? efficiency, List<double>? weekly,
  }) async {
    if (score      != null) { _sleepScore      = score; }
    if (bedtime    != null) { _bedtime         = bedtime; }
    if (wakeTime   != null) { _wakeTime        = wakeTime; }
    if (duration   != null) { _sleepDuration   = duration; }
    if (efficiency != null) { _sleepEfficiency = efficiency; }
    if (weekly     != null) { _sleepWeekly     = weekly; }
    _recomputeScore();
    notifyListeners();
    if (_uid != null) {
      await FirestoreService.instance.updateSleep(
        _uid!, score: score, bedtime: bedtime, wakeTime: wakeTime,
        duration: duration, efficiency: efficiency, weekly: weekly,
      );
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_uid == null) { return; }
    await FirestoreService.instance.updateProfile(_uid!, data);
  }

  Future<void> updateGoals(Map<String, dynamic> goals) async {
    if (_uid == null) { return; }
    if (goals['waterGoal']    != null) { _waterGoal    = (goals['waterGoal']    as num).toDouble(); }
    if (goals['caloriesGoal'] != null) { _caloriesGoal = (goals['caloriesGoal'] as num).toDouble(); }
    notifyListeners();
    await FirestoreService.instance.updateGoals(_uid!, goals);
  }

  // ── Health Connect / HealthKit public API ────────────────────────────────

  /// Check if permission already granted (call on screen open)
  Future<HealthPermissionStatus> checkHealthPermission() async {
    _healthPermStatus = await HealthSyncService.instance.checkPermission();
    notifyListeners();
    return _healthPermStatus;
  }

  /// Request permission then immediately sync data.
  /// Returns true if granted.
  Future<bool> requestAndSyncHealth() async {
    final granted = await HealthSyncService.instance.requestPermission();
    if (granted) {
      _healthPermStatus = HealthPermissionStatus.granted;
      await _syncHealthData();
      return true;
    } else {
      _healthPermStatus = HealthPermissionStatus.denied;
      notifyListeners();
      return false;
    }
  }

  /// Refresh health data (pull-to-refresh or periodic call)
  Future<void> refreshHealthData() async {
    if (_healthPermStatus != HealthPermissionStatus.granted) return;
    await _syncHealthData();
  }

  Future<void> _syncHealthData() async {
    _healthSyncing   = true;
    _healthSyncError = null;
    notifyListeners();

    try {
      final svc      = HealthSyncService.instance;
      final snapshot = await svc.fetchTodaySnapshot();
      final weekly   = await svc.fetchWeeklySleep();

      _healthSource = snapshot.source;
      _lastSyncTime = snapshot.syncedAt;

      // Apply real data — override Firestore defaults
      if (snapshot.steps > 0)          _steps         = snapshot.steps;
      if (snapshot.caloriesBurned > 0) _caloriesBurned = snapshot.caloriesBurned;
      if (snapshot.activeMinutes > 0)  _activeMinutes  = snapshot.activeMinutes;
      if (snapshot.heartRateBpm   > 0) _heartRateBpm   = snapshot.heartRateBpm;

      // Sleep data
      if (snapshot.sleepScore > 0) {
        _sleepScore      = snapshot.sleepScore;
        _sleepDuration   = snapshot.sleepDuration;
        _bedtime         = snapshot.bedtime;
        _wakeTime        = snapshot.wakeTime;
        _sleepEfficiency = snapshot.sleepEfficiency;
      }
      if (weekly.any((v) => v > 0)) {
        _sleepWeekly = weekly;
      }

      // Persist synced data back to Firestore
      if (_uid != null) {
        await FirestoreService.instance.updateCaloriesFromFitness(
          _uid!,
          steps:         _steps,
          burned:        _caloriesBurned,
          activeMinutes: _activeMinutes,
        );
        await FirestoreService.instance.updateSleep(
          _uid!,
          score:      snapshot.sleepScore > 0 ? snapshot.sleepScore : null,
          bedtime:    snapshot.bedtime != '--' ? snapshot.bedtime : null,
          wakeTime:   snapshot.wakeTime != '--' ? snapshot.wakeTime : null,
          duration:   snapshot.sleepDuration != '--' ? snapshot.sleepDuration : null,
          efficiency: snapshot.sleepEfficiency > 0 ? snapshot.sleepEfficiency : null,
          weekly:     weekly.any((v) => v > 0) ? weekly : null,
        );
      }

      _recomputeScore();
      _healthSyncing = false;
      notifyListeners();
    } catch (e) {
      _healthSyncError = 'Sync failed: $e';
      _healthSyncing   = false;
      notifyListeners();
    }
  }

  // ── Add meal calories (from Scan Food) ──────────────────────────────────
  Future<void> addMealCalories(double calories, String foodName) async {
    _caloriesConsumed = _caloriesConsumed + calories;
    _recomputeScore();
    notifyListeners();
    if (_uid != null) {
      try {
        await FirestoreService.instance.logMealCalories(
          _uid!, calories: calories, foodName: foodName,
        );
      } catch (_) {}
    }
  }

  // ── Manual override (fallback when permission denied) ─────────────────────
  void setManualSleepData({
    required double score,
    required String bedtime,
    required String wakeTime,
    required String duration,
    required double efficiency,
  }) {
    _sleepScore      = score;
    _bedtime         = bedtime;
    _wakeTime        = wakeTime;
    _sleepDuration   = duration;
    _sleepEfficiency = efficiency;
    _lastSyncTime    = DateTime.now();
    _healthSource    = 'Manual';
    _recomputeScore();
    notifyListeners();
    if (_uid != null) {
      FirestoreService.instance.updateSleep(
        _uid!,
        score: score, bedtime: bedtime, wakeTime: wakeTime,
        duration: duration, efficiency: efficiency,
      );
    }
  }

  void setManualCalorieData({
    required double caloriesBurned,
    required int    steps,
    required int    activeMinutes,
  }) {
    _caloriesBurned = caloriesBurned;
    _steps          = steps;
    _activeMinutes  = activeMinutes;
    _lastSyncTime   = DateTime.now();
    _healthSource   = 'Manual';
    _recomputeScore();
    notifyListeners();
    if (_uid != null) {
      FirestoreService.instance.updateCaloriesFromFitness(
        _uid!, steps: steps, burned: caloriesBurned, activeMinutes: activeMinutes,
      );
    }
  }

  // ── Cleanup ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _dashSub?.cancel();
    _streakSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  // ── Google Fitness API ───────────────────────────────────────────────────

  /// Connect Google Fitness: sign in + fetch today's real data
  Future<void> connectGoogleFitness() async {
    if (kIsWeb) {
      _fitnessError = 'Google Fit is not available on Web preview. '
          'Connect on Android or iOS device.';
      notifyListeners();
      return;
    }

    _fitnessFetching = true;
    _fitnessError    = null;
    notifyListeners();

    try {
      final svc     = GoogleFitnessService.instance;
      final success = await svc.signIn();

      if (!success) {
        _fitnessError    = 'Google Sign-In cancelled or failed.';
        _fitnessFetching = false;
        notifyListeners();
        return;
      }

      _fitnessConnected = true;
      await _fetchFitnessData();
    } catch (e) {
      _fitnessError    = 'Failed to connect Google Fit: $e';
      _fitnessFetching = false;
      notifyListeners();
    }
  }

  /// Disconnect Google Fitness
  Future<void> disconnectGoogleFitness() async {
    await GoogleFitnessService.instance.signOut();
    _fitnessConnected = false;
    notifyListeners();
  }

  /// Refresh fitness data (call on pull-to-refresh)
  Future<void> refreshFitnessData() async {
    if (!_fitnessConnected) return;
    await _fetchFitnessData();
  }

  Future<void> _fetchFitnessData() async {
    _fitnessFetching = true;
    notifyListeners();

    try {
      final svc      = GoogleFitnessService.instance;
      final snapshot = await svc.fetchTodaySnapshot();
      final weekly   = await svc.fetchWeeklySteps();

      // Override Firestore values with real Google Fit data
      if (snapshot.steps > 0) {
        _steps         = snapshot.steps;
      }
      if (snapshot.caloriesBurned > 0) {
        _caloriesBurned = snapshot.caloriesBurned;
      }
      if (snapshot.activeMinutes > 0) {
        _activeMinutes = snapshot.activeMinutes;
      }
      _weeklySteps = weekly;

      // Persist back to Firestore so other devices also see the synced data
      if (_uid != null) {
        FirestoreService.instance.updateCaloriesFromFitness(
          _uid!,
          steps:         _steps,
          burned:        _caloriesBurned,
          activeMinutes: _activeMinutes,
        );
      }

      _recomputeScore();
      _fitnessFetching = false;
      _fitnessError    = null;
      notifyListeners();
    } catch (e) {
      _fitnessError    = 'Error fetching fitness data: $e';
      _fitnessFetching = false;
      notifyListeners();
    }
  }
}

// ── Models ────────────────────────────────────────────────────────────────────
class SleepStage {
  final String name;
  final double heightFraction;
  final double widthFraction;
  final Color color;
  SleepStage(this.name, this.heightFraction, this.widthFraction, this.color);
}

class Vitamin {
  final String   name;
  final String   dose;
  final String   benefit;
  final bool     taken;
  final Color    color;
  final IconData icon;
  const Vitamin({
    required this.name, required this.dose, required this.benefit,
    required this.taken, required this.color, required this.icon,
  });
}

class WorkoutCategory {
  final String name;
  bool selected;
  WorkoutCategory(this.name, this.selected);
}

class WorkoutCard {
  final String      title;
  final String      level;
  final String      tag;
  final int         duration;
  final int         calories;
  final bool        isLarge;
  final List<Color> gradientColors;
  const WorkoutCard({
    required this.title, required this.level, required this.tag,
    required this.duration, required this.calories,
    required this.isLarge, required this.gradientColors,
  });
}
