// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Claude AI Workout Service
//  Uses Claude Sonnet for personalised workout text suggestions based on
//  user's GoFaster Score, sleep quality, fitness goal and level.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WorkoutPlan {
  final String title;
  final String description;
  final String intensity;
  final int durationMinutes;
  final int estimatedCalories;
  final List<WorkoutSet> sets;
  final String warmup;
  final String cooldown;
  final String aiInsight;

  const WorkoutPlan({
    required this.title,
    required this.description,
    required this.intensity,
    required this.durationMinutes,
    required this.estimatedCalories,
    required this.sets,
    required this.warmup,
    required this.cooldown,
    required this.aiInsight,
  });
}

class WorkoutSet {
  final String exercise;
  final String sets;
  final String reps;
  final String rest;
  final String muscleGroup;

  const WorkoutSet({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.rest,
    required this.muscleGroup,
  });
}

class ClaudeWorkoutService {
  ClaudeWorkoutService._();
  static final ClaudeWorkoutService instance = ClaudeWorkoutService._();

  // Claude API key - loaded from app config
  static const _apiKey = 'YOUR_CLAUDE_API_KEY';
  static const _model  = 'claude-sonnet-4-5';
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  Future<WorkoutPlan> generatePlan({
    required double goFasterScore,
    required String sleepDuration,
    required double sleepScore,
    required String fitnessGoal,
    required String fitnessLevel,
    required String workoutType,
    required int activeMinutes,
  }) async {
    // Build personalised prompt
    final prompt = '''You are a world-class fitness coach for the GoFaster Health app. 
Create a personalised workout plan based on:
- GoFaster Score: ${goFasterScore.toInt()}/100
- Sleep last night: $sleepDuration (quality score: ${sleepScore.toInt()}/100)
- Fitness goal: $fitnessGoal
- Fitness level: $fitnessLevel
- Preferred workout: $workoutType
- Active minutes today: $activeMinutes

Respond ONLY with a valid JSON object (no markdown) in this exact format:
{
  "title": "Workout title",
  "description": "One sentence description",
  "intensity": "Low|Moderate|High|Very High",
  "duration_minutes": 30,
  "estimated_calories": 350,
  "warmup": "5-minute warm-up description",
  "cooldown": "5-minute cool-down description",
  "ai_insight": "Personalised 1-sentence insight based on their data",
  "sets": [
    {"exercise": "Exercise name", "sets": "3", "reps": "12", "rest": "60s", "muscle_group": "Chest"},
    {"exercise": "Exercise name", "sets": "3", "reps": "15", "rest": "45s", "muscle_group": "Core"}
  ]
}

Include 5-7 exercises appropriate for $fitnessLevel level. If sleep score < 60, reduce intensity.''';

    try {
      final res = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [{'role': 'user', 'content': prompt}],
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final content = ((body['content'] as List?)?.first)?['text'] as String? ?? '';
        // Extract JSON from response
        final jsonStart = content.indexOf('{');
        final jsonEnd   = content.lastIndexOf('}') + 1;
        if (jsonStart >= 0 && jsonEnd > jsonStart) {
          final planJson = jsonDecode(content.substring(jsonStart, jsonEnd)) as Map<String, dynamic>;
          return _parsePlan(planJson);
        }
      }
    } catch (e) {
      debugPrint('[Claude] generatePlan error: $e');
    }
    // Fallback to rule-based plan
    return _fallbackPlan(goFasterScore, sleepScore, fitnessLevel, workoutType, fitnessGoal);
  }

  WorkoutPlan _parsePlan(Map<String, dynamic> j) {
    final rawSets = (j['sets'] as List?) ?? [];
    return WorkoutPlan(
      title:             (j['title']             as String?) ?? 'GoFaster Workout',
      description:       (j['description']       as String?) ?? 'Personalised workout plan',
      intensity:         (j['intensity']         as String?) ?? 'Moderate',
      durationMinutes:   (j['duration_minutes']  as int?)    ?? 30,
      estimatedCalories: (j['estimated_calories'] as int?)   ?? 300,
      warmup:            (j['warmup']            as String?) ?? '5-min light cardio',
      cooldown:          (j['cooldown']          as String?) ?? '5-min stretching',
      aiInsight:         (j['ai_insight']        as String?) ?? 'Stay consistent and push yourself!',
      sets: rawSets.map((s) {
        final sm = s as Map<String, dynamic>;
        return WorkoutSet(
          exercise:    (sm['exercise']     as String?) ?? 'Exercise',
          sets:        (sm['sets']         as String?) ?? '3',
          reps:        (sm['reps']         as String?) ?? '12',
          rest:        (sm['rest']         as String?) ?? '60s',
          muscleGroup: (sm['muscle_group'] as String?) ?? 'Full Body',
        );
      }).toList(),
    );
  }

  WorkoutPlan _fallbackPlan(
    double score, double sleepScore, String level, String type, String goal,
  ) {
    final isLowSleep = sleepScore < 60;
    final isHigh     = score > 75 && !isLowSleep;

    final allPlans = {
      'HIIT': WorkoutPlan(
        title: isLowSleep ? 'Active Recovery HIIT' : 'Explosive HIIT Circuit',
        description: isLowSleep
            ? 'Lower-intensity HIIT to support recovery after poor sleep'
            : 'High-intensity intervals to maximise calorie burn and boost your score',
        intensity: isLowSleep ? 'Low' : 'High',
        durationMinutes: isLowSleep ? 20 : 30,
        estimatedCalories: isLowSleep ? 180 : 380,
        warmup: '5 min light jog + dynamic stretching',
        cooldown: '5 min static stretching + deep breathing',
        aiInsight: isLowSleep
            ? 'Your sleep score is low — keeping today\'s intensity moderate helps recovery.'
            : 'Your GoFaster Score of ${score.toInt()} is great! Push hard today.',
        sets: [
          const WorkoutSet(exercise: 'Burpee', sets: '3', reps: '10', rest: '60s', muscleGroup: 'Full Body'),
          const WorkoutSet(exercise: 'Jump Squat', sets: '3', reps: '15', rest: '45s', muscleGroup: 'Legs'),
          const WorkoutSet(exercise: 'Mountain Climber', sets: '3', reps: '20', rest: '45s', muscleGroup: 'Core'),
          const WorkoutSet(exercise: 'High Knees', sets: '3', reps: '30s', rest: '30s', muscleGroup: 'Cardio'),
          const WorkoutSet(exercise: 'Push-Up', sets: '3', reps: '12', rest: '60s', muscleGroup: 'Chest'),
        ],
      ),
      'Strength': WorkoutPlan(
        title: 'GoFaster Strength Session',
        description: 'Build muscle and power with compound movements',
        intensity: isHigh ? 'High' : 'Moderate',
        durationMinutes: 45,
        estimatedCalories: 320,
        warmup: '5 min light cardio + mobility work',
        cooldown: '10 min full-body stretch',
        aiInsight: 'Focus on progressive overload — add 5% weight each session.',
        sets: [
          const WorkoutSet(exercise: 'Squat', sets: '4', reps: '8', rest: '90s', muscleGroup: 'Legs'),
          const WorkoutSet(exercise: 'Bench Press', sets: '4', reps: '8', rest: '90s', muscleGroup: 'Chest'),
          const WorkoutSet(exercise: 'Deadlift', sets: '3', reps: '5', rest: '120s', muscleGroup: 'Back'),
          const WorkoutSet(exercise: 'Overhead Press', sets: '3', reps: '10', rest: '90s', muscleGroup: 'Shoulders'),
          const WorkoutSet(exercise: 'Pull-Up', sets: '3', reps: '8', rest: '90s', muscleGroup: 'Back'),
        ],
      ),
      'Cardio': WorkoutPlan(
        title: 'Endurance Cardio Blast',
        description: 'Improve cardiovascular fitness and burn calories steadily',
        intensity: 'Moderate',
        durationMinutes: 35,
        estimatedCalories: 280,
        warmup: '5 min brisk walk',
        cooldown: '5 min easy walk + stretching',
        aiInsight: 'Steady-state cardio helps build aerobic base and supports sleep quality.',
        sets: [
          const WorkoutSet(exercise: 'Treadmill Run', sets: '1', reps: '20 min', rest: '0s', muscleGroup: 'Cardio'),
          const WorkoutSet(exercise: 'Jump Rope', sets: '3', reps: '1 min', rest: '30s', muscleGroup: 'Full Body'),
          const WorkoutSet(exercise: 'Cycling', sets: '1', reps: '10 min', rest: '0s', muscleGroup: 'Legs'),
          const WorkoutSet(exercise: 'Battle Ropes', sets: '3', reps: '30s', rest: '30s', muscleGroup: 'Shoulders'),
        ],
      ),
      'Yoga': WorkoutPlan(
        title: 'GoFaster Yoga Flow',
        description: 'Mindful movement to improve flexibility and recovery',
        intensity: 'Low',
        durationMinutes: 30,
        estimatedCalories: 120,
        warmup: '3 min deep breathing',
        cooldown: '5 min savasana',
        aiInsight: 'Yoga improves sleep quality — perfect for boosting your Sleep score!',
        sets: [
          const WorkoutSet(exercise: 'Sun Salutation', sets: '3', reps: '5 cycles', rest: '30s', muscleGroup: 'Full Body'),
          const WorkoutSet(exercise: 'Warrior I & II', sets: '2', reps: '30s each', rest: '15s', muscleGroup: 'Legs'),
          const WorkoutSet(exercise: 'Downward Dog', sets: '3', reps: '30s', rest: '15s', muscleGroup: 'Full Body'),
          const WorkoutSet(exercise: 'Child\'s Pose', sets: '2', reps: '60s', rest: '0s', muscleGroup: 'Back'),
          const WorkoutSet(exercise: 'Pigeon Pose', sets: '2', reps: '45s each side', rest: '15s', muscleGroup: 'Hips'),
        ],
      ),
    };

    return allPlans[type] ?? allPlans['HIIT']!;
  }
}
