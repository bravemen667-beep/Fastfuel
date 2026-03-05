// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Fuel (Calorie) Screen  · Complete Rebuild
//  Reference: MyFitnessPal, Cronometer, Lose It!
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
import 'scan_food_screen.dart';

// ─── Meal Entry model ─────────────────────────────────────────────────────────
class MealEntry {
  final String   name;
  final int      calories;
  final double   protein;
  final double   carbs;
  final double   fat;
  final DateTime time;
  final MealType type;

  const MealEntry({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.time,
    required this.type,
  });
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class CalorieScreen extends StatefulWidget {
  const CalorieScreen({super.key});

  @override
  State<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends State<CalorieScreen> {
  // ── goals (persisted) ──────────────────────────────────────────────────────
  int    _goalCalories = 2200;
  int    _goalProtein  = 120;
  int    _goalCarbs    = 380;
  int    _goalFat      = 85;

  // ── today's mock data ──────────────────────────────────────────────────────
  // In production these would come from Firestore [NEEDS_FIREBASE]
  late List<MealEntry> _todayMeals;
  bool _goalsExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _todayMeals = _mockMeals();
  }

  List<MealEntry> _mockMeals() {
    final today = DateTime.now();
    return [
      MealEntry(name: 'Oatmeal + Milk', calories: 310, protein: 12,
          carbs: 56, fat: 6,
          time: today.copyWith(hour: 7, minute: 30), type: MealType.breakfast),
      MealEntry(name: 'Paneer Rice Bowl', calories: 520, protein: 28,
          carbs: 62, fat: 14,
          time: today.copyWith(hour: 13, minute: 0), type: MealType.lunch),
      MealEntry(name: 'Protein Bar', calories: 200, protein: 20,
          carbs: 20, fat: 5,
          time: today.copyWith(hour: 16, minute: 30), type: MealType.snack),
    ];
  }

  // ── computed ───────────────────────────────────────────────────────────────
  int get _totalCalories  => _todayMeals.fold(0, (s, m) => s + m.calories);
  double get _totalProtein => _todayMeals.fold(0.0, (s, m) => s + m.protein);
  double get _totalCarbs   => _todayMeals.fold(0.0, (s, m) => s + m.carbs);
  double get _totalFat     => _todayMeals.fold(0.0, (s, m) => s + m.fat);

  int get _burned     => context.read<HealthProvider>().caloriesBurned.toInt();
  int get _remaining  => (_goalCalories - _totalCalories + _burned).clamp(0, _goalCalories);
  double get _pct     => (_totalCalories / _goalCalories).clamp(0.0, 1.5);

  // ── goals persistence ──────────────────────────────────────────────────────
  Future<void> _loadGoals() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _goalCalories = p.getInt('fuel_goal_calories') ?? 2200;
      _goalProtein  = p.getInt('fuel_goal_protein')  ?? 120;
      _goalCarbs    = p.getInt('fuel_goal_carbs')    ?? 380;
      _goalFat      = p.getInt('fuel_goal_fat')      ?? 85;
    });
  }

  Future<void> _saveGoals() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('fuel_goal_calories', _goalCalories);
    await p.setInt('fuel_goal_protein',  _goalProtein);
    await p.setInt('fuel_goal_carbs',    _goalCarbs);
    await p.setInt('fuel_goal_fat',      _goalFat);
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Text('Goals saved! 🎯',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
    }
  }

  // ── navigation ─────────────────────────────────────────────────────────────
  Future<void> _openScanner(MealType type) async {
    final added = await Navigator.push<bool>(
      context,
      fadeRoute(ScanFoodScreen(mealType: type)),
    );
    if (added == true && mounted) setState(() {});
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
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
              _CalorieRingCard(
                totalCalories: _totalCalories,
                goalCalories:  _goalCalories,
                burned:        _burned,
                remaining:     _remaining,
                pct:           _pct,
              ).animate().fade(duration: 450.ms).slideY(begin: 0.2, end: 0),
              const SizedBox(height: 16),
              _MacrosCard(
                protein: _totalProtein,
                carbs:   _totalCarbs,
                fat:     _totalFat,
                goalProtein: _goalProtein.toDouble(),
                goalCarbs:   _goalCarbs.toDouble(),
                goalFat:     _goalFat.toDouble(),
              ).animate(delay: 80.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _StepsCard(hp: context.watch<HealthProvider>())
                  .animate(delay: 120.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _MealLogSection(
                meals:   _todayMeals,
                onTapBreakfast: () => _openScanner(MealType.breakfast),
                onTapLunch:     () => _openScanner(MealType.lunch),
                onTapDinner:    () => _openScanner(MealType.dinner),
                onTapSnack:     () => _openScanner(MealType.snack),
              ).animate(delay: 160.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _AiTipCard()
                  .animate(delay: 200.ms).fade(duration: 450.ms),
              const SizedBox(height: 16),
              _GoalsSetter(
                calories: _goalCalories,
                protein:  _goalProtein,
                carbs:    _goalCarbs,
                fat:      _goalFat,
                expanded: _goalsExpanded,
                onToggle: () => setState(() => _goalsExpanded = !_goalsExpanded),
                onCaloriesChanged: (v) => setState(() => _goalCalories = v),
                onProteinChanged:  (v) => setState(() => _goalProtein  = v),
                onCarbsChanged:    (v) => setState(() => _goalCarbs    = v),
                onFatChanged:      (v) => setState(() => _goalFat      = v),
                onSave: _saveGoals,
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
                    Text('Daily Fuel', style: AppTextStyles.h3),
                    Text('Calorie & Macro Tracker',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: const Text('TODAY',
                    style: TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700,
                        fontSize: 11, fontFamily: 'Poppins')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Calorie Ring Card ────────────────────────────────────────────────────────
class _CalorieRingCard extends StatelessWidget {
  final int    totalCalories;
  final int    goalCalories;
  final int    burned;
  final int    remaining;
  final double pct;

  const _CalorieRingCard({
    required this.totalCalories, required this.goalCalories,
    required this.burned, required this.remaining, required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final pctInt = (pct * 100).clamp(0, 150).toInt();
    final ringColor = pct > 1.0 ? AppColors.error : AppColors.primary;

    return GFCard(
      child: Column(children: [
        Row(children: [
          Expanded(child: const SectionHeader(title: 'Calorie Summary')),
          Text(DateFormat('MMM d').format(DateTime.now()),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: 20),

        // Ring + side stats
        Row(children: [
          // Left stat — Burned
          Expanded(child: _RingStat(
            label: 'Burned',
            value: '$burned',
            unit: 'kcal',
            color: AppColors.primary,
            icon: Icons.local_fire_department_rounded,
          )),

          // Center donut ring
          SizedBox(
            width: 140, height: 140,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                size: const Size(140, 140),
                painter: _DonutPainter(progress: pct.clamp(0.0, 1.5), color: ringColor),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('$pctInt%',
                    style: TextStyle(color: ringColor, fontSize: 28,
                        fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                Text('goal', style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12,
                    fontFamily: 'Poppins')),
              ]),
            ]),
          ),

          // Right stat — Consumed
          Expanded(child: _RingStat(
            label: 'Consumed',
            value: '$totalCalories',
            unit: 'kcal',
            color: const Color(0xFF00BCD4),
            icon: Icons.restaurant_rounded,
          )),
        ]),
        const SizedBox(height: 20),

        // Bottom 3-stat row
        Row(children: [
          _buildBottomStat('$goalCalories kcal', 'Goal', AppColors.textSecondary),
          _buildBottomStat('$remaining kcal', 'Remaining',
              remaining > 0 ? const Color(0xFF66BB6A) : AppColors.error),
          _buildBottomStat(
            '${context.read<HealthProvider>().activeMinutes.toInt()} min',
            'Active',
            AppColors.primary,
          ),
        ]),
      ]),
    );
  }

  Widget _buildBottomStat(String val, String label, Color c) => Expanded(
    child: Column(children: [
      Text(val, style: TextStyle(color: c, fontWeight: FontWeight.w700,
          fontSize: 14, fontFamily: 'Poppins')),
      Text(label, style: const TextStyle(color: AppColors.textMuted,
          fontSize: 11, fontFamily: 'Poppins')),
    ]),
  );
}

class _RingStat extends StatelessWidget {
  final String  label;
  final String  value;
  final String  unit;
  final Color   color;
  final IconData icon;
  const _RingStat({required this.label, required this.value,
    required this.unit, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontSize: 22,
          fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
      Text(unit, style: const TextStyle(
          color: AppColors.textSecondary, fontSize: 11, fontFamily: 'Poppins')),
      Text(label, style: const TextStyle(
          color: AppColors.textMuted, fontSize: 10, fontFamily: 'Poppins')),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  final double progress;
  final Color  color;
  const _DonutPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    const start = -math.pi / 2;
    final paint = Paint()
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
        start, 2 * math.pi, false,
        paint..color = AppColors.border);

    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r),
          start, 2 * math.pi * progress.clamp(0, 1), false,
          paint..color = color);
      if (progress > 1) {
        canvas.drawArc(Rect.fromCircle(center: c, radius: r),
            start, 2 * math.pi * (progress - 1), false,
            paint..color = AppColors.error);
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) =>
      o.progress != progress || o.color != color;
}

// ─── Macros Card ──────────────────────────────────────────────────────────────
class _MacrosCard extends StatelessWidget {
  final double protein, carbs, fat;
  final double goalProtein, goalCarbs, goalFat;

  const _MacrosCard({
    required this.protein, required this.carbs, required this.fat,
    required this.goalProtein, required this.goalCarbs, required this.goalFat,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;
    final proteinPct = total > 0 ? protein / total : 0.33;
    final carbsPct   = total > 0 ? carbs   / total : 0.34;
    final fatPct     = total > 0 ? fat     / total : 0.33;

    return GFCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Macros Breakdown'),
        const SizedBox(height: 16),
        Row(children: [
          // Bars
          Expanded(
            flex: 3,
            child: Column(children: [
              _buildMacroRow('Protein', protein, goalProtein,
                  AppColors.primary),
              const SizedBox(height: 12),
              _buildMacroRow('Carbs', carbs, goalCarbs,
                  const Color(0xFFFFB347)),
              const SizedBox(height: 12),
              _buildMacroRow('Fats', fat, goalFat,
                  const Color(0xFF66BB6A)),
            ]),
          ),
          const SizedBox(width: 20),
          // Mini donut
          SizedBox(
            width: 90, height: 90,
            child: Stack(alignment: Alignment.center, children: [
              PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 28,
                sections: [
                  PieChartSectionData(value: proteinPct * 100,
                      color: AppColors.primary, radius: 16, showTitle: false),
                  PieChartSectionData(value: carbsPct * 100,
                      color: const Color(0xFFFFB347), radius: 16, showTitle: false),
                  PieChartSectionData(value: fatPct * 100,
                      color: const Color(0xFF66BB6A), radius: 16, showTitle: false),
                ],
              )),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${total.toInt()}g',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w800, fontSize: 14,
                        fontFamily: 'Poppins')),
                const Text('total', style: TextStyle(
                    color: AppColors.textMuted, fontSize: 9,
                    fontFamily: 'Poppins')),
              ]),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMacroRow(String label, double val, double goal, Color c) {
    final pct = (val / goal).clamp(0.0, 1.0);
    return Row(children: [
      SizedBox(width: 60,
          child: Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 12,
              fontFamily: 'Poppins'))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: AppColors.border,
          valueColor: AlwaysStoppedAnimation<Color>(c),
          minHeight: 10,
        ),
      )),
      const SizedBox(width: 8),
      SizedBox(width: 52, child: Text(
        '${val.toInt()}g',
        textAlign: TextAlign.right,
        style: TextStyle(color: c, fontSize: 12,
            fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
      )),
    ]);
  }
}

// ─── Steps Card ───────────────────────────────────────────────────────────────
class _StepsCard extends StatelessWidget {
  final HealthProvider hp;
  const _StepsCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    final steps    = hp.steps;
    final goal     = 10000;
    final stepsPct = (steps / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.directions_walk_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Steps Today',
                  style: AppTextStyles.bodySm
                      .copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Goal: ${NumberFormat('#,###').format(goal)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textMuted)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Text(NumberFormat('#,###').format(steps),
                  style: const TextStyle(color: AppColors.primary,
                      fontSize: 22, fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins')),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${(stepsPct * 100).toInt()}%',
                    style: const TextStyle(color: Color(0xFF66BB6A),
                        fontWeight: FontWeight.w700, fontSize: 12,
                        fontFamily: 'Poppins')),
              ),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stepsPct,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
        )),
      ]),
    );
  }
}

