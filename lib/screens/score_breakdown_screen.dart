// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Score Breakdown Screen
//  Detailed 4-pillar breakdown (Hydration 25, Sleep 25, Vitamins 25, Activity 25),
//  7-day trend chart, motivational message.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/nav_aware_scaffold.dart';

class ScoreBreakdownScreen extends StatelessWidget {
  const ScoreBreakdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HealthProvider>();

    // Compute 4 sub-scores out of 25
    final hydrationScore  = (hp.waterProgress.clamp(0.0, 1.0) * 25).roundToDouble();
    final sleepScore      = ((hp.sleepScore / 100).clamp(0.0, 1.0) * 25).roundToDouble();
    final vitaminScore    = (hp.vitamins.isEmpty ? 0.0 : (hp.vitaminsDone / hp.vitamins.length).clamp(0.0, 1.0) * 25).roundToDouble();
    final activityScore   = ((hp.caloriesProgress).clamp(0.0, 1.0) * 25).roundToDouble();
    final totalScore      = (hydrationScore + sleepScore + vitaminScore + activityScore);

    final pillars = [
      _Pillar('Hydration',  hydrationScore, Icons.water_drop_rounded,         const Color(0xFF2196F3)),
      _Pillar('Sleep',      sleepScore,     Icons.bedtime_rounded,             const Color(0xFF9C27B0)),
      _Pillar('Nutrition',  vitaminScore,   Icons.medication_rounded,          AppColors.success),
      _Pillar('Activity',   activityScore,  Icons.local_fire_department_rounded, AppColors.primary),
    ];

    final motivational = _motivationalMessage(totalScore);

    return NavAwareScaffold(
      activeTab: 0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, hp, totalScore),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Total Score Hero ────────────────────────────────────────
                _ScoreHeroCard(score: totalScore, motivational: motivational)
                    .animate().fade(duration: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 24),

