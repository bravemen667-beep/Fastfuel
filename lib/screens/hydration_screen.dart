import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/health_provider.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDarkAlt,
      body: Stack(
        children: [
          // Glow blobs
          GlowBlob(color: AppColors.primary, size: 350, alignment: const Alignment(-0.8, -0.6), opacity: 0.15),
          GlowBlob(color: AppColors.neonBlue, size: 280, alignment: const Alignment(0.9, 0.5), opacity: 0.1),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: glassDecoration(borderRadius: 14),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text('Hydration Tracker',
                            style: AppTextStyles.headingMd),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: glassDecoration(borderRadius: 14),
                        child: const Icon(Icons.settings_rounded, color: AppColors.textPrimary, size: 18),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),

                        // ── Bottle Visual ────────────────
                        _BottleVisual(progress: health.waterProgress)
                          .animate().fadeIn(delay: 100.ms, duration: 600.ms),

                        const SizedBox(height: 20),

                        // ── Stats ────────────────────────
                        _WaterStats(health: health)
                          .animate().fadeIn(delay: 200.ms, duration: 500.ms),

                        const SizedBox(height: 20),

                        // ── Quick Add HUD ────────────────
                        _QuickAddHUD(health: health)
                          .animate().fadeIn(delay: 300.ms, duration: 500.ms),

                        const SizedBox(height: 20),

                        // ── Hourly Chart ─────────────────
                        _HourlyChart()
                          .animate().fadeIn(delay: 400.ms, duration: 500.ms),

                        const SizedBox(height: 16),

                        // ── Smart Reminders ──────────────
                        _SmartReminders(health: health)
                          .animate().fadeIn(delay: 500.ms, duration: 500.ms),

                        const SizedBox(height: 16),

                        // ── GoFaster Tip ─────────────────
                        _GoFasterTip()
                          .animate().fadeIn(delay: 600.ms, duration: 500.ms),

                        const SizedBox(height: 110),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────
//  Animated Bottle Visual
// ─────────────────────────────────────────────────────
class _BottleVisual extends StatefulWidget {
  final double progress;
  const _BottleVisual({required this.progress});

  @override
  State<_BottleVisual> createState() => _BottleVisualState();
}

class _BottleVisualState extends State<_BottleVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
          ),

          // Bottle container
          Container(
            width: 130,
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 32,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(
                children: [
                  // Liquid fill
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 210 * widget.progress,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeInOut,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.primary, AppColors.neonBlue],
                        ),
                      ),
                    ),
                  ),

                  // Wave effect line
                  AnimatedBuilder(
                    animation: _waveController,
                    builder: (_, __) {
                      final fillHeight = 210 * widget.progress;
                      return Positioned(
                        bottom: fillHeight - 6,
                        left: 0,
                        right: 0,
                        child: Opacity(
                          opacity: 0.4,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Measurement lines
                  ...List.generate(5, (i) {
                    return Positioned(
                      bottom: (210 / 5) * (i + 1),
                      left: 0,
                      child: Container(
                        width: i.isEven ? 32 : 20,
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    );
                  }),

                  // Percentage overlay
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(widget.progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const Text('GOAL',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white60,
                            letterSpacing: 2,
                          )),
                      ],
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

// ─────────────────────────────────────────────────────
//  Water Stats
// ─────────────────────────────────────────────────────
class _WaterStats extends StatelessWidget {
  final HealthProvider health;
  const _WaterStats({required this.health});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: '${health.waterConsumed.toInt()}',
                style: AppTextStyles.headingXL.copyWith(fontSize: 34),
              ),
              TextSpan(
                text: ' / ${health.waterGoal.toInt()} ml',
                style: AppTextStyles.headingSm.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('Remaining: ${health.waterRemaining}',
          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  Quick Add HUD
// ─────────────────────────────────────────────────────
class _QuickAddHUD extends StatelessWidget {
  final HealthProvider health;
  const _QuickAddHUD({required this.health});

  @override
  Widget build(BuildContext context) {
    final options = [150, 250, 500];
    return Row(
      children: [
        ...options.map((ml) {
          final isHighlighted = ml == 500;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => context.read<HealthProvider>().addWater(ml.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHighlighted
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text('+$ml',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        )),
                      const SizedBox(height: 2),
                      Text('ml',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        )),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: glassDecoration(borderRadius: 16),
              child: Column(
                children: [
                  const Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 18),
                  const SizedBox(height: 2),
                  Text('Custom',
                    style: AppTextStyles.label.copyWith(fontSize: 9)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  Hourly Flow Chart
// ─────────────────────────────────────────────────────
class _HourlyChart extends StatelessWidget {
  final _barHeights = const [0.30, 0.20, 0.60, 0.10, 0.90, 0.75, 0.40, 0.15, 0.05, 0.05, 0.05, 0.05];

  const _HourlyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: glassDecoration(borderRadius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('HOURLY FLOW',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textPrimary,
                      letterSpacing: 1.5,
                    )),
                ],
              ),
              NeonBadge(label: 'Optimal', color: AppColors.neonGreen),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _barHeights.map((h) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: BarChartColumn(
                    height: h,
                    color: h > 0.6
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: h < 0.15 ? 0.1 : 0.3 + h * 0.3),
                    width: double.infinity,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['08 AM', '12 PM', '04 PM', '08 PM'].map((t) =>
              Text(t, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted)),
            ).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Smart Reminders Toggle
// ─────────────────────────────────────────────────────
class _SmartReminders extends StatelessWidget {
  final HealthProvider health;
  const _SmartReminders({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassDecoration(borderRadius: 22),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.neonBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: AppColors.neonBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Smart Reminders', style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text('AI PERFORMANCE OPTIMIZATION',
                  style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 9)),
              ],
            ),
          ),
          PillToggle(
            value: health.waterReminders,
            onChanged: (v) => context.read<HealthProvider>().toggleWaterReminders(v),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  GoFaster Tip
// ─────────────────────────────────────────────────────
class _GoFasterTip extends StatelessWidget {
  const _GoFasterTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.25),
            AppColors.neonBlue.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.neonGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'GoFaster Tip: ',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: 'Dissolve your tablet in 250ml of water for best absorption.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
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