// ─── Meal Log Section ─────────────────────────────────────────────────────────
class _MealLogSection extends StatelessWidget {
  final List<MealEntry> meals;
  final VoidCallback onTapBreakfast;
  final VoidCallback onTapLunch;
  final VoidCallback onTapDinner;
  final VoidCallback onTapSnack;

  const _MealLogSection({
    required this.meals,
    required this.onTapBreakfast,
    required this.onTapLunch,
    required this.onTapDinner,
    required this.onTapSnack,
  });

  int _kcalFor(MealType t) => meals
      .where((m) => m.type == t)
      .fold(0, (s, m) => s + m.calories);

  String _nameFor(MealType t) {
    final ms = meals.where((m) => m.type == t).toList();
    if (ms.isEmpty) { return 'Tap to add'; }
    if (ms.length == 1) { return ms.first.name; }
    return '${ms.length} items';
  }

  String _timeFor(MealType t) {
    final ms = meals.where((m) => m.type == t).toList();
    if (ms.isEmpty) { return ''; }
    return DateFormat('hh:mm a').format(ms.first.time);
  }

  @override
  Widget build(BuildContext context) {
    final mealDefs = [
      (MealType.breakfast, 'Breakfast', Icons.wb_sunny_rounded,
        const Color(0xFFFFF176), onTapBreakfast),
      (MealType.lunch, 'Lunch', Icons.lunch_dining_rounded,
        const Color(0xFF80DEEA), onTapLunch),
      (MealType.snack, 'Snack', Icons.cookie_rounded,
        const Color(0xFFCE93D8), onTapSnack),
      (MealType.dinner, 'Dinner', Icons.dinner_dining_rounded,
        const Color(0xFFFFCC80), onTapDinner),
    ];

    return GFCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: SectionHeader(title: 'Meal Log')),
          GFPrimaryButton(
            label: 'Add Meal',
            icon: Icons.add_rounded,
            onTap: () => _showAddMealSheet(context),
            height: 36,
            fullWidth: false,
          ),
        ]),
        const SizedBox(height: 12),
        ...mealDefs.map((m) {
          final kcal   = _kcalFor(m.$1);
          final name   = _nameFor(m.$1);
          final time   = _timeFor(m.$1);
          final hasFood = kcal > 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () { HapticFeedback.lightImpact(); m.$5(); },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: m.$4.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(m.$3, color: m.$4, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(m.$2, style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700,
                            fontSize: 14, fontFamily: 'Poppins')),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Text(time, style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                        ],
                      ]),
                      const SizedBox(height: 2),
                      Text(name, style: AppTextStyles.caption
                          .copyWith(
                          color: hasFood
                              ? AppColors.textSecondary
                              : AppColors.primary)),
                    ],
                  )),
                  Text(hasFood ? '$kcal kcal' : '',
                      style: TextStyle(
                          color: hasFood ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 14, fontFamily: 'Poppins')),
                  const SizedBox(width: 8),
                  const Icon(Icons.add_circle_rounded,
                      color: AppColors.primary, size: 20),
                ]),
              ),
            ),
          );
        }),
      ]),
    );
  }

  void _showAddMealSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Add Meal', style: AppTextStyles.h3),
            const SizedBox(height: 24),
            GFPrimaryButton(
              label: 'Open Food Scanner',
              icon: Icons.camera_alt_rounded,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(ctx,
                    fadeRoute(const ScanFoodScreen()));
              },
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── AI Tip ───────────────────────────────────────────────────────────────────
class _AiTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.tips_and_updates_rounded,
      message: 'Protein-rich meals boost metabolism and keep you fuller for '
          '3× longer than carbs alone. Try to hit your protein goal first.',
      color: AppColors.primary,
    );
  }
}

