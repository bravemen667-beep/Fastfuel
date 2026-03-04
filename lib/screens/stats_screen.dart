import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = const ['Week', 'Month', 'Year'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text('My Stats', style: AppTextStyles.h4),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(50),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  gradient: AppGradients.fire,
                  borderRadius: BorderRadius.circular(50),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: AppTextStyles.buttonSm,
                unselectedLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                tabs: _tabs.map((t) => Tab(text: t, height: 36)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            // Summary Cards
            _SummaryRow(hp: hp).animate().fade(duration: 500.ms),
            const SizedBox(height: 20),
            // Weekly Activity Chart
            _WeeklyActivityCard().animate(delay: 100.ms).fade(duration: 500.ms),
            const SizedBox(height: 20),
            // Metrics breakdown
            _MetricsBreakdown(hp: hp).animate(delay: 150.ms).fade(duration: 500.ms),
            const SizedBox(height: 20),
            // Achievement streak
            _StreakCard(hp: hp).animate(delay: 200.ms).fade(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final HealthProvider hp;
  const _SummaryRow({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MiniStatCard(
          icon: Icons.bolt_rounded,
          label: 'Score',
          value: hp.score.toInt().toString(),
          change: '+12%',
          color: AppColors.primary,
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard(
          icon: Icons.local_fire_department_rounded,
          label: 'Calories',
          value: '${hp.caloriesBurned.toInt()}',
          change: '+8%',
          color: AppColors.accent,
        )),
        const SizedBox(width: 10),
        Expanded(child: _MiniStatCard(
          icon: Icons.directions_walk_rounded,
          label: 'Steps',
          value: '8.4K',
          change: '+5%',
          color: AppColors.success,
        )),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final Color color;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h4.copyWith(color: color)),
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(change, style: AppTextStyles.label.copyWith(color: AppColors.success)),
          ),
        ],
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _water =   [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.5];
  static const _cals  =   [0.5, 0.7, 0.4, 0.9, 0.6, 0.8, 0.3];
  static const _sleep =   [0.7, 0.6, 0.8, 0.5, 0.7, 0.9, 0.6];

  @override
  Widget build(BuildContext context) {
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Weekly Activity'),
              Row(
                children: [
                  _Legend('Water', const Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  _Legend('Cals', AppColors.primary),
                  const SizedBox(width: 8),
                  _Legend('Sleep', const Color(0xFF9C27B0)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isToday = i == 4;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 6 ? 0 : 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: FractionallySizedBox(
                                heightFactor: _water[i],
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2196F3).withValues(
                                      alpha: isToday ? 1 : 0.5,
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                              )),
                              const SizedBox(width: 1),
                              Expanded(child: FractionallySizedBox(
                                heightFactor: _cals[i],
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: isToday ? 1 : 0.5),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                              )),
                              const SizedBox(width: 1),
                              Expanded(child: FractionallySizedBox(
                                heightFactor: _sleep[i],
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9C27B0).withValues(
                                      alpha: isToday ? 1 : 0.5,
                                    ),
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(_days[i], style: AppTextStyles.label.copyWith(
                          color: isToday ? AppColors.primary : AppColors.textMuted,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        )),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

class _MetricsBreakdown extends StatelessWidget {
  final HealthProvider hp;
  const _MetricsBreakdown({required this.hp});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Hydration Avg', '${(hp.waterProgress * 100).toInt()}%', AppColors.primary, Icons.water_drop_rounded, hp.waterProgress),
      _Metric('Calorie Goal', '${(hp.caloriesProgress * 100).toInt()}%', AppColors.accent, Icons.local_fire_department_rounded, hp.caloriesProgress),
      _Metric('Sleep Quality', '${hp.sleepScore.toInt()}/100', const Color(0xFF9C27B0), Icons.bedtime_rounded, hp.sleepProgress),
      _Metric('Vitamin Intake', '${hp.vitaminsDone}/${hp.vitamins.length} doses', AppColors.success, Icons.medication_rounded, hp.vitaminsDone / hp.vitamins.length),
    ];
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Performance Metrics'),
          const SizedBox(height: 16),
          ...metrics.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: m.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(m.icon, color: m.color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(m.label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary)),
                              Text(m.value, style: AppTextStyles.bodySm.copyWith(
                                color: m.color, fontWeight: FontWeight.w700,
                              )),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.border, borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: m.progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: m.color,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [BoxShadow(
                                    color: m.color.withValues(alpha: 0.4), blurRadius: 4,
                                  )],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _Metric {
  final String label, value;
  final Color color;
  final IconData icon;
  final double progress;
  const _Metric(this.label, this.value, this.color, this.icon, this.progress);
}

class _StreakCard extends StatelessWidget {
  final HealthProvider hp;
  const _StreakCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.fire,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20, spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text('🔥', style: const TextStyle(fontSize: 36)),
              Text('${hp.streakDays}', style: AppTextStyles.h1.copyWith(color: Colors.white)),
              Text('days', style: AppTextStyles.bodySm.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Streak', style: AppTextStyles.h4.copyWith(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  'You\'re on fire! Keep the momentum. Daily streaks boost your GoFaster Score by 25%.',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85), height: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text('Personal Best: ${hp.streakDays} days 🏆',
                    style: AppTextStyles.label.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
