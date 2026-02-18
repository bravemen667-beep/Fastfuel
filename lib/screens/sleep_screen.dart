import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/health_provider.dart';
import 'dart:math' as math;

class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDarkDeep,
      body: Stack(
        children: [
          // Deep space gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.5, -0.5),
                radius: 1.2,
                colors: [
                  const Color(0xFF1a0033).withValues(alpha: 0.8),
                  AppColors.bgDarkDeep,
                ],
              ),
            ),
          ),
          GlowBlob(color: AppColors.primary, size: 300, alignment: const Alignment(0.7, -0.7), opacity: 0.12),
          GlowBlob(color: AppColors.indigo, size: 250, alignment: const Alignment(-0.6, 0.6), opacity: 0.08),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Sticky Header ────────────────────────
                Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: glassDecoration(borderRadius: 14, borderColor: AppColors.primary.withValues(alpha: 0.2)),
                          child: const Icon(Icons.calendar_today_rounded, color: AppColors.textPrimary, size: 18),
                        ),
                        Column(
                          children: [
                            Text('Sleep Analysis', style: AppTextStyles.headingSm),
                            Text('SYNCED WITH HEALTHKIT • 2M AGO',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontSize: 8,
                                letterSpacing: 1,
                              )),
                          ],
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: glassDecoration(borderRadius: 14, borderColor: AppColors.primary.withValues(alpha: 0.2)),
                          child: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 18),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _SleepScoreRing(health: health).animate().fadeIn(delay: 100.ms, duration: 600.ms),
                        const SizedBox(height: 20),
                        _GoFasterInsight().animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _BedtimeWakeRow(health: health).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _SleepStagesChart(health: health).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _WeeklyTrend(health: health).animate().fadeIn(delay: 500.ms, duration: 500.ms),
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
//  Sleep Score Ring
// ─────────────────────────────────────────────────────
class _SleepScoreRing extends StatelessWidget {
  final HealthProvider health;
  const _SleepScoreRing({required this.health});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _GradientRingPainter(
                  progress: health.sleepProgress,
                  colors: [AppColors.primary, AppColors.accentBlue],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    health.sleepScore.toInt().toString(),
                    style: AppTextStyles.scoreHuge.copyWith(fontSize: 52),
                  ),
                  Text('SCORE',
                    style: AppTextStyles.label.copyWith(color: AppColors.textMuted, letterSpacing: 2)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeonBadge(label: 'Good Quality', color: AppColors.primary),
            const SizedBox(width: 10),
            NeonBadge(label: '+5% vs Last Week', color: AppColors.accentGreen, textColor: AppColors.accentGreen),
          ],
        ),
      ],
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _GradientRingPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Track
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke);

    // Gradient glow
    final sweepAngle = 2 * math.pi * progress;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Glow layer
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: colors,
          tileMode: TileMode.clamp,
        ).createShader(rect)
        ..strokeWidth = 18
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Sharp arc
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: colors,
          tileMode: TileMode.clamp,
        ).createShader(rect)
        ..strokeWidth = 10
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GradientRingPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────
//  GoFaster Insight Banner
// ─────────────────────────────────────────────────────
class _GoFasterInsight extends StatelessWidget {
  const _GoFasterInsight();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GOFASTER INSIGHT',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  )),
                SizedBox(height: 6),
                Text(
                  'Low sleep = low energy. Your B12 tablet can help combat fatigue from reduced sleep cycles.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('LEARN MORE',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 1,
                      )),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 14),
                  ],
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
//  Bedtime & Wake Row
// ─────────────────────────────────────────────────────
class _BedtimeWakeRow extends StatelessWidget {
  final HealthProvider health;
  const _BedtimeWakeRow({required this.health});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TimeCard(
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF818CF8),
          label: 'Bedtime',
          time: health.bedtime,
        )),
        const SizedBox(width: 12),
        Expanded(child: _TimeCard(
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFFB923C),
          label: 'Woke up',
          time: health.wakeTime,
        )),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;

  const _TimeCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A190F23),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 9)),
              const SizedBox(height: 3),
              Text(time, style: AppTextStyles.headingSm.copyWith(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Sleep Stages Chart
// ─────────────────────────────────────────────────────
class _SleepStagesChart extends StatelessWidget {
  final HealthProvider health;
  const _SleepStagesChart({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x1A190F23),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sleep Stages', style: AppTextStyles.headingSm),
                  const SizedBox(height: 2),
                  Text('Total: ${health.sleepDuration}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                ],
              ),
              NeonBadge(
                label: '${(health.sleepEfficiency * 100).toInt()}% Efficiency',
                color: AppColors.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stage bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: health.sleepStages.map((stage) {
              return Expanded(
                flex: ((stage.widthFraction * 100).toInt()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        height: 100 * stage.heightFraction,
                        decoration: BoxDecoration(
                          color: stage.color.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          border: stage.name == 'REM'
                              ? Border(top: BorderSide(color: stage.color, width: 2))
                              : null,
                          boxShadow: stage.name == 'REM'
                              ? [BoxShadow(color: stage.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -4))]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: 10),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _LegendDot(color: AppColors.primary, label: 'REM'),
              _LegendDot(color: const Color(0xFF60A5FA), label: 'Core'),
              _LegendDot(color: const Color(0xFF1E3A8A), label: 'Deep'),
              _LegendDot(color: const Color(0xFFEF4444), label: 'Awake'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label.toUpperCase(),
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 9)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  7-Day Weekly Trend
// ─────────────────────────────────────────────────────
class _WeeklyTrend extends StatelessWidget {
  final HealthProvider health;
  const _WeeklyTrend({required this.health});

  final _days = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x1A190F23),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('7-DAY TREND',
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted, letterSpacing: 2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final isToday = i == 3;
              return Column(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 600 + i * 100),
                    curve: Curves.easeOutCubic,
                    width: 8,
                    height: 80 * health.sleepWeekly[i],
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isToday
                          ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 10)]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_days[i],
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isToday ? AppColors.primary : AppColors.textMuted,
                    )),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
