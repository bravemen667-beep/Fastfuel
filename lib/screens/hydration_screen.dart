// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Hydration Screen (Smart Daily Limit)
//  MyFitnessPal / WaterMinder quality
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../widgets/common_widgets.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class WaterEntry {
  final int ml;
  final DateTime time;
  WaterEntry(this.ml, this.time);

  String get timeLabel => DateFormat('hh:mm a').format(time);
  Map<String, dynamic> toJson() =>
      {'ml': ml, 'time': time.toIso8601String()};
  factory WaterEntry.fromJson(Map<String, dynamic> j) =>
      WaterEntry(j['ml'] as int, DateTime.parse(j['time'] as String));
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen>
    with WidgetsBindingObserver {

  static const _goalKey   = 'daily_water_goal_ml';
  static const _quickAmts = [150, 250, 350, 500];

  int            _goalMl  = 2500;
  List<WaterEntry> _entries = [];
  bool           _loading = true;
  DateTime       _today   = _dateOnly(DateTime.now());

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _checkMidnightReset();
  }

  // ── date helpers ──────────────────────────────────────────────────────────
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  String get _dateKey =>
      'water_${_today.year}-${_today.month.toString().padLeft(2,'0')}-${_today.day.toString().padLeft(2,'0')}';

  void _checkMidnightReset() {
    final now = _dateOnly(DateTime.now());
    if (now.isAfter(_today)) {
      setState(() {
        _today   = now;
        _entries = [];
      });
    }
  }

  // ── persistence ────────────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _goalMl = prefs.getInt(_goalKey) ?? 2500;
    final raw = prefs.getStringList(_dateKey) ?? [];
    setState(() {
      _entries = raw.map((s) {
        try {
          final parts = s.split(':');
          return WaterEntry(int.parse(parts[0]),
              DateTime.parse(parts.sublist(1).join(':')));
        } catch (_) {
          return WaterEntry(250, DateTime.now());
        }
      }).toList();
      _loading = false;
    });
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _dateKey,
        _entries.map((e) => '${e.ml}:${e.time.toIso8601String()}').toList());
  }

  // ── computed ───────────────────────────────────────────────────────────────
  int get _totalMl  => _entries.fold(0, (s, e) => s + e.ml);
  int get _maxMl    => (_goalMl * 1.5).toInt();
  double get _progress => (_totalMl / _goalMl).clamp(0.0, 1.5);
  Color get _arcColor {
    if (_totalMl > _goalMl) return AppColors.error;
    if (_progress > 0.75)   return const Color(0xFF2196F3);
    return const Color(0xFF64B5F6);
  }

  // ── add water ──────────────────────────────────────────────────────────────
  void _addWater(int ml) {
    if (_totalMl >= _maxMl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(children: [
            const Icon(Icons.warning_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(child: Text(
              "You've reached your maximum safe intake for today",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            )),
          ]),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    // clamp to max
    final effective = math.min(ml, _maxMl - _totalMl);
    setState(() => _entries.add(WaterEntry(effective, DateTime.now())));
    _save();
    _syncProvider();

    // Green confirmation snack
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(children: [
          const Icon(Icons.water_drop_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Text('+$effective ml logged!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  void _syncProvider() {
    context.read<HealthProvider>().setWaterDirectly(_totalMl);
  }

  void _resetToday() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Today?', style: TextStyle(color: Colors.white)),
        content: const Text('This will clear all water entries for today.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _entries = []);
      await _save();
      _syncProvider();
    }
  }

  // ── custom amount dialog ────────────────────────────────────────────────────
  void _showCustomDialog() {
    int custom = 200;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Custom Amount',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          StatefulBuilder(builder: (ctx, ss) => Column(children: [
            Text('$custom ml', style: TextStyle(
                color: AppColors.primary, fontSize: 32,
                fontWeight: FontWeight.w800)),
            Slider(
              min: 50, max: 1000, divisions: 38,
              value: custom.toDouble(),
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (v) => ss(() => custom = v.toInt()),
            ),
          ])),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () { Navigator.pop(context); _addWater(custom); },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── goal dialog ─────────────────────────────────────────────────────────────
  void _showGoalDialog() {
    int newGoal = _goalMl;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Daily Goal',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: StatefulBuilder(builder: (ctx, ss) => Column(
          mainAxisSize: MainAxisSize.min, children: [
          Text('$newGoal ml', style: TextStyle(
              color: AppColors.primary, fontSize: 32,
              fontWeight: FontWeight.w800)),
          Slider(
            min: 1000, max: 5000, divisions: 40,
            value: newGoal.toDouble(),
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (v) => ss(() => newGoal = v.toInt()),
          ),
          Text('Recommended: 2000–3000 ml/day',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              setState(() => _goalMl = newGoal);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(_goalKey, newGoal);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const SizedBox(height: 8),
              _WaterRingCard(
                totalMl: _totalMl,
                goalMl:  _goalMl,
                progress: _progress,
                arcColor: _arcColor,
              ).animate().fade(duration: 400.ms).slideY(begin: 0.15, end: 0),
              const SizedBox(height: 20),
              _QuickAddRow(
                amounts: _quickAmts,
                onAdd: _addWater,
                onCustom: _showCustomDialog,
              ).animate(delay: 80.ms).fade(duration: 400.ms),
              const SizedBox(height: 20),
              _InfoRow(goalMl: _goalMl, totalMl: _totalMl)
                  .animate(delay: 120.ms).fade(duration: 400.ms),
              const SizedBox(height: 20),
              _HistorySection(
                entries: _entries,
                onReset: _entries.isEmpty ? null : _resetToday,
              ).animate(delay: 160.ms).fade(duration: 400.ms),
              const SizedBox(height: 20),
              _HydrationTip().animate(delay: 200.ms).fade(duration: 400.ms),
            ])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGoalDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.tune_rounded, color: Colors.white),
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
          child: Row(
            children: [
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
                    Text('Hydration', style: AppTextStyles.h3),
                    Text('Daily Water Tracker',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showGoalDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.4)),
                  ),
                  child: Text('GOAL: ${_goalMl}ml',
                      style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          fontFamily: 'Poppins')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Water Ring Card ──────────────────────────────────────────────────────────
class _WaterRingCard extends StatelessWidget {
  final int    totalMl;
  final int    goalMl;
  final double progress;
  final Color  arcColor;

  const _WaterRingCard({
    required this.totalMl,
    required this.goalMl,
    required this.progress,
    required this.arcColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 150).toInt();
    return GFCard(
      child: Column(children: [
        const SectionHeader(title: 'Today\'s Intake'),
        const SizedBox(height: 20),
        SizedBox(
          width: 220, height: 220,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(220, 220),
              painter: _ArcPainter(progress: progress.clamp(0, 1.5), color: arcColor),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.water_drop_rounded, color: arcColor, size: 32),
              const SizedBox(height: 4),
              Text('$totalMl',
                  style: TextStyle(
                      color: arcColor, fontSize: 40,
                      fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
              const Text('ml today',
                  style: TextStyle(color: AppColors.textSecondary,
                      fontSize: 13, fontFamily: 'Poppins')),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: arcColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$pct%',
                    style: TextStyle(color: arcColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12, fontFamily: 'Poppins')),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$totalMl ml / $goalMl ml  ',
              style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 4),
        Text('Recommended: 8 glasses (2000ml)',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted)),
      ]),
    );
  }
}

// ─── Arc Painter ─────────────────────────────────────────────────────────────
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 14;
    const start = -math.pi / 2;
    const full  = 2 * math.pi;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start, full, false,
      Paint()
        ..color = AppColors.border
        ..strokeWidth = 16
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      // Over-goal shows red on top
      final baseProgress = progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, full * baseProgress, false,
        Paint()
          ..color = color
          ..strokeWidth = 16
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      if (progress > 1.0) {
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          start, full * (progress - 1.0), false,
          Paint()
            ..color = AppColors.error
            ..strokeWidth = 16
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Quick Add Row ────────────────────────────────────────────────────────────
class _QuickAddRow extends StatelessWidget {
  final List<int> amounts;
  final void Function(int) onAdd;
  final VoidCallback onCustom;

  const _QuickAddRow({
    required this.amounts,
    required this.onAdd,
    required this.onCustom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text('Quick Add',
            style: AppTextStyles.h4.copyWith(fontSize: 16)),
      ),
      Row(children: [
        ...amounts.map((ml) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onAdd(ml),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  const Icon(Icons.water_drop_rounded,
                      color: Color(0xFF2196F3), size: 22),
                  const SizedBox(height: 4),
                  Text('+$ml',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700,
                          fontSize: 13, fontFamily: 'Poppins')),
                  const Text('ml',
                      style: TextStyle(color: AppColors.textMuted,
                          fontSize: 10, fontFamily: 'Poppins')),
                ]),
              ),
            ),
          ),
        )),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onCustom,
          child: Container(
            width: 52, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                Text('Custom', style: TextStyle(
                    color: AppColors.primary, fontSize: 9,
                    fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
      ]),
    ]);
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final int goalMl;
  final int totalMl;
  const _InfoRow({required this.goalMl, required this.totalMl});

  @override
  Widget build(BuildContext context) {
    final remaining = (goalMl - totalMl).clamp(0, goalMl);
    final glasses   = (totalMl / 250).toStringAsFixed(1);
    return Row(children: [
      _buildStat('Remaining', '${remaining}ml', AppColors.textSecondary),
      const SizedBox(width: 12),
      _buildStat('Glasses', '$glasses of 8', const Color(0xFF2196F3)),
      const SizedBox(width: 12),
      _buildStat('Max Safe', '${((goalMl) * 1.5).toInt()}ml', AppColors.textMuted),
    ]);
  }

  Widget _buildStat(String label, String val, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.caption
            .copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(
            color: c, fontWeight: FontWeight.w700,
            fontSize: 14, fontFamily: 'Poppins')),
      ]),
    ),
  );
}

