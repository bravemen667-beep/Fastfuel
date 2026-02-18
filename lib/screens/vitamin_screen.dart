import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../providers/health_provider.dart';

class VitaminScreen extends StatelessWidget {
  const VitaminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthProvider>();
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          GlowBlob(color: AppColors.primary, size: 350, alignment: const Alignment(-0.7, -0.5), opacity: 0.08),
          GlowBlob(color: AppColors.neonGreenAlt, size: 250, alignment: const Alignment(0.8, 0.7), opacity: 0.05),

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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12)],
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text('Daily Fuel', style: AppTextStyles.headingMd),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
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
                        _StreakHero(streakDays: health.streakDays)
                          .animate().fadeIn(delay: 100.ms, duration: 600.ms),
                        const SizedBox(height: 20),
                        _DoseSchedule()
                          .animate().fadeIn(delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _VitaminProtocolCard(health: health)
                          .animate().fadeIn(delay: 300.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _BenefitCards()
                          .animate().fadeIn(delay: 400.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        _InventoryCard(tabletsLeft: health.tabletsLeft)
                          .animate().fadeIn(delay: 500.ms, duration: 500.ms),
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
//  Streak Hero
// ─────────────────────────────────────────────────────
class _StreakHero extends StatelessWidget {
  final int streakDays;
  const _StreakHero({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Column(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 6),
              Text('$streakDays-day streak',
                style: AppTextStyles.headingXL.copyWith(fontSize: 28)),
              const SizedBox(height: 4),
              Text("You're performing at peak efficiency. Keep Going!",
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 6,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.85,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
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

// ─────────────────────────────────────────────────────
//  Dose Schedule
// ─────────────────────────────────────────────────────
class _DoseSchedule extends StatelessWidget {
  const _DoseSchedule();

  @override
  Widget build(BuildContext context) {
    final slots = [
      _Slot('Morning', Icons.check_circle_rounded, AppColors.neonGreenAlt, true, false),
      _Slot('Afternoon', Icons.schedule_rounded, AppColors.primary, false, true),
      _Slot('Evening', Icons.nights_stay_rounded, AppColors.textMuted, false, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SCHEDULE',
          style: AppTextStyles.label.copyWith(color: AppColors.primary.withValues(alpha: 0.7), letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Row(
          children: slots.map((s) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: s.isActive
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: s.isActive
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : s.isDone
                            ? AppColors.neonGreenAlt.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(s.icon, color: s.color, size: 22),
                    const SizedBox(height: 6),
                    Text(s.label,
                      style: AppTextStyles.label.copyWith(
                        color: s.isActive ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 10,
                      )),
                  ],
                ),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }
}

class _Slot {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDone;
  final bool isActive;
  const _Slot(this.label, this.icon, this.color, this.isDone, this.isActive);
}

// ─────────────────────────────────────────────────────
//  Vitamin Protocol Card
// ─────────────────────────────────────────────────────
class _VitaminProtocolCard extends StatelessWidget {
  final HealthProvider health;
  const _VitaminProtocolCard({required this.health});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Protocol', style: AppTextStyles.headingSm),
                Text('GOFASTER™ STACK',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary, letterSpacing: 1.2)),
              ],
            ),
          ),
          ...health.vitamins.asMap().entries.map((e) {
            final i = e.key;
            final v = e.value;
            return GestureDetector(
              onTap: () => context.read<HealthProvider>().toggleVitamin(i),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: i < health.vitamins.length - 1
                      ? Border(bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.05)))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: v.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(v.icon, color: v.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(v.name, style: AppTextStyles.bodyMedium.copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${v.benefit} • ${v.dose}',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: v.taken
                            ? AppColors.neonGreenAlt.withValues(alpha: 0.12)
                            : AppColors.textMuted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: v.taken
                              ? AppColors.neonGreenAlt.withValues(alpha: 0.3)
                              : AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        v.taken ? 'TAKEN' : 'SKIP',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: v.taken ? AppColors.neonGreenAlt : AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Benefit Info Cards
// ─────────────────────────────────────────────────────
class _BenefitCards extends StatelessWidget {
  const _BenefitCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _BenefitCard(
          icon: Icons.psychology_rounded,
          title: 'B12 Benefits',
          body: 'Boosts energy levels and improves cognitive focus for high-intensity work.',
        )),
        const SizedBox(width: 12),
        Expanded(child: _BenefitCard(
          icon: Icons.shield_rounded,
          title: 'Vit C Benefits',
          body: 'Protects cellular health and keeps your immune system operational.',
        )),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _BenefitCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon, size: 56, color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: 13,
                )),
              const SizedBox(height: 6),
              Text(body,
                style: AppTextStyles.body.copyWith(fontSize: 11, height: 1.5)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Inventory Alert Card
// ─────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final int tabletsLeft;
  const _InventoryCard({required this.tabletsLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)]),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('$tabletsLeft tablets left',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      )),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Low stock: Lasts approx. 6 days',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.white70,
                    fontSize: 12,
                  )),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.neonGreenAlt,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(color: AppColors.neonGreenAlt.withValues(alpha: 0.4), blurRadius: 16),
              ],
            ),
            child: const Row(
              children: [
                Text('Reorder',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
