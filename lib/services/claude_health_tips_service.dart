// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Claude AI Health Tips Service
//  Uses Claude Sonnet for personalised home messages, hydration nudges,
//  sleep tips, vitamin streak coaching, and workout suggestions.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClaudeHealthTipsService {
  ClaudeHealthTipsService._();
  static final ClaudeHealthTipsService instance = ClaudeHealthTipsService._();

  static const _apiKey = 'YOUR_CLAUDE_API_KEY';
  static const _model  = 'claude-sonnet-4-5';
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';

  // ── Cache tips to avoid re-calling on every rebuild ──────────────────────
  final Map<String, String> _cache = {};

  // ── Home screen personalized greeting + motivation message ────────────────
  Future<String> getHomeMessage({
    required String userName,
    required int score,
    required double waterProgress,
    required double sleepHours,
    required int vitaminsLogged,
    required int caloriesBurned,
  }) async {
    final key = 'home_${score}_${waterProgress.toStringAsFixed(1)}_${sleepHours.toStringAsFixed(1)}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final prompt = '''
You are GoFaster AI, a motivational health coach. Generate a single SHORT (max 25 words) personalized message for $userName.

Context: GoFaster Score $score/100, Water: ${(waterProgress * 100).toInt()}% of goal, Sleep: ${sleepHours.toStringAsFixed(1)}h, Vitamins taken: $vitaminsLogged, Calories burned: $caloriesBurned.

Rules:
- Start with "$greeting, ${userName.split(' ').first}!"
- Be specific about ONE metric that needs attention
- Be motivating, not generic
- Max 25 words total
- End with an action tip

Return ONLY the message text, no formatting.
''';

    return _callClaude(prompt, fallback: '$greeting, ${userName.split(' ').first}! Score $score/100 today. Keep pushing — every healthy choice counts! 💪');
  }

  // ── Hydration nudge message ───────────────────────────────────────────────
  Future<String> getHydrationNudge({
    required double currentMl,
    required double goalMl,
    required double sleepHours,
    required int score,
  }) async {
    final pct = currentMl / goalMl;
    final key = 'hydration_${(pct * 10).round()}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final prompt = '''
You are GoFaster AI hydration coach. Give ONE short hydration tip (max 20 words).

Context: Drank ${currentMl.toInt()}ml of ${goalMl.toInt()}ml goal (${(pct * 100).toInt()}% done). Sleep: ${sleepHours.toStringAsFixed(1)}h.

Return ONLY the tip. Be specific, motivating, science-based. No hashtags.
''';

    final fallbacks = [
      if (pct < 0.3) 'Your body is ${(100 - pct * 100).toInt()}% behind on hydration. Drink a glass now — performance drops with dehydration! 💧',
      if (pct >= 0.3 && pct < 0.7) 'Halfway there! A glass of water now boosts focus by 14%. Keep it up! 💧',
      'Amazing! You\'ve hit your hydration target. Staying hydrated improves sleep quality too! 💧',
    ];

    return _callClaude(prompt, fallback: fallbacks.first);
  }

  // ── Sleep tip message ─────────────────────────────────────────────────────
  Future<String> getSleepTip({
    required double sleepHours,
    required int score,
    required double deepSleepPct,
  }) async {
    final key = 'sleep_${sleepHours.toStringAsFixed(0)}_${deepSleepPct.toStringAsFixed(0)}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final prompt = '''
You are GoFaster AI sleep coach. Give ONE actionable sleep improvement tip (max 20 words).

Context: Slept ${sleepHours.toStringAsFixed(1)} hours. Deep sleep: ${(deepSleepPct * 100).toInt()}%.

Return ONLY the tip. Science-backed, specific, actionable.
''';

    String fallback;
    if (sleepHours < 6) {
      fallback = 'You need ${(7 - sleepHours).toStringAsFixed(0)} more hours. Set a consistent bedtime to rebuild your sleep debt.';
    } else if (deepSleepPct < 0.2) {
      fallback = 'Low deep sleep detected. Avoid screens 1h before bed to boost deep sleep quality.';
    } else {
      fallback = 'Great sleep quality! Consistent sleep schedules maximise recovery and performance. Keep it up!';
    }

    return _callClaude(prompt, fallback: fallback);
  }

  // ── Vitamin streak coach ──────────────────────────────────────────────────
  Future<String> getVitaminCoachMessage({
    required int streak,
    required int vitaminsTaken,
    required int vitaminTotal,
  }) async {
    final key = 'vitamin_${streak}_${vitaminsTaken}_$vitaminTotal';
    if (_cache.containsKey(key)) return _cache[key]!;

    final prompt = '''
You are GoFaster AI vitamin coach. Give ONE motivating message about vitamin adherence (max 20 words).

Context: $vitaminsTaken/$vitaminTotal vitamins taken today. Current streak: $streak days.

Return ONLY the message. Celebratory if all taken, encouraging if some missed.
''';

    final fallback = streak > 7
        ? '🔥 $streak day streak! Your consistent vitamin intake is building real metabolic health benefits!'
        : vitaminsTaken == vitaminTotal
            ? '✅ All vitamins taken! Consistency is your superpower — keep this streak going!'
            : '${vitaminTotal - vitaminsTaken} vitamins remaining. Set a reminder — consistency builds long-term results!';

    return _callClaude(prompt, fallback: fallback);
  }

  // ── Internal Claude API call ──────────────────────────────────────────────
  Future<String> _callClaude(String prompt, {required String fallback}) async {
    if (_apiKey == 'YOUR_CLAUDE_API_KEY') return fallback;

    try {
      final res = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 100,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data    = jsonDecode(res.body) as Map<String, dynamic>;
        final content = (data['content'] as List?)?.first;
        final text    = (content?['text'] as String?)?.trim() ?? '';
        if (text.isNotEmpty) {
          // Cache result for this session
          return text;
        }
      }
    } catch (e) {
      debugPrint('[ClaudeHealthTips] error: $e');
    }
    return fallback;
  }

  void clearCache() => _cache.clear();
}
