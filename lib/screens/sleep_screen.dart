// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Sleep Screen (Complete Rebuild)
//  Reference: Sleep Cycle, SleepScore
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../widgets/common_widgets.dart';

// ─── Sleep Data model ─────────────────────────────────────────────────────────
class SleepData {
  final String bedtime;
  final String wakeTime;
  final double totalHours;
  final double efficiency;
  final double score;
  final String quality;

  const SleepData({
    required this.bedtime,
    required this.wakeTime,
    required this.totalHours,
    required this.efficiency,
    required this.score,
    required this.quality,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  SleepData _sleep = const SleepData(
    bedtime: '11:15 PM',
    wakeTime: '06:57 AM',
    totalHours: 7.7,
    efficiency: 0.88,
    score: 82,
    quality: 'Good Quality',
  );

  // 7-day data (hours)
  final List<double> _weekly = [6.5, 7.2, 5.8, 7.7, 6.3, 8.1, 7.7];

  // Sleep stages (8 bars for the night hours)
  final List<_SleepStage> _stages = [
    _SleepStage('Awake',   0.2, const Color(0xFF616161)),
    _SleepStage('Core',    1.4, const Color(0xFFFFB347)),
    _SleepStage('Deep',    1.1, AppColors.primary),
    _SleepStage('REM',     0.9, const Color(0xFFFF6B00)),
    _SleepStage('Core',    1.8, const Color(0xFFFFB347)),
    _SleepStage('Deep',    0.8, AppColors.primary),
    _SleepStage('REM',     0.7, const Color(0xFFFF6B00)),
    _SleepStage('Awake',   0.1, const Color(0xFF616161)),
  ];

  final bool _loading = false;

  Future<void> _loadSavedSleep() async {
    final p = await SharedPreferences.getInstance();
    final bt = p.getString('sleep_bedtime');
    final wt = p.getString('sleep_waketime');
    if (bt != null && wt != null && mounted) {
      setState(() {
        _sleep = SleepData(
          bedtime:    bt,
          wakeTime:   wt,
          totalHours: p.getDouble('sleep_hours') ?? 7.7,
          efficiency: p.getDouble('sleep_efficiency') ?? 0.88,
          score:      p.getDouble('sleep_score') ?? 82,
          quality:    p.getString('sleep_quality') ?? 'Good Quality',
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedSleep();
  }

  void _openLogSleepSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _LogSleepSheet(
        initialBedtime: _sleep.bedtime,
        initialWake: _sleep.wakeTime,
        onSave: (bt, wt, hours) async {
          Navigator.pop(ctx);
          HapticFeedback.lightImpact();
          // Compute quality from hours
          String quality;
          double score;
          if (hours >= 8.0) { quality = 'Excellent'; score = 92; }
          else if (hours >= 7.0) { quality = 'Good Quality'; score = 82; }
          else if (hours >= 6.0) { quality = 'Fair'; score = 68; }
          else { quality = 'Poor'; score = 50; }

          final p = await SharedPreferences.getInstance();
          await p.setString('sleep_bedtime', bt);
          await p.setString('sleep_waketime', wt);
          await p.setDouble('sleep_hours', hours);
          await p.setDouble('sleep_score', score);
          await p.setString('sleep_quality', quality);

          if (mounted) {
            setState(() {
              _sleep = SleepData(
                bedtime: bt, wakeTime: wt, totalHours: hours,
                efficiency: 0.88, score: score, quality: quality,
              );
            });
          }
          // Sync with HealthProvider
          if (mounted) {
            context.read<HealthProvider>().updateSleepData(
              score: score,
              bedtime: bt,
              wakeTime: wt,
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: const Color(0xFF1B1B3A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              content: Row(children: [
                const Icon(Icons.bedtime_rounded,
                    color: Color(0xFF9C27B0)),
                const SizedBox(width: 8),
                Text('Sleep logged: ${hours.toStringAsFixed(1)}h 😴',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ]),
            ));
          }
        },
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: OrangeLoader()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _SleepScoreCard(sleep: _sleep)
                  .animate().fade(duration: 450.ms).slideY(begin: 0.15, end: 0),
              const SizedBox(height: 16),
              _BedtimeWakeCard(sleep: _sleep)
                  .animate(delay: 80.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _SleepStagesCard(stages: _stages)
                  .animate(delay: 120.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _WeeklyTrendCard(weekly: _weekly)
                  .animate(delay: 160.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _SleepTip(sleep: _sleep)
                  .animate(delay: 200.ms).fade(duration: 450.ms),
              const SizedBox(height: 20),
              GFPrimaryButton(
                label: 'Log Sleep',
                icon: Icons.bedtime_rounded,
                onTap: _openLogSleepSheet,
              ).animate(delay: 240.ms).fade(duration: 450.ms),
            ])),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.background,
      expandedHeight: kToolbarHeight + MediaQuery.of(context).padding.top,
      collapsedHeight: kToolbarHeight,
      automaticallyImplyLeading: false,
      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sleep Analysis', style: AppTextStyles.h3),
                  Text('Last Night\'s Data',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.4)),
              ),
              child: const Text('LAST NIGHT',
                  style: TextStyle(
                      color: Color(0xFF9C27B0), fontWeight: FontWeight.w700,
                      fontSize: 11, fontFamily: 'Poppins')),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Sleep Score Card ─────────────────────────────────────────────────────────
class _SleepScoreCard extends StatelessWidget {
  final SleepData sleep;
  const _SleepScoreCard({required this.sleep});

  Color get _qualityColor {
    if (sleep.quality.contains('Excellent')) return const Color(0xFF66BB6A);
    if (sleep.quality.contains('Good'))      return const Color(0xFF66BB6A);
    if (sleep.quality.contains('Fair'))      return const Color(0xFFFFB347);
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return GFCard(
      child: Row(children: [
        // Donut arc + score
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(120, 120),
              painter: _SleepArcPainter(progress: sleep.score / 100),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.bedtime_rounded,
                  color: Color(0xFF9C27B0), size: 22),
              Text('${sleep.score.toInt()}',
                  style: const TextStyle(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
              const Text('/100', style: TextStyle(
                  color: AppColors.textMuted, fontSize: 10,
                  fontFamily: 'Poppins')),
            ]),
          ]),
        ),
        const SizedBox(width: 16),
        // Right stats
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _qualityColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(sleep.quality, style: TextStyle(
                  color: _qualityColor, fontWeight: FontWeight.w700,
                  fontSize: 12, fontFamily: 'Poppins')),
            ),
            const SizedBox(height: 10),
            const Text('Sleep Duration',
                style: TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, fontFamily: 'Poppins')),
            Text(_formatHours(sleep.totalHours),
                style: const TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('+5% vs Last Week',
                    style: TextStyle(color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.w600, fontSize: 11,
                        fontFamily: 'Poppins')),
              ),
            ]),
            const SizedBox(height: 4),
            Text('Efficiency: ${(sleep.efficiency * 100).toInt()}%',
                style: const TextStyle(color: Color(0xFF9C27B0),
                    fontSize: 12, fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
        )),
      ]),
    );
  }

  String _formatHours(double h) {
    final hrs  = h.toInt();
    final mins = ((h - hrs) * 60).toInt();
    return '${hrs}h ${mins}m';
  }
}

