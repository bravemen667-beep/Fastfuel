import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/health_provider.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: Stack(
        children: [
          GlowBlob(color: AppColors.primary, size: 320, alignment: const Alignment(-0.5, -0.7), opacity: 0.1),
          GlowBlob(color: AppColors.neonBlue, size: 250, alignment: const Alignment(0.8, 0.3), opacity: 0.06),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Header ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 24),
                      ),
                      const Expanded(
                        child: Center(child: Text('Your GoFaster Workout',
                          style: AppTextStyles.headingSm)),
                      ),
                      Stack(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                          ),
                          Positioned(
                            right: 9,
                            top: 9,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1C1C1E), width: 1.5),
                              ),
                            ),
                          ),
                        ],
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
                        const SizedBox(height: 16),

                        // ── Recovery Alert ───────────────
                        _RecoveryAlert()
                          .animate().fadeIn(delay: 100.ms, duration: 500.ms),
                        const SizedBox(height: 20),

                        // ── AI Insight ───────────────────
                        _AIInsightCard(health: health)
                          .animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 20),

                        // ── Category Chips ───────────────
                        _CategoryChips(
                          categories: health.workoutCategories,
                          selectedIndex: _selectedCategory,
                          onSelected: (i) => setState(() => _selectedCategory = i),
                        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                        const SizedBox(height: 20),

                        // ── Workout Cards ────────────────
                        _WorkoutCardsList(cards: health.workoutCards)
                          .animate().fadeIn(delay: 400.ms, duration: 500.ms),

                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Start Workout Floating CTA ────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF1C1C1E),
                    const Color(0xFF1C1C1E).withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: GradientButton(
                label: 'Start Workout',
                icon: Icons.play_circle_fill_rounded,
                gradient: AppGradients.actionGradient,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Recovery Alert Banner
// ─────────────────────────────────────────────────────
class _RecoveryAlert extends StatelessWidget {
  const _RecoveryAlert();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_rounded, color: Color(0xFFF59E0B), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recovery Alert',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Color(0xFFF59E0B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
                SizedBox(height: 4),
                Text(
                  'Your HRV is lower than usual. Consider a guided yoga session today to prevent overtraining.',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
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
//  AI Recommendation Card
// ─────────────────────────────────────────────────────
class _AIInsightCard extends StatelessWidget {
  final HealthProvider health;
  const _AIInsightCard({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('AI RECOMMENDATION',
                    style: AppTextStyles.label.copyWith(color: AppColors.primary, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.55,
                  ),
                  children: [
                    const TextSpan(text: 'Based on your '),
                    TextSpan(
                      text: '${health.score.toInt()} GoFaster Score',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: health.sleepDuration + ' sleep',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ', we recommend a HIIT session today to peak your performance.'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('AI',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 9,
                            )),
                        ),
                      ),
                    ],
                  ),
                  Text('Updated 5m ago',
                    style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Category Chips
// ─────────────────────────────────────────────────────
class _CategoryChips extends StatelessWidget {
  final List<WorkoutCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.1),
                ),
                boxShadow: selected
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 12)]
                    : null,
              ),
              child: Text(categories[i].name,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: selected ? Colors.white : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Workout Cards List
// ─────────────────────────────────────────────────────
class _WorkoutCardsList extends StatelessWidget {
  final List<WorkoutCard> cards;
  const _WorkoutCardsList({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECOMMENDED FOR YOU',
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted, letterSpacing: 1.5)),
        const SizedBox(height: 14),
        ...cards.asMap().entries.map((e) {
          final card = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _WorkoutCardTile(card: card),
          );
        }),
      ],
    );
  }
}

class _WorkoutCardTile extends StatelessWidget {
  final WorkoutCard card;
  const _WorkoutCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: card.isLarge ? 220 : 130,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: card.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),

          // Decorative glow
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Tag(card.level, Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(width: 8),
                      _Tag(card.tag, AppColors.primary.withValues(alpha: 0.4), textColor: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(card.title,
                    style: card.isLarge
                        ? AppTextStyles.headingXL.copyWith(fontSize: 28)
                        : AppTextStyles.headingLg),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text('${card.duration} min',
                        style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.local_fire_department_rounded, color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text('${card.calories} kcal',
                        style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (!card.isLarge)
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color bg;
  final Color? textColor;
  const _Tag(this.label, this.bg, {this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          color: textColor ?? Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.5,
        )),
    );
  }
}