// ─── Goals Setter ─────────────────────────────────────────────────────────────
class _GoalsSetter extends StatelessWidget {
  final int    calories, protein, carbs, fat;
  final bool   expanded;
  final VoidCallback onToggle;
  final ValueChanged<int> onCaloriesChanged;
  final ValueChanged<int> onProteinChanged;
  final ValueChanged<int> onCarbsChanged;
  final ValueChanged<int> onFatChanged;
  final VoidCallback onSave;

  const _GoalsSetter({
    required this.calories, required this.protein,
    required this.carbs,    required this.fat,
    required this.expanded, required this.onToggle,
    required this.onCaloriesChanged, required this.onProteinChanged,
    required this.onCarbsChanged,    required this.onFatChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return GFCard(
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          child: Row(children: [
            const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('Set My Goals',
                style: AppTextStyles.h4.copyWith(fontSize: 16))),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AppColors.textSecondary,
            ),
          ]),
        ),
        if (expanded) ...[
          const SizedBox(height: 16),
          _buildGoalSlider('Calories', calories, 1200, 4000, onCaloriesChanged,
              AppColors.primary, 'kcal'),
          _buildGoalSlider('Protein',  protein,  50,   300,  onProteinChanged,
              const Color(0xFFEF5350), 'g'),
          _buildGoalSlider('Carbs',    carbs,    100,  500,  onCarbsChanged,
              const Color(0xFFFFB347), 'g'),
          _buildGoalSlider('Fat',      fat,      30,   200,  onFatChanged,
              const Color(0xFF66BB6A), 'g'),
          const SizedBox(height: 12),
          GFPrimaryButton(label: 'Save Goals', icon: Icons.save_rounded,
              onTap: onSave),
        ],
      ]),
    );
  }

  Widget _buildGoalSlider(String label, int val, int min, int max,
      ValueChanged<int> onChange, Color color, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary,
              fontSize: 13, fontFamily: 'Poppins')),
          const Spacer(),
          Text('$val $unit', style: TextStyle(color: color,
              fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
        ]),
        Slider(
          value: val.clamp(min, max).toDouble(),
          min: min.toDouble(), max: max.toDouble(),
          divisions: (max - min) ~/ 10,
          activeColor: color,
          inactiveColor: AppColors.border,
          onChanged: (v) => onChange(v.toInt()),
        ),
      ]),
    );
  }
}