class _SleepArcPainter extends CustomPainter {
  final double progress;
  const _SleepArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final paint = Paint()
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        -math.pi / 2, 2 * math.pi, false,
        paint..color = AppColors.border);

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        paint
          ..shader = SweepGradient(
            colors: [AppColors.primary, AppColors.error],
            startAngle: -math.pi / 2,
            endAngle: -math.pi / 2 + 2 * math.pi * progress,
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_SleepArcPainter o) => o.progress != progress;
}

// ─── Bedtime / Wake Card ──────────────────────────────────────────────────────
class _BedtimeWakeCard extends StatelessWidget {
  final SleepData sleep;
  const _BedtimeWakeCard({required this.sleep});

  @override
  Widget build(BuildContext context) {
    return GFCard(
      child: Row(children: [
        Expanded(child: _TimeBlock(
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF9C27B0),
          label: 'Bedtime',
          time: sleep.bedtime,
          timeColor: const Color(0xFF9C27B0),
        )),
        Container(width: 1, height: 60, color: AppColors.border),
        Expanded(child: _TimeBlock(
          icon: Icons.wb_sunny_rounded,
          iconColor: AppColors.primary,
          label: 'Wake Up',
          time: sleep.wakeTime,
          timeColor: AppColors.primary,
        )),
      ]),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   time;
  final Color    timeColor;

  const _TimeBlock({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.timeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, color: iconColor, size: 28),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      Text(time, style: TextStyle(
          color: timeColor, fontSize: 20,
          fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
    ]);
  }
}

// ─── Sleep Stages Card ────────────────────────────────────────────────────────
class _SleepStage {
  final String name;
  final double hours;
  final Color  color;
  const _SleepStage(this.name, this.hours, this.color);
}

class _SleepStagesCard extends StatelessWidget {
  final List<_SleepStage> stages;
  const _SleepStagesCard({required this.stages});

