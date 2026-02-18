import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/health_provider.dart';
import 'dart:math' as math;

class CalorieScreen extends StatelessWidget {
  const CalorieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDarkAlt,
      body: Stack(
        children: [
          GlowBlob(color: AppColors.neonOrange, size: 320, alignment: const Alignment(0.7, -0.6), opacity: 0.1),
          GlowBlob(color: AppColors.primary, size: 280, alignment: const Alignment(-0.9, 0.6), opacity: 0.08),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calorie Dashboard', style: AppTextStyles.headingMd),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.sync_rounded, color: AppColors.accentGreen, size: 14),
                              const SizedBox(width: 4),
                              Text('SYNCED WITH APPLE HEALTH',
                                style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: glassDecoration(borderRadius: 14),
                        child: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary, size: 18),
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
                        const SizedBox(height: 20),
                        _BurnGauge(health: health).animate().fadeIn(delay: 100.ms, duration: 600.ms),
                        const SizedBox(height: 20),
                        _ConsumedRemaining(health: health).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _MacroBreakdown(health: health).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _MealLog().animate().fadeIn(delay: 400.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _NutritionTip().animate().fadeIn(delay: 500.ms, duration: 500.ms),
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
//  Circular Burn Gauge
// ─────────────────────────────────────────────────────
class _BurnGauge extends StatelessWidget {
  final HealthProvider health;
  const _BurnGauge({required this.health});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(220, 220),
                painter: _GaugePainter(
                  progress: health.caloriesProgress,
                  color: AppColors.primary,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(health.caloriesBurned.toInt().toString(),
                    style: AppTextStyles.headingXL.copyWith(fontSize: 42)),
                  Text('/ 900 kcal',
                    style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  NeonBadge(label: 'Burned', color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatPill(label: 'Steps', value: '${health.steps.toStringAsFixed(0).replaceAll(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), r'$1,')}'),
            Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1), margin: const EdgeInsets.symmetric(horizontal: 24)),
            _StatPill(label: 'Active', value: '${health.activeMinutes} min'),
          ],
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _GaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 18) / 2;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke);

    // Glow
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headingSm.copyWith(fontSize: 18)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  Consumed / Remaining Cards
// ─────────────────────────────────────────────────────
class _ConsumedRemaining extends StatelessWidget {
  final HealthProvider health;
  const _ConsumedRemaining({required this.health});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricTile(
          dot: AppColors.accentBlue,
          label: 'Consumed',
          value: '${health.caloriesConsumed.toInt()}',
          unit: 'kcal',
        )),
        const SizedBox(width: 12),
        Expanded(child: _MetricTile(
          dot: AppColors.primary,
          label: 'Remaining',
          value: '${health.caloriesRemaining.toInt()}',
          unit: 'kcal',
          valueColor: AppColors.primary,
        )),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const _MetricTile({
    required this.dot,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: glassDecoration(borderRadius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 9, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTextStyles.headingLg.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted, fontSize: 12),
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
//  Macro Breakdown (Donut)
// ─────────────────────────────────────────────────────
class _MacroBreakdown extends StatelessWidget {
  final HealthProvider health;
  const _MacroBreakdown({required this.health});

  @override
  Widget build(BuildContext context) {
    final total = health.proteinG + health.carbsG + health.fatsG;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: glassDecoration(borderRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macro Breakdown', style: AppTextStyles.headingMd),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [health.proteinG, health.carbsG, health.fatsG],
                    total: total,
                    colors: [AppColors.primary, AppColors.accentBlue, AppColors.accentGreen],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _MacroRow(color: AppColors.primary, label: 'Protein', value: '${health.proteinG.toInt()}g'),
                    const SizedBox(height: 14),
                    _MacroRow(color: AppColors.accentBlue, label: 'Carbs', value: '${health.carbsG.toInt()}g'),
                    const SizedBox(height: 14),
                    _MacroRow(color: AppColors.accentGreen, label: 'Fats', value: '${health.fatsG.toInt()}g'),
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

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double total;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.total, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    double startAngle = -math.pi / 2;
    const strokeWidth = 16.0;

    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * (values[i] / total);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

class _MacroRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _MacroRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        Text(value, style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  Meal Log
// ─────────────────────────────────────────────────────
class _MealLog extends StatelessWidget {
  const _MealLog();

  @override
  Widget build(BuildContext context) {
    final meals = [
      _Meal('Post-Run Smoothie', '08:30 AM', 250, AppColors.accentBlue, Icons.blender_rounded),
      _Meal('Quinoa Salad Bowl', '01:15 PM', 480, AppColors.accentGreen, Icons.restaurant_rounded),
      _Meal('Greek Yogurt', '04:00 PM', 120, AppColors.primary, Icons.icecream_rounded),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Meals', style: AppTextStyles.headingMd),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...meals.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: glassDecoration(borderRadius: 20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(m.icon, color: m.color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(m.time, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ),
                ),
                Text('${m.calories} kcal',
                  style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _Meal {
  final String name, time;
  final int calories;
  final Color color;
  final IconData icon;
  const _Meal(this.name, this.time, this.calories, this.color, this.icon);
}

// ─────────────────────────────────────────────────────
//  Nutrition Tip
// ─────────────────────────────────────────────────────
class _NutritionTip extends StatelessWidget {
  const _NutritionTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'GoFaster Tip: ',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: 'Vitamin C boosts iron absorption — eat it with meals to maximize recovery.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.textSecondary,
                      fontSize: 13,
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
