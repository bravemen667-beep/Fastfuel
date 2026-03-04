// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Exercise Service
//  Fetches exercises from ExerciseDB (RapidAPI) based on muscle/category.
//  Falls back to curated exercises if API is unavailable.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ExerciseItem {
  final String id;
  final String name;
  final String bodyPart;
  final String target;
  final String equipment;
  final String gifUrl;
  final String difficulty;

  const ExerciseItem({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.target,
    required this.equipment,
    required this.gifUrl,
    required this.difficulty,
  });

  factory ExerciseItem.fromJson(Map<String, dynamic> j) {
    return ExerciseItem(
      id:         (j['id']        as String?) ?? '',
      name:       _titleCase((j['name']      as String?) ?? 'Exercise'),
      bodyPart:   _titleCase((j['bodyPart']  as String?) ?? ''),
      target:     _titleCase((j['target']    as String?) ?? ''),
      equipment:  _titleCase((j['equipment'] as String?) ?? ''),
      gifUrl:     (j['gifUrl']    as String?) ?? '',
      difficulty: 'Intermediate',
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s.split(' ').map((w) => w.isEmpty ? w :
        '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
}

class ExerciseService {
  ExerciseService._();
  static final ExerciseService instance = ExerciseService._();

  // RapidAPI key placeholder — replace with real key in production
  static const _rapidApiKey = 'YOUR_RAPIDAPI_KEY';
  static const _baseUrl     = 'https://exercisedb.p.rapidapi.com';

  Future<List<ExerciseItem>> fetchByBodyPart(String bodyPart, {int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/exercises/bodyPart/${Uri.encodeComponent(bodyPart)}?limit=$limit');
      final res = await http.get(uri, headers: {
        'X-RapidAPI-Key':  _rapidApiKey,
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((j) => ExerciseItem.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[ExerciseDB] fetchByBodyPart error: $e');
    }
    // Return curated fallback
    return _fallbackForBodyPart(bodyPart);
  }

  Future<List<ExerciseItem>> fetchByTarget(String target, {int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/exercises/target/${Uri.encodeComponent(target)}?limit=$limit');
      final res = await http.get(uri, headers: {
        'X-RapidAPI-Key':  _rapidApiKey,
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((j) => ExerciseItem.fromJson(j as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[ExerciseDB] fetchByTarget error: $e');
    }
    return _fallbackForBodyPart('chest');
  }

  List<ExerciseItem> _fallbackForBodyPart(String bp) {
    final lower = bp.toLowerCase();
    if (lower.contains('chest') || lower.contains('hiit')) {
      return _hiitExercises;
    } else if (lower.contains('back') || lower.contains('strength')) {
      return _strengthExercises;
    } else if (lower.contains('cardio') || lower.contains('run')) {
      return _cardioExercises;
    } else if (lower.contains('yoga') || lower.contains('recov')) {
      return _recoveryExercises;
    }
    return _hiitExercises;
  }

  static final _hiitExercises = [
    const ExerciseItem(id: 'h1', name: 'Burpee',                bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Body Weight', gifUrl: '', difficulty: 'Advanced'),
    const ExerciseItem(id: 'h2', name: 'Jump Squat',            bodyPart: 'Legs',      target: 'Quads',        equipment: 'Body Weight', gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'h3', name: 'Mountain Climber',      bodyPart: 'Core',      target: 'Abs',          equipment: 'Body Weight', gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'h4', name: 'High Knees',            bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'h5', name: 'Box Jump',              bodyPart: 'Legs',      target: 'Glutes',       equipment: 'Box',         gifUrl: '', difficulty: 'Advanced'),
    const ExerciseItem(id: 'h6', name: 'Plank Jack',            bodyPart: 'Core',      target: 'Abs',          equipment: 'Body Weight', gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'h7', name: 'Sprint Interval',       bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Treadmill',   gifUrl: '', difficulty: 'Advanced'),
    const ExerciseItem(id: 'h8', name: 'Kettlebell Swing',      bodyPart: 'Full Body', target: 'Glutes',       equipment: 'Kettlebell',  gifUrl: '', difficulty: 'Intermediate'),
  ];

  static final _strengthExercises = [
    const ExerciseItem(id: 's1', name: 'Bench Press',           bodyPart: 'Chest',     target: 'Pectorals',    equipment: 'Barbell',    gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 's2', name: 'Deadlift',              bodyPart: 'Back',      target: 'Spine',        equipment: 'Barbell',    gifUrl: '', difficulty: 'Advanced'),
    const ExerciseItem(id: 's3', name: 'Squat',                 bodyPart: 'Legs',      target: 'Quads',        equipment: 'Barbell',    gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 's4', name: 'Pull Up',               bodyPart: 'Back',      target: 'Lats',         equipment: 'Body Weight', gifUrl: '', difficulty: 'Advanced'),
    const ExerciseItem(id: 's5', name: 'Overhead Press',        bodyPart: 'Shoulders', target: 'Delts',        equipment: 'Barbell',    gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 's6', name: 'Romanian Deadlift',     bodyPart: 'Legs',      target: 'Hamstrings',   equipment: 'Barbell',    gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 's7', name: 'Dumbbell Row',          bodyPart: 'Back',      target: 'Lats',         equipment: 'Dumbbell',   gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 's8', name: 'Incline Dumbbell Press',bodyPart: 'Chest',     target: 'Pectorals',    equipment: 'Dumbbell',   gifUrl: '', difficulty: 'Intermediate'),
  ];

  static final _cardioExercises = [
    const ExerciseItem(id: 'c1', name: 'Treadmill Run',         bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Treadmill',  gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'c2', name: 'Cycling',               bodyPart: 'Legs',      target: 'Quads',        equipment: 'Bike',       gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'c3', name: 'Jump Rope',             bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Jump Rope',  gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'c4', name: 'Rowing Machine',        bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Rower',      gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'c5', name: 'Stair Climber',         bodyPart: 'Legs',      target: 'Glutes',       equipment: 'Stair Climber', gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'c6', name: 'Elliptical',            bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Elliptical', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'c7', name: 'Swimming Laps',         bodyPart: 'Full Body', target: 'Cardio',       equipment: 'Pool',       gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'c8', name: 'Battle Ropes',          bodyPart: 'Shoulders', target: 'Delts',        equipment: 'Rope',       gifUrl: '', difficulty: 'Advanced'),
  ];

  static final _recoveryExercises = [
    const ExerciseItem(id: 'r1', name: 'Child\'s Pose',         bodyPart: 'Back',      target: 'Spine',        equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'r2', name: 'Downward Dog',          bodyPart: 'Full Body', target: 'Hamstrings',   equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'r3', name: 'Hip Flexor Stretch',    bodyPart: 'Hips',      target: 'Hip Flexors',  equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'r4', name: 'Cat-Cow Stretch',       bodyPart: 'Back',      target: 'Spine',        equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'r5', name: 'Foam Roll Quads',       bodyPart: 'Legs',      target: 'Quads',        equipment: 'Foam Roll',   gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'r6', name: 'Seated Forward Fold',   bodyPart: 'Back',      target: 'Hamstrings',   equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
    const ExerciseItem(id: 'r7', name: 'Pigeon Pose',           bodyPart: 'Hips',      target: 'Glutes',       equipment: 'Body Weight', gifUrl: '', difficulty: 'Intermediate'),
    const ExerciseItem(id: 'r8', name: 'Thread the Needle',     bodyPart: 'Back',      target: 'Spine',        equipment: 'Body Weight', gifUrl: '', difficulty: 'Beginner'),
  ];
}
