// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Workout Screen
//  ExerciseDB API for exercise data + Claude AI for personalised suggestions.
//  Shows workout cards: name, sets, reps, muscle group, difficulty, Start button.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/nav_aware_scaffold.dart';
import '../services/exercise_service.dart';
import '../services/claude_workout_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedCategory = 0;
  final List<String> _categories = ['HIIT', 'Strength', 'Cardio', 'Yoga', 'Recovery', 'MMA'];

  WorkoutPlan? _aiPlan;
  List<ExerciseItem> _exercises = [];
  bool _loadingAI  = false;
  bool _loadingExercises = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([_generateAIPlan(), _loadExercises()]);
  }

  Future<void> _generateAIPlan() async {
    setState(() { _loadingAI = true; _aiError = null; });
    final hp = context.read<HealthProvider>();
    try {
      final plan = await ClaudeWorkoutService.instance.generatePlan(
        goFasterScore:  hp.score,
        sleepDuration:  hp.sleepDuration,
        sleepScore:     hp.sleepScore,
        fitnessGoal:    hp.fitnessGoal,
        fitnessLevel:   hp.fitnessLevel,
        workoutType:    _categories[_selectedCategory],
        activeMinutes:  hp.activeMinutes,
      );
      if (mounted) setState(() { _aiPlan = plan; _loadingAI = false; });
    } catch (e) {
      if (mounted) setState(() { _loadingAI = false; _aiError = 'AI suggestion unavailable'; });
    }
  }

  Future<void> _loadExercises() async {
    setState(() => _loadingExercises = true);
    final bodyPart = _bodyPartForCategory(_categories[_selectedCategory]);
    final items = await ExerciseService.instance.fetchByBodyPart(bodyPart);
    if (mounted) setState(() { _exercises = items; _loadingExercises = false; });
  }

  String _bodyPartForCategory(String cat) {
    switch (cat) {
      case 'Strength':  return 'chest';
      case 'Cardio':    return 'cardio';
      case 'Yoga':
      case 'Recovery':  return 'back';
      case 'MMA':       return 'waist';
      default:          return 'cardio'; // HIIT
    }
  }

  void _onCategoryChange(int i) {
    setState(() => _selectedCategory = i);
    _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HealthProvider>();
    return NavAwareScaffold(
      activeTab: 0,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardBg,
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            _buildHeader(context),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _RecoveryAlert(hp: hp).animate().fade(duration: 500.ms),
                  const SizedBox(height: 20),

                  // ── Claude AI Plan ─────────────────────────────────────
                  if (_loadingAI)
                    _AiLoadingCard().animate().fade(duration: 400.ms)
                  else if (_aiPlan != null)
                    _AiPlanCard(plan: _aiPlan!).animate(delay: 100.ms).fade(duration: 500.ms)
                  else if (_aiError != null)
                    _buildAiError(),

                  const SizedBox(height: 20),

                  // ── Category chips ─────────────────────────────────────
                  _CategoryChips(
                    categories: _categories,
                    selected: _selectedCategory,
                    onSelect: _onCategoryChange,
                  ).animate(delay: 150.ms).fade(duration: 500.ms),

                  const SizedBox(height: 20),

                  // ── Exercise cards from ExerciseDB ─────────────────────
                  _ExerciseList(
                    exercises: _exercises,
                    loading: _loadingExercises,
                  ).animate(delay: 200.ms).fade(duration: 500.ms),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(_aiError!, style: AppTextStyles.bodySm)),
        GestureDetector(
          onTap: _generateAIPlan,
          child: Text('Retry', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
        ),
      ]),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: Navigator.canPop(context)
          ? GestureDetector(
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
            )
          : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(60, 0, 20, 0),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AI Workouts', style: AppTextStyles.h3),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text('Claude AI', style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Recovery Alert ────────────────────────────────────────────────────────────