  @override
  Widget build(BuildContext context) {
    final maxH = stages.map((s) => s.hours).reduce(math.max);

    return GFCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Sleep Stages'),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: stages.asMap().entries.map((e) {
              final s = e.value;
              final h = (s.hours / maxH).clamp(0.0, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: h * 80,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: ['11pm', '1am', '3am', '5am', '7am'].map((t) => Expanded(
          child: Text(t, textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted,
                  fontSize: 9, fontFamily: 'Poppins')),
        )).toList()),
        const SizedBox(height: 16),
        // Legend
        Wrap(spacing: 16, runSpacing: 8, children: [
          _buildLegendDot('REM', const Color(0xFFFF6B00)),
          _buildLegendDot('Core', const Color(0xFFFFB347)),
          _buildLegendDot('Deep', AppColors.primary),
          _buildLegendDot('Awake', const Color(0xFF616161)),
        ]),
      ]),
    );
  }

  Widget _buildLegendDot(String label, Color c) => Row(
    mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(
        color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Poppins')),
  ]);
}

// ─── 7-day Trend Card ─────────────────────────────────────────────────────────
class _WeeklyTrendCard extends StatelessWidget {
  final List<double> weekly;
  const _WeeklyTrendCard({required this.weekly});

  @override
  Widget build(BuildContext context) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final todayIdx = DateTime.now().weekday % 7;

    return GFCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: '7-Day Sleep Trend'),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: 10,
              minY: 0,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (val, _) {
                      if (val % 2 == 0 && val <= 10) {
                        return Text('${val.toInt()}h',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 9,
                                fontFamily: 'Poppins'));
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= days.length) { return const SizedBox(); }
                      return Text(days[i],
                          style: TextStyle(
                              color: i == todayIdx
                                  ? AppColors.primary : AppColors.textMuted,
                              fontWeight: i == todayIdx
                                  ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 11, fontFamily: 'Poppins'));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: weekly.asMap().entries.map((e) {
                final i = e.key;
                final h = e.value;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: h,
                    color: i == todayIdx
                        ? AppColors.primary
                        : const Color(0xFF9C27B0),
                    width: 20,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Avg ${(weekly.reduce((a, b) => a + b) / weekly.length).toStringAsFixed(1)}h / night',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ]),
    );
  }
}

// ─── Sleep Tip ────────────────────────────────────────────────────────────────
class _SleepTip extends StatelessWidget {
  final SleepData sleep;
  const _SleepTip({required this.sleep});