                // ── 4 Pillar Breakdown ──────────────────────────────────────
                Text('Score Breakdown', style: AppTextStyles.h4)
                    .animate(delay: 100.ms).fade(duration: 400.ms),
                const SizedBox(height: 12),
                ...pillars.asMap().entries.map((e) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PillarCard(pillar: e.value)
                        .animate(delay: Duration(milliseconds: 150 + e.key * 60))
                        .fade(duration: 400.ms)
                        .slideX(begin: 0.1, end: 0),
                  ),
                ),
                const SizedBox(height: 8),

                // ── 7-Day Trend ─────────────────────────────────────────────
                _SevenDayTrend(hp: hp)
                    .animate(delay: 400.ms).fade(duration: 400.ms),
                const SizedBox(height: 24),

                // ── How Score is Calculated ─────────────────────────────────
                _HowItWorks()
                    .animate(delay: 500.ms).fade(duration: 400.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, HealthProvider hp, double score) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(60, 0, 130, 0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                Text('GoFaster Score', style: AppTextStyles.h3),
                const SizedBox(width: 8),
                const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            final name = hp.profileName.isNotEmpty ? hp.profileName : 'GoFaster User';
            final text = '⚡ $name scored ${score.toInt()}/100 on GoFaster today! 💪\n\n'
                'Tracking with GoFaster 👉 https://gofaster.in\n#GoFaster #StayActive';
            Share.share(text);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppGradients.fire,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.share_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('Share', style: AppTextStyles.buttonSm.copyWith(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _motivationalMessage(double score) {
    if (score >= 90) return '🏆 Incredible! You\'re in peak GoFaster form!';
    if (score >= 80) return '🔥 Outstanding performance! Top 15% today!';
    if (score >= 70) return '💪 Great work! A few tweaks and you\'ll crush 80+!';
    if (score >= 60) return '⚡ Good progress! Stay consistent and keep pushing!';
    if (score >= 50) return '🎯 You\'re halfway there — one habit at a time!';
    return '🌱 Every journey starts here. Let\'s build momentum today!';
  }
}

// ── Score Hero Card ───────────────────────────────────────────────────────────
class _ScoreHeroCard extends StatelessWidget {
  final double score;
  final String motivational;
  const _ScoreHeroCard({required this.score, required this.motivational});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 30, spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular progress
          SizedBox(
            width: 110, height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      score >= 80 ? AppColors.primary : score >= 60 ? AppColors.accent : AppColors.warning,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      score.toInt().toString(),
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primary, fontSize: 36,
                      ),
                    ),
                    Text('/100', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 13),
                      const SizedBox(width: 4),
                      Text('GoFaster Score',
                        style: AppTextStyles.label.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _scoreLabel(score),
                  style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(motivational,
                  style: AppTextStyles.bodySm.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(double score) {
    if (score >= 90) return 'Elite';
    if (score >= 80) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Average';
    if (score >= 50) return 'Below Avg';
    return 'Needs Work';
  }
}

// ── Pillar Card ───────────────────────────────────────────────────────────────
class _PillarCard extends StatelessWidget {
  final _Pillar pillar;
  const _PillarCard({required this.pillar});

  @override
  Widget build(BuildContext context) {
    final pct = pillar.score / 25;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: pillar.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(pillar.icon, color: pillar.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(pillar.name, style: AppTextStyles.h5),
                    Row(
                      children: [
                        Text(
                          '${pillar.score.toInt()}',
                          style: AppTextStyles.h4.copyWith(color: pillar.color),
                        ),
                        Text('/25',
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(pillar.color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _pillarTip(pillar.name, pillar.score),
                  style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pillarTip(String name, double score) {
    switch (name) {
      case 'Hydration':
        return score >= 20 ? '✅ Great hydration today!' : '💧 Drink ${(25 - score.toInt()) * 100}ml more water';
      case 'Sleep':
        return score >= 20 ? '✅ Well rested!' : '😴 Aim for 7–9 hrs for full score';
      case 'Nutrition':
        return score >= 20 ? '✅ Vitamins on track!' : '💊 Mark remaining vitamins as taken';
      case 'Activity':
        return score >= 20 ? '✅ Active day!' : '🏃 Burn more calories to boost score';
      default:
        return '';
    }
  }
}

// ── 7-Day Trend Chart ────────────────────────────────────────────────────────
class _SevenDayTrend extends StatelessWidget {
  final HealthProvider hp;
  const _SevenDayTrend({required this.hp});

  @override
  Widget build(BuildContext context) {
    // Derive 7-day score trend from sleep weekly (normalized to 100)
    final scores = hp.sleepWeekly.map((v) => (v * 100).clamp(0.0, 100.0)).toList();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: '7-Day Trend'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                      color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('+${hp.scoreDelta.toInt()}% vs last week',
                      style: AppTextStyles.label.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Text(days[i],
                          style: AppTextStyles.label.copyWith(fontSize: 9),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0, maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: scores.asMap().entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.primary,
                        strokeWidth: 1,
                        strokeColor: AppColors.background,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.primary.withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── How It Works ─────────────────────────────────────────────────────────────
class _HowItWorks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 8),
              Text('How It\'s Calculated', style: AppTextStyles.h5.copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 14),
          _rule('💧 Hydration (25 pts)', 'Based on % of daily water goal achieved'),
          _rule('😴 Sleep (25 pts)',     'Based on sleep score from last night'),
          _rule('💊 Nutrition (25 pts)', 'Based on vitamins taken out of total'),
          _rule('🔥 Activity (25 pts)',  'Based on calories burned vs. 900 kcal target'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Scores reset daily at midnight. Sync your health data and stay consistent for a high GoFaster Score!',
              style: AppTextStyles.bodySm.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Expanded(child: Text('— $desc', style: AppTextStyles.bodySm)),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────
class _Pillar {
  final String name;
  final double score;
  final IconData icon;
  final Color color;
  const _Pillar(this.name, this.score, this.icon, this.color);
}