class _RecoveryAlert extends StatelessWidget {
  final HealthProvider hp;
  const _RecoveryAlert({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.fire, borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recovery Alert', style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                Text('Sleep: ${hp.sleepDuration} · Score ${hp.sleepScore.toInt()}. Adjust intensity accordingly.',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Loading Card ────────────────────────────────────────────────────────────
class _AiLoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        const SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Claude AI is crafting your plan…',
                style: AppTextStyles.h5.copyWith(color: AppColors.accent),
              ),
              Text('Analysing sleep, score & preferences',
                style: AppTextStyles.bodySm,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── AI Plan Card ──────────────────────────────────────────────────────────────
class _AiPlanCard extends StatefulWidget {
  final WorkoutPlan plan;
  const _AiPlanCard({required this.plan});

  @override
  State<_AiPlanCard> createState() => _AiPlanCardState();
}

class _AiPlanCardState extends State<_AiPlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final intensityColor = _intensityColor(p.intensity);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.10),
            blurRadius: 20, spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text('Claude AI Plan', style: AppTextStyles.label.copyWith(color: AppColors.accent)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: intensityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(p.intensity,
                        style: AppTextStyles.label.copyWith(color: intensityColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(p.title, style: AppTextStyles.h4),
                const SizedBox(height: 4),
                Text(p.description, style: AppTextStyles.bodySm),
                const SizedBox(height: 12),
                // Stats row
                Row(children: [
                  _PlanStat(Icons.timer_rounded, '${p.durationMinutes} min'),
                  const SizedBox(width: 16),
                  _PlanStat(Icons.local_fire_department_rounded,
                    '~${p.estimatedCalories} kcal', color: AppColors.primary),
                  const SizedBox(width: 16),
                  _PlanStat(Icons.fitness_center_rounded,
                    '${p.sets.length} exercises'),
                ]),
                const SizedBox(height: 12),
                // AI Insight
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.insights_rounded, color: AppColors.accent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.aiInsight, style: AppTextStyles.bodySm.copyWith(height: 1.4))),
                  ]),
                ),
              ],
            ),
          ),

          // Exercises list (collapsible)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('View ${p.sets.length} Exercises',
                    style: AppTextStyles.h5.copyWith(color: AppColors.primary),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary, size: 22),
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _WarmupCooldown(icon: Icons.wb_sunny_outlined, label: 'Warm-Up', text: p.warmup),
                  const SizedBox(height: 8),
                  ...p.sets.asMap().entries.map((e) => _ExerciseSetRow(set: e.value, index: e.key + 1)),
                  const SizedBox(height: 8),
                  _WarmupCooldown(icon: Icons.ac_unit_rounded, label: 'Cool-Down', text: p.cooldown),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        content: Text('Workout started! Stay hydrated and go faster! 💪',
                          style: AppTextStyles.bodySm.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text('Start Workout', style: AppTextStyles.button),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _intensityColor(String i) {
    switch (i) {
      case 'Low':       return AppColors.success;
      case 'Moderate':  return AppColors.accent;
      case 'High':      return AppColors.primary;
      case 'Very High': return AppColors.error;
      default:          return AppColors.accent;
    }
  }
}

class _PlanStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _PlanStat(this.icon, this.label, {this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(label, style: AppTextStyles.bodySm.copyWith(color: color)),
    ]);
  }
}

class _WarmupCooldown extends StatelessWidget {
  final IconData icon;
  final String label;
  final String text;
  const _WarmupCooldown({required this.icon, required this.label, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, color: AppColors.textMuted, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySm,
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _ExerciseSetRow extends StatelessWidget {
  final WorkoutSet set;
  final int index;
  const _ExerciseSetRow({required this.set, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('$index', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(set.exercise, style: AppTextStyles.h5),
              Text(set.muscleGroup, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${set.sets} × ${set.reps}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600,
              ),
            ),
            Text('Rest: ${set.rest}', style: AppTextStyles.label),
          ],
        ),
      ]),
    );
  }
}

// ── Category Chips ────────────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final int selected;
  final ValueChanged<int> onSelect;
  const _CategoryChips({required this.categories, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final active = i == selected;
          return Padding(
            padding: EdgeInsets.only(right: i == categories.length - 1 ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: active ? AppGradients.fire : null,
                  color: active ? null : AppColors.surface,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: active ? Colors.transparent : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    categories[i],
                    style: AppTextStyles.buttonSm.copyWith(
                      color: active ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Exercise List from ExerciseDB ─────────────────────────────────────────────
class _ExerciseList extends StatelessWidget {
  final List<ExerciseItem> exercises;
  final bool loading;
  const _ExerciseList({required this.exercises, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Exercise Library'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.border),
              ),
              child: Text('ExerciseDB',
                style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (loading)
          const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
        else if (exercises.isEmpty)
          Text('No exercises found.', style: AppTextStyles.bodySm)
        else
          ...exercises.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExerciseCard(exercise: e),
          )),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseItem exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Placeholder for GIF
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: exercise.gifUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(exercise.gifUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                        const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 28),
                    ),
                  )
                : const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: AppTextStyles.h5),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _Tag(exercise.target, AppColors.primary),
                    _Tag(exercise.bodyPart, AppColors.textMuted),
                    _Tag(exercise.equipment, AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.cardBg,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  content: Text('Added ${exercise.name} to today\'s workout! 💪',
                    style: AppTextStyles.bodySm,
                  ),
                ),
              );
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.fire,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(text, style: AppTextStyles.label.copyWith(color: color, fontSize: 9)),
    );
  }
}