  @override
  Widget build(BuildContext context) {
    final msg = sleep.totalHours < 7
        ? 'You got less than 7 hours last night. Try sleeping 30 min earlier tonight.'
        : 'Great sleep! Your GoFaster tablet B12 formula helps maintain energy levels after a good rest.';

    return InfoBanner(
      icon: Icons.bedtime_rounded,
      message: msg,
      color: const Color(0xFF9C27B0),
    );
  }
}

// ─── Log Sleep Bottom Sheet ───────────────────────────────────────────────────
class _LogSleepSheet extends StatefulWidget {
  final String initialBedtime;
  final String initialWake;
  final void Function(String bedtime, String wakeTime, double hours) onSave;

  const _LogSleepSheet({
    required this.initialBedtime,
    required this.initialWake,
    required this.onSave,
  });

  @override
  State<_LogSleepSheet> createState() => _LogSleepSheetState();
}

class _LogSleepSheetState extends State<_LogSleepSheet> {
  late TimeOfDay _bedtime;
  late TimeOfDay _wakeTime;

  @override
  void initState() {
    super.initState();
    _bedtime  = _parseTime(widget.initialBedtime)  ?? const TimeOfDay(hour: 23, minute: 15);
    _wakeTime = _parseTime(widget.initialWake) ?? const TimeOfDay(hour: 6,  minute: 57);
  }

  TimeOfDay? _parseTime(String s) {
    try {
      final fmt = DateFormat('hh:mm a');
      final dt  = fmt.parse(s);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      return null;
    }
  }

  double _computeHours() {
    final bedMinutes  = _bedtime.hour * 60 + _bedtime.minute;
    var   wakeMinutes = _wakeTime.hour * 60 + _wakeTime.minute;
    if (wakeMinutes <= bedMinutes) { wakeMinutes += 24 * 60; }
    return (wakeMinutes - bedMinutes) / 60.0;
  }

  String _formatTime(TimeOfDay t) {
    final hour   = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(bool isBedtime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isBedtime ? _bedtime : _wakeTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isBedtime) {
          _bedtime = picked;
        } else {
          _wakeTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hours = _computeHours();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24, right: 24, top: 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text('Log Your Sleep', style: AppTextStyles.h3),
        const SizedBox(height: 24),

        // Bedtime picker
        _TimePicker(
          icon: Icons.bedtime_rounded,
          iconColor: const Color(0xFF9C27B0),
          label: 'Bedtime',
          time: _formatTime(_bedtime),
          onTap: () => _pickTime(true),
        ),
        const SizedBox(height: 12),

        // Wake time picker
        _TimePicker(
          icon: Icons.wb_sunny_rounded,
          iconColor: AppColors.primary,
          label: 'Wake Up Time',
          time: _formatTime(_wakeTime),
          onTap: () => _pickTime(false),
        ),
        const SizedBox(height: 16),

        // Duration preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded,
                  color: Color(0xFF9C27B0), size: 20),
              const SizedBox(width: 8),
              Text(
                'Duration: ${hours.toStringAsFixed(1)} hours',
                style: const TextStyle(
                    color: Color(0xFF9C27B0), fontWeight: FontWeight.w700,
                    fontSize: 14, fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        GFPrimaryButton(
          label: 'Save Sleep',
          icon: Icons.save_rounded,
          onTap: () => widget.onSave(
              _formatTime(_bedtime), _formatTime(_wakeTime), hours),
        ),
      ]),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   time;
  final VoidCallback onTap;

  const _TimePicker({
    required this.icon, required this.iconColor,
    required this.label, required this.time, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12,
                  fontFamily: 'Poppins')),
              Text(time, style: TextStyle(
                  color: iconColor, fontSize: 20,
                  fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
            ],
          )),
          const Icon(Icons.edit_rounded, color: AppColors.textMuted, size: 18),
        ]),
      ),
    );
  }
}
