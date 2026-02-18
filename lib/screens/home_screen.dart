import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/health_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // Ambient glow
          GlowBlob(color: AppColors.primary, size: 400, alignment: const Alignment(-0.6, -0.8), opacity: 0.1),
          GlowBlob(color: AppColors.neonBlue, size: 300, alignment: const Alignment(0.9, 0.2), opacity: 0.06),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppGradients.primaryGradient,
                            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)],
                          ),
                          child: const Center(
                            child: Text('A', style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good Morning, Alex ⚡',
                                style: AppTextStyles.headingMd),
                              Text('Monday, Oct 24',
                                style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        // Notification bell
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Stack(
                            children: [
                              const Center(child: Icon(Icons.notifications_rounded, color: AppColors.primary, size: 22)),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 500.ms),
                  ),
                ),
              ),

              // ── GoFaster Score Hero ───────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ScoreCard(score: health.score, delta: health.scoreDelta),
                ).animate().fadeIn(delay: 100.ms, duration: 600.ms).slideY(begin: 0.15),
              ),

              // ── Section: Vital Stats ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text('Vital Stats', style: AppTextStyles.headingMd),
                ),
              ),

              // ── Rings Grid ────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildListDelegate([
                    _VitalCard(
                      label: 'Water',
                      value: '${(health.waterConsumed / 1000).toStringAsFixed(1)}L',
                      unit: '/ ${(health.waterGoal / 1000).toStringAsFixed(1)}L',
                      progress: health.waterProgress,
                      color: AppColors.neonBlue,
                      icon: Icons.water_drop_rounded,
                    ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    _VitalCard(
                      label: 'Vitamins',
                      value: health.vitaminsDone == health.vitamins.length ? 'Taken' : '${health.vitaminsDone}/${health.vitamins.length}',
                      unit: health.vitaminsDone == health.vitamins.length ? '✓' : ' done',
                      progress: health.vitaminsDone / health.vitamins.length,
                      color: AppColors.neonGreen,
                      icon: Icons.medication_rounded,
                      valueColor: health.vitaminsDone == health.vitamins.length ? AppColors.neonGreen : null,
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                    _VitalCard(
                      label: 'Calories',
                      value: '${health.caloriesConsumed.toInt()}',
                      unit: '/ ${health.caloriesGoal.toInt()}',
                      progress: (health.caloriesConsumed / health.caloriesGoal).clamp(0, 1),
                      color: AppColors.neonOrange,
                      icon: Icons.local_fire_department_rounded,
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                    _VitalCard(
                      label: 'Sleep',
                      value: '${health.sleepScore.toInt()}',
                      unit: ' Score',
                      progress: health.sleepProgress,
                      color: AppColors.primary,
                      icon: Icons.bedtime_rounded,
                    ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                  ]),
                ),
              ),

              // ── Vitamin Reminder Card ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _VitaminReminder(),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ),

              // ── Quick Actions ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Actions', style: AppTextStyles.headingMd),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _QuickAction(icon: Icons.add_circle_outline_rounded, label: 'Log Water', color: AppColors.neonBlue),
                          const SizedBox(width: 10),
                          _QuickAction(icon: Icons.restaurant_rounded, label: 'Log Meal', color: AppColors.neonOrange),
                          const SizedBox(width: 10),
                          _QuickAction(icon: Icons.fitness_center_rounded, label: 'Workout', color: AppColors.primary),
                          const SizedBox(width: 10),
                          _QuickAction(icon: Icons.bedtime_rounded, label: 'Sleep', color: AppColors.indigo),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  GoFaster Score Card
// ─────────────────────────────────────────────────────
class _ScoreCard extends StatelessWidget {
  final double score;
  final double delta;
  const _ScoreCard({required this.score, required this.delta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          // Glow blobs
          Positioned(top: -40, right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(bottom: -40, left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.neonBlue.withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          Column(
            children: [
              Text('PERFORMANCE METRIC',
                style: AppTextStyles.label.copyWith(letterSpacing: 2.0, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (r) => AppGradients.primaryGradient.createShader(r),
                    child: Text(
                      score.toInt().toString(),
                      style: AppTextStyles.scoreHuge,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 12, left: 4),
                    child: Icon(Icons.bolt_rounded, color: AppColors.primary, size: 36),
                  ),
                ],
              ),
              Text("Today's GoFaster Score",
                style: AppTextStyles.headingSm.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.neonGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neonGreen.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded, color: AppColors.neonGreen, size: 16),
                    const SizedBox(width: 6),
                    Text('+${delta.toInt()}% from yesterday',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.neonGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Vital Stats Ring Card
// ─────────────────────────────────────────────────────
class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;
  final IconData icon;
  final Color? valueColor;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NeonProgressRing(
            progress: progress,
            ringColor: color,
            size: 80,
            strokeWidth: 9,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(label,
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.headingSm.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                    fontSize: 17,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Vitamin Reminder Banner
// ─────────────────────────────────────────────────────
class _VitaminReminder extends StatefulWidget {
  @override
  State<_VitaminReminder> createState() => _VitaminReminderState();
}

class _VitaminReminderState extends State<_VitaminReminder> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: Text('💊', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time for your GoFaster Tablet',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      )),
                    SizedBox(height: 3),
                    Text('Boost your recovery cycles',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white70,
                        fontSize: 12,
                      )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _dismissed = true),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Center(
                      child: Text('Mark as Taken',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Center(
                    child: Text('Dismiss',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Quick Action Button
// ─────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickAction({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label,
              style: AppTextStyles.label.copyWith(color: color, fontSize: 9),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
