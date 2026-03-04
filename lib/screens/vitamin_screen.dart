import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../services/claude_health_tips_service.dart';
import '../widgets/common_widgets.dart';

class VitaminScreen extends StatelessWidget {
  const VitaminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HealthProvider>();
    if (hp.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _header(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StreakHero(hp: hp).animate().fade(duration: 500.ms),
                const SizedBox(height: 20),
                _DoseSchedule(hp: hp).animate(delay: 100.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _VitaminList(hp: hp).animate(delay: 150.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _InventoryCard(hp: hp).animate(delay: 200.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _VitaminTip().animate(delay: 250.ms).fade(duration: 500.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _header() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      expandedHeight: 56,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
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
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 4),
                        Text('GoFaster', style: AppTextStyles.h5.copyWith(color: AppColors.primary)),
                      ],
                    ),
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

// ─── Streak Hero ─────────────────────────────────────────
class _StreakHero extends StatelessWidget {
  final HealthProvider hp;
  const _StreakHero({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.fire,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 30, spreadRadius: -5, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 28),
                Text('${hp.streakDays}',
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAY STREAK', style: AppTextStyles.tag.copyWith(
                  color: Colors.white.withValues(alpha: 0.8), letterSpacing: 1.5,
                )),
                const SizedBox(height: 6),
                Text('${hp.streakDays} Days\nConsistent!',
                  style: AppTextStyles.h3.copyWith(color: Colors.white, height: 1.3),
                ),
                const SizedBox(height: 8),
                Text('Keep going, you\'re unstoppable! 🔥',
                  style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${hp.vitaminsDone}/${hp.vitamins.length}',
                style: AppTextStyles.h1.copyWith(color: Colors.white),
              ),
              Text('taken', style: AppTextStyles.bodySm.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Dose Schedule ───────────────────────────────────────
class _DoseSchedule extends StatelessWidget {
  final HealthProvider hp;
  const _DoseSchedule({required this.hp});

  @override
  Widget build(BuildContext context) {
    final slots = [
      _Slot('Morning', '8:00 AM', Icons.wb_sunny_rounded, AppColors.accent, hp.vitamins.sublist(0, 2)),
      _Slot('Afternoon', '1:00 PM', Icons.lunch_dining_rounded, AppColors.primary, []),
      _Slot('Evening', '8:00 PM', Icons.nightlight_round, const Color(0xFF9C27B0), hp.vitamins.sublist(2)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Schedule'),
        const SizedBox(height: 14),
        ...slots.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(s.icon, color: s.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(s.slot, style: AppTextStyles.h5),
                          const SizedBox(width: 6),
                          Text(s.time, style: AppTextStyles.label.copyWith(color: s.color)),
                        ],
                      ),
                      if (s.vitamins.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          s.vitamins.map((v) => v.name).join(', '),
                          style: AppTextStyles.bodySm,
                        ),
                      ],
                    ],
                  ),
                ),
                if (s.vitamins.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: s.vitamins.every((v) => v.taken)
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          s.vitamins.every((v) => v.taken)
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: s.vitamins.every((v) => v.taken) ? AppColors.success : AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.vitamins.every((v) => v.taken) ? 'Done' : 'Take',
                          style: AppTextStyles.label.copyWith(
                            color: s.vitamins.every((v) => v.taken) ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ],
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

class _Slot {
  final String slot;
  final String time;
  final IconData icon;
  final Color color;
  final List vitamins;
  const _Slot(this.slot, this.time, this.icon, this.color, this.vitamins);
}

// ─── Vitamin List ────────────────────────────────────────
class _VitaminList extends StatelessWidget {
  final HealthProvider hp;
  const _VitaminList({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Today\'s Protocol'),
        const SizedBox(height: 14),
        ...hp.vitamins.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: () => context.read<HealthProvider>().toggleVitamin(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: v.taken
                      ? v.color.withValues(alpha: 0.08)
                      : AppColors.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: v.taken ? v.color.withValues(alpha: 0.4) : AppColors.border,
                    width: v.taken ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: v.color.withValues(alpha: v.taken ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(v.icon, color: v.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: AppTextStyles.h5),
                          Text('${v.dose} · ${v.benefit}',
                            style: AppTextStyles.bodySm,
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: v.taken
                            ? v.color.withValues(alpha: 0.25)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: v.taken ? v.color : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        v.taken ? Icons.check_rounded : Icons.add_rounded,
                        color: v.taken ? v.color : AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Inventory Card ──────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final HealthProvider hp;
  const _InventoryCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    final low = hp.tabletsLeft <= 15;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: low ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: low ? AppGradients.fire : null,
              color: low ? null : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              color: low ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inventory', style: AppTextStyles.h5),
                Text('${hp.tabletsLeft} tablets remaining',
                  style: AppTextStyles.bodySm.copyWith(
                    color: low ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GFOutlineButton(
            label: 'Reorder',
            icon: Icons.shopping_bag_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Tip ─────────────────────────────────────────────────
class _VitaminTip extends StatefulWidget {
  @override
  State<_VitaminTip> createState() => _VitaminTipState();
}

class _VitaminTipState extends State<_VitaminTip> {
  String _tip = 'Take GoFaster tablet with warm water in the morning for 40% better absorption.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTip());
  }

  Future<void> _loadTip() async {
    if (!mounted) return;
    final hp = context.read<HealthProvider>();
    final taken = hp.vitamins.where((v) => v.taken).length;
    final total = hp.vitamins.length;
    try {
      final tip = await ClaudeHealthTipsService.instance.getVitaminCoachMessage(
        streak: hp.vitaminStreak,
        vitaminsTaken: taken,
        vitaminTotal: total > 0 ? total : 4,
      );
      if (mounted) setState(() => _tip = tip);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message: _tip,
      icon: Icons.tips_and_updates_rounded,
      color: AppColors.primary,
    );
  }
}
