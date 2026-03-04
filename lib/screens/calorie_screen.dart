// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Daily Fuel / Calorie Screen
//
//  On first open:
//    1. Checks if Health Connect / HealthKit permission is already granted.
//    2. If not → shows PermissionGateScreen overlay.
//    3. If granted (or after grant) → auto-syncs real calorie / step data.
//    4. Shows "Synced X min ago" badge when real data is live.
//    5. If denied → falls back to Firestore / manual data silently.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../services/health_sync_service.dart';
import '../widgets/common_widgets.dart';
import 'permission_gate_screen.dart';

class CalorieScreen extends StatefulWidget {
  const CalorieScreen({super.key});

  @override
  State<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends State<CalorieScreen> {
  static const _prefKey = 'calorie_health_asked';
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermission());
  }

  Future<void> _checkPermission() async {
    if (!mounted) return;
    final hp = context.read<HealthProvider>();

    // ── 1. Already granted? Sync immediately ──────────────────────────────
    final status = await hp.checkHealthPermission();
    if (status == HealthPermissionStatus.granted) {
      await hp.refreshHealthData();
      if (mounted) setState(() => _gateChecked = true);
      return;
    }

    // ── 2. Web / unsupported → skip gate ────────────────────────────────
    if (kIsWeb || status == HealthPermissionStatus.notAvailable) {
      if (mounted) setState(() => _gateChecked = true);
      return;
    }

    // ── 3. First time? Show permission gate ──────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_prefKey) ?? false;
    if (!alreadyAsked && mounted) {
      await prefs.setBool(_prefKey, true);
      if (!mounted) return;
      final granted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PermissionGateScreen(context: 'calories'),
        ),
      );
      if ((granted ?? false) && mounted) {
        await hp.refreshHealthData();
      }
    }

    if (mounted) setState(() => _gateChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HealthProvider>();

    if (hp.isLoading || !_gateChecked) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary, strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardBg,
        onRefresh: () async {
          final status = await hp.checkHealthPermission();
          if (status == HealthPermissionStatus.granted) {
            await hp.refreshHealthData();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _header(hp),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Sync status banner ──────────────────────────────────
                  _SyncBanner(hp: hp).animate().fade(duration: 400.ms),
                  if (hp.syncLabel.isNotEmpty) const SizedBox(height: 12),

                  _CalorieSummary(hp: hp).animate().fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _MacrosCard(hp: hp)
                      .animate(delay: 100.ms).fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _StepsCard(hp: hp)
                      .animate(delay: 150.ms).fade(duration: 500.ms),
                  // Show heart rate card when synced
                  if (hp.heartRateBpm > 0) ...[
                    const SizedBox(height: 20),
                    _HeartRateCard(hp: hp)
                        .animate(delay: 175.ms).fade(duration: 500.ms),
                  ],
                  const SizedBox(height: 20),
                  _MealLog().animate(delay: 200.ms).fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _CalorieTip().animate(delay: 250.ms).fade(duration: 500.ms),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _header(HealthProvider hp) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Daily Fuel', style: AppTextStyles.h3),
                    hp.syncLabel.isNotEmpty
                        ? _SyncChip(label: hp.syncLabel)
                        : GFTag(label: 'Today', color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sync Status Banner ────────────────────────────────────────────────────────
class _SyncBanner extends StatelessWidget {
  final HealthProvider hp;
  const _SyncBanner({required this.hp});

  @override
  Widget build(BuildContext context) {
    if (hp.healthSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Syncing activity data from '
              '${hp.healthSource.isEmpty ? "Health" : hp.healthSource}…',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (hp.healthSyncError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Health sync unavailable — showing saved data',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    if (hp.syncLabel.isNotEmpty && hp.healthSource.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${hp.syncLabel} from ${hp.healthSource} · Pull to refresh',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.success),
              ),
            ),
            const Icon(Icons.refresh_rounded, color: AppColors.success, size: 16),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ── Sync chip (header) ────────────────────────────────────────────────────────
class _SyncChip extends StatelessWidget {
  final String label;
  const _SyncChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(label,
            style: AppTextStyles.tag.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

// ─── Calorie Summary ──────────────────────────────────────────────────────────
class _CalorieSummary extends StatelessWidget {
  final HealthProvider hp;
  const _CalorieSummary({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 25,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Burned', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    '${hp.caloriesBurned.toInt()}',
                    style: AppTextStyles.scoreLg.copyWith(color: AppColors.primary),
                  ),
                  Text('kcal', style: AppTextStyles.bodySm),
                ],
              ),
              GlowRing(
                progress: hp.caloriesProgress,
                size: 120,
                strokeWidth: 10,
                gradientColors: const [AppColors.primary, AppColors.accent],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.primary, size: 20,
                    ),
                    Text(
                      '${(hp.caloriesProgress * 100).toInt()}%',
                      style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                    ),
                    Text('goal', style: AppTextStyles.label),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Consumed', style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(
                    '${hp.caloriesConsumed.toInt()}',
                    style: AppTextStyles.scoreLg.copyWith(
                      color: const Color(0xFF42A5F5),
                    ),
                  ),
                  Text('kcal', style: AppTextStyles.bodySm),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _CalStat(
                label: 'Goal',
                value: '${hp.caloriesGoal.toInt()} kcal',
                color: AppColors.textSecondary,
              )),
              Expanded(child: _CalStat(
                label: 'Remaining',
                value: '${hp.caloriesRemaining.toInt()} kcal',
                color: hp.caloriesRemaining >= 0
                    ? AppColors.success
                    : AppColors.error,
              )),
              Expanded(child: _CalStat(
                label: 'Active Min',
                value: '${hp.activeMinutes} min',
                color: AppColors.accent,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h5.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

// ─── Macros Card ──────────────────────────────────────────────────────────────
class _MacrosCard extends StatelessWidget {
  final HealthProvider hp;
  const _MacrosCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    final total = hp.proteinG + hp.carbsG + hp.fatsG;
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Macros Breakdown'),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _MacroBar(
                      label: 'Protein',
                      grams: hp.proteinG,
                      total: total,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _MacroBar(
                      label: 'Carbs',
                      grams: hp.carbsG,
                      total: total,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 10),
                    _MacroBar(
                      label: 'Fats',
                      grams: hp.fatsG,
                      total: total,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 80, height: 80,
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [hp.proteinG, hp.carbsG, hp.fatsG],
                    colors: [AppColors.primary, AppColors.accent, AppColors.success],
                  ),
                  child: Center(
                    child: Text(
                      '${total.toInt()}g',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _MacroBar extends StatelessWidget {
  final String label;
  final double grams;
  final double total;
  final Color color;

  const _MacroBar({
    required this.label, required this.grams,
    required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? grams / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4), blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${grams.toInt()}g',
          style: AppTextStyles.caption.copyWith(
            color: color, fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.reduce((a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 12.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * math.pi * 2 * 0.9;
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(
          center: center, radius: radius - strokeWidth / 2,
        ),
        start, sweep, false, paint,
      );
      start += sweep + 0.1;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.values != values;
}

// ─── Steps Card ───────────────────────────────────────────────────────────────
class _StepsCard extends StatelessWidget {
  final HealthProvider hp;
  const _StepsCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    final pct = hp.steps / 10000;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: AppGradients.fire,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.directions_walk_rounded,
              color: Colors.white, size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Steps Today', style: AppTextStyles.h5),
                    Text('Goal: 10,000', style: AppTextStyles.bodySm),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      hp.steps.toString().replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (m) => '${m[1]},',
                      ),
                      style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(pct * 100).toInt()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: pct.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.fire,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
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

// ─── Heart Rate Card (visible only when synced) ───────────────────────────────
class _HeartRateCard extends StatelessWidget {
  final HealthProvider hp;
  const _HeartRateCard({required this.hp});

  String get _zone {
    final bpm = hp.heartRateBpm;
    if (bpm < 60) return 'Resting';
    if (bpm < 100) return 'Normal';
    if (bpm < 140) return 'Fat Burn';
    if (bpm < 170) return 'Cardio';
    return 'Peak';
  }

  Color get _zoneColor {
    final bpm = hp.heartRateBpm;
    if (bpm < 60) return AppColors.textSecondary;
    if (bpm < 100) return AppColors.success;
    if (bpm < 140) return AppColors.accent;
    if (bpm < 170) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite_rounded,
              color: AppColors.error, size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Avg Heart Rate', style: AppTextStyles.h5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _zoneColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        _zone,
                        style: AppTextStyles.tag.copyWith(color: _zoneColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${hp.heartRateBpm.toInt()}',
                      style: AppTextStyles.h2.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'bpm',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'From ${hp.healthSource}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
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

// ─── Meal Log ─────────────────────────────────────────────────────────────────
class _MealLog extends StatelessWidget {
  static const _meals = [
    _Meal('Breakfast', '7:30 AM', Icons.free_breakfast_rounded, 420, AppColors.accent),
    _Meal('Lunch', '1:00 PM', Icons.lunch_dining_rounded, 580, AppColors.primary),
    _Meal('Snack', '4:30 PM', Icons.apple_rounded, 200, AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Meal Log',
          action: 'Add Meal',
          onAction: () {},
        ),
        const SizedBox(height: 14),
        ..._meals.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: m.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(m.icon, color: m.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: AppTextStyles.h5),
                      Text(m.time, style: AppTextStyles.bodySm),
                    ],
                  ),
                ),
                Text(
                  '${m.cal} kcal',
                  style: AppTextStyles.body.copyWith(
                    color: m.color, fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _Meal {
  final String  name;
  final String  time;
  final IconData icon;
  final int     cal;
  final Color   color;
  const _Meal(this.name, this.time, this.icon, this.cal, this.color);
}

// ─── Tip ──────────────────────────────────────────────────────────────────────
class _CalorieTip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message:
          'Protein-rich meals boost metabolism and keep you fuller for 3x longer than carbs alone.',
      icon: Icons.local_fire_department_rounded,
      color: AppColors.primary,
    );
  }
}
