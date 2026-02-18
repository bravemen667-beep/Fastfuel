import 'package:flutter/material.dart';
import 'dart:math';

class HealthProvider extends ChangeNotifier {
  // ── GoFaster Score ──────────────────────────────────
  double _score = 88;
  double get score => _score;
  double get scoreDelta => 12; // % change

  // ── Water ───────────────────────────────────────────
  double _waterConsumed = 1250; // ml
  double _waterGoal = 2500;     // ml
  bool _waterReminders = true;

  double get waterConsumed => _waterConsumed;
  double get waterGoal => _waterGoal;
  double get waterProgress => (_waterConsumed / _waterGoal).clamp(0, 1);
  bool get waterReminders => _waterReminders;
  String get waterRemaining => '${(_waterGoal - _waterConsumed).toInt()} ml';

  // ── Calories ────────────────────────────────────────
  double _caloriesConsumed = 1200;
  double _caloriesBurned = 750;
  double _caloriesGoal = 2200;

  double get caloriesConsumed => _caloriesConsumed;
  double get caloriesBurned => _caloriesBurned;
  double get caloriesGoal => _caloriesGoal;
  double get caloriesProgress => (_caloriesBurned / 900).clamp(0, 1);
  double get caloriesRemaining => _caloriesGoal - _caloriesConsumed;
  int get steps => 8432;
  int get activeMinutes => 45;

  // Macros (grams)
  double get proteinG => 120;
  double get carbsG => 105;
  double get fatsG => 35;

  // ── Sleep ───────────────────────────────────────────
  double _sleepScore = 82;
  double get sleepScore => _sleepScore;
  double get sleepProgress => _sleepScore / 100;
  String get bedtime => '11:15 PM';
  String get wakeTime => '06:57 AM';
  String get sleepDuration => '7h 42m';
  double get sleepEfficiency => 0.88;

  List<SleepStage> get sleepStages => [
    SleepStage('Awake', 0.20, 0.05, const Color(0xFFEF4444)),
    SleepStage('Core', 0.60, 0.15, const Color(0xFF60A5FA)),
    SleepStage('REM', 0.75, 0.10, const Color(0xFF850AFF)),
    SleepStage('Deep', 0.40, 0.20, const Color(0xFF1E3A8A)),
    SleepStage('REM', 0.75, 0.12, const Color(0xFF850AFF)),
    SleepStage('Core', 0.60, 0.18, const Color(0xFF60A5FA)),
    SleepStage('Deep', 0.35, 0.10, const Color(0xFF1E3A8A)),
    SleepStage('Awake', 0.15, 0.10, const Color(0xFFEF4444)),
  ];

  List<double> get sleepWeekly => [0.65, 0.78, 0.55, 0.82, 0.70, 0.72, 0.68];

  // ── Vitamins ────────────────────────────────────────
  final List<Vitamin> _vitamins = [
    Vitamin(name: 'Vitamin C', dose: '500mg', benefit: 'Immunity Support', taken: true, color: const Color(0xFFF97316), icon: Icons.shield_rounded),
    Vitamin(name: 'Vitamin B12', dose: '1000mcg', benefit: 'Energy & Focus', taken: true, color: const Color(0xFF3B82F6), icon: Icons.bolt_rounded),
    Vitamin(name: 'Vitamin D3', dose: '2000 IU', benefit: 'Bone Strength', taken: false, color: const Color(0xFFF59E0B), icon: Icons.wb_sunny_rounded),
    Vitamin(name: 'Omega-3', dose: '1000mg', benefit: 'Heart & Brain', taken: false, color: const Color(0xFF10B981), icon: Icons.favorite_rounded),
  ];

  List<Vitamin> get vitamins => _vitamins;
  int get vitaminsDone => _vitamins.where((v) => v.taken).length;
  int get tabletsLeft => 12;
  int get streakDays => 14;

  // ── Workouts ────────────────────────────────────────
  final List<WorkoutCategory> workoutCategories = [
    WorkoutCategory('HIIT', true),
    WorkoutCategory('Strength', false),
    WorkoutCategory('Cardio', false),
    WorkoutCategory('Recovery', false),
    WorkoutCategory('Yoga', false),
    WorkoutCategory('Mobility', false),
  ];

  final List<WorkoutCard> workoutCards = [
    WorkoutCard(
      title: 'Explosive HIIT',
      level: 'Advanced',
      tag: 'Top Pick',
      duration: 25,
      calories: 320,
      isLarge: true,
      gradientColors: [Color(0xFF1a0030), Color(0xFF330066)],
    ),
    WorkoutCard(
      title: 'Deep Recovery Flow',
      level: 'Beginner',
      tag: 'Recommended',
      duration: 15,
      calories: 90,
      isLarge: false,
      gradientColors: [Color(0xFF0a1a2a), Color(0xFF142840)],
    ),
    WorkoutCard(
      title: 'Power Strength',
      level: 'Intermediate',
      tag: 'Popular',
      duration: 35,
      calories: 480,
      isLarge: false,
      gradientColors: [Color(0xFF1a0a00), Color(0xFF2a1500)],
    ),
  ];

  // ── Actions ─────────────────────────────────────────
  void addWater(double ml) {
    _waterConsumed = min(_waterConsumed + ml, _waterGoal);
    _updateScore();
    notifyListeners();
  }

  void toggleWaterReminders(bool v) {
    _waterReminders = v;
    notifyListeners();
  }

  void toggleVitamin(int index) {
    final v = _vitamins[index];
    _vitamins[index] = Vitamin(
      name: v.name,
      dose: v.dose,
      benefit: v.benefit,
      taken: !v.taken,
      color: v.color,
      icon: v.icon,
    );
    _updateScore();
    notifyListeners();
  }

  void _updateScore() {
    final waterPct = waterProgress;
    final vitPct = vitaminsDone / _vitamins.length;
    final calPct = (caloriesBurned / 900).clamp(0, 1);
    _score = (waterPct * 25 + vitPct * 25 + calPct * 20 + sleepProgress * 30).clamp(0, 100);
    notifyListeners();
  }
}

// ── Data Models ──────────────────────────────────────
class SleepStage {
  final String name;
  final double heightFraction;
  final double widthFraction;
  final Color color;
  SleepStage(this.name, this.heightFraction, this.widthFraction, this.color);
}

class Vitamin {
  final String name;
  final String dose;
  final String benefit;
  final bool taken;
  final Color color;
  final IconData icon;
  Vitamin({
    required this.name,
    required this.dose,
    required this.benefit,
    required this.taken,
    required this.color,
    required this.icon,
  });
}

class WorkoutCategory {
  final String name;
  bool selected;
  WorkoutCategory(this.name, this.selected);
}

class WorkoutCard {
  final String title;
  final String level;
  final String tag;
  final int duration;
  final int calories;
  final bool isLarge;
  final List<Color> gradientColors;
  WorkoutCard({
    required this.title,
    required this.level,
    required this.tag,
    required this.duration,
    required this.calories,
    required this.isLarge,
    required this.gradientColors,
  });
}