// ─── History Section ──────────────────────────────────────────────────────────
class _HistorySection extends StatelessWidget {
  final List<WaterEntry> entries;
  final VoidCallback?    onReset;
  const _HistorySection({required this.entries, this.onReset});

  @override
  Widget build(BuildContext context) {
    return GFCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: const SectionHeader(title: 'Today\'s History')),
          if (onReset != null)
            GestureDetector(
              onTap: onReset,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Reset Today',
                    style: TextStyle(
                        color: AppColors.error, fontSize: 11,
                        fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('No entries yet. Start drinking! 💧',
                  style: TextStyle(color: AppColors.textSecondary,
                      fontFamily: 'Poppins')),
            ),
          )
        else
          ...entries.reversed.take(10).map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: Color(0xFF2196F3), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(e.timeLabel,
                    style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.textSecondary)),
              ),
              Text('+${e.ml} ml',
                  style: const TextStyle(
                      color: Color(0xFF2196F3), fontWeight: FontWeight.w700,
                      fontSize: 14, fontFamily: 'Poppins')),
            ]),
          )),
      ]),
    );
  }
}

// ─── Hydration Tip ────────────────────────────────────────────────────────────
class _HydrationTip extends StatelessWidget {
  const _HydrationTip();

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.tips_and_updates_rounded,
      message: 'Drinking water 30 min before meals can reduce calorie '
          'intake by up to 13%. Aim for ${(8 * 250)}ml across the day.',
      color: const Color(0xFF2196F3),
    );
  }
}
