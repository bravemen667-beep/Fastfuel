import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../services/notification_service.dart';
import '../services/claude_health_tips_service.dart';
import '../widgets/common_widgets.dart';

class HydrationScreen extends StatelessWidget {
  const HydrationScreen({super.key});

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
          _buildHeader(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WaterBottleCard(hp: hp).animate().fade(duration: 500.ms),
                const SizedBox(height: 20),
                _QuickAddRow(hp: hp).animate(delay: 100.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _HourlyChart().animate(delay: 150.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _SmartReminderCard(hp: hp).animate(delay: 200.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _HydrationTip().animate(delay: 250.ms).fade(duration: 500.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                    Text('Hydration', style: AppTextStyles.h3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.water_drop_rounded, color: Color(0xFF2196F3), size: 14),
                          const SizedBox(width: 4),
                          Text('Track', style: AppTextStyles.label.copyWith(color: const Color(0xFF2196F3))),
                        ],
                      ),
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

// ─── Water Bottle ────────────────────────────────────────
class _WaterBottleCard extends StatelessWidget {
  final HealthProvider hp;
  const _WaterBottleCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    final pct = hp.waterProgress;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.10),
            blurRadius: 25,
          ),
        ],
      ),
      child: Row(
        children: [
          // Bottle visualization
          Expanded(
            flex: 2,
            child: Column(
              children: [
                SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      // Bottle neck
                      Container(
                        width: 40, height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      // Bottle body
                      Container(
                        width: 90, height: 160,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              FractionallySizedBox(
                                heightFactor: pct,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${(pct * 100).toInt()}%',
                                      style: AppTextStyles.h2.copyWith(
                                        color: pct > 0.5 ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text('filled',
                                      style: AppTextStyles.caption.copyWith(
                                        color: pct > 0.5 ? Colors.white70 : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stats
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Goal', style: AppTextStyles.label),
                const SizedBox(height: 6),
                Text('${hp.waterConsumed.toInt()} ml',
                  style: AppTextStyles.h2.copyWith(color: const Color(0xFF42A5F5)),
                ),
                Text('of ${hp.waterGoal.toInt()} ml',
                  style: AppTextStyles.bodySm,
                ),
                const SizedBox(height: 20),
                _StatRow(
                  icon: Icons.flag_rounded,
                  label: 'Remaining',
                  value: hp.waterRemaining,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _StatRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Achieved',
                  value: '${(pct * 100).toInt()}%',
                  color: pct >= 1.0 ? AppColors.success : const Color(0xFF2196F3),
                ),
                const SizedBox(height: 12),
                _StatRow(
                  icon: Icons.emoji_events_rounded,
                  label: 'Streak',
                  value: '14 days',
                  color: AppColors.accent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatRow({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: AppTextStyles.bodySm)),
        Text(value, style: AppTextStyles.bodySm.copyWith(
          color: color, fontWeight: FontWeight.w700,
        )),
      ],
    );
  }
}

// ─── Quick Add Row (animated) ────────────────────────────
class _QuickAddRow extends StatelessWidget {
  final HealthProvider hp;
  const _QuickAddRow({required this.hp});

  @override
  Widget build(BuildContext context) {
    final amounts = [150.0, 250.0, 350.0, 500.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Add'),
        const SizedBox(height: 14),
        Row(
          children: amounts.map((ml) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: ml == amounts.last ? 0 : 8),
                child: _AnimatedWaterButton(ml: ml),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AnimatedWaterButton extends StatefulWidget {
  final double ml;
  const _AnimatedWaterButton({required this.ml});

  @override
  State<_AnimatedWaterButton> createState() => _AnimatedWaterButtonState();
}

class _AnimatedWaterButtonState extends State<_AnimatedWaterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _justTapped = false;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.90).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    _ctrl.forward().then((_) => _ctrl.reverse());
    setState(() => _justTapped = true);
    context.read<HealthProvider>().addWater(widget.ml);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _justTapped = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _justTapped
                ? const Color(0xFF2196F3).withValues(alpha: 0.20)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _justTapped
                  ? const Color(0xFF2196F3).withValues(alpha: 0.6)
                  : AppColors.border,
              width: _justTapped ? 1.5 : 1,
            ),
            boxShadow: _justTapped ? [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.25),
                blurRadius: 12, spreadRadius: -2,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _justTapped
                    ? const Icon(Icons.check_rounded, color: AppColors.success, size: 18, key: ValueKey('check'))
                    : const Icon(Icons.add_rounded, color: Color(0xFF2196F3), size: 18, key: ValueKey('add')),
              ),
              const SizedBox(height: 4),
              Text('${widget.ml.toInt()}', style: AppTextStyles.h5.copyWith(
                color: _justTapped ? AppColors.success : const Color(0xFF42A5F5),
              )),
              Text('ml', style: AppTextStyles.label.copyWith(
                color: _justTapped ? AppColors.success : AppColors.textMuted,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hourly Chart ─────────────────────────────────────────
class _HourlyChart extends StatelessWidget {
  static const _bars = [0.2, 0.4, 0.6, 0.3, 0.5, 0.8, 0.6, 0.4, 0.3, 0.5, 0.7, 0.4];
  static const _hours = ['6A', '8A', '10A', '12P', '2P', '4P', '6P', '8P', '10P', '12A', '2A', '4A'];

  @override
  Widget build(BuildContext context) {
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Hourly Intake'),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_bars.length, (i) {
                final isActive = i == 5;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == _bars.length - 1 ? 0 : 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: _bars[i],
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 300 + (i * 50)),
                              curve: Curves.easeOut,
                              decoration: BoxDecoration(
                                gradient: isActive
                                    ? AppGradients.fire
                                    : const LinearGradient(
                                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: isActive
                                    ? [BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(_hours[i], style: AppTextStyles.label.copyWith(fontSize: 8)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Smart Reminder Toggle ───────────────────────────────
class _SmartReminderCard extends StatelessWidget {
  final HealthProvider hp;
  const _SmartReminderCard({required this.hp});

  String _nextReminderTime() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 8, 0);
    while (next.isBefore(now) || next.hour > 22) {
      next = next.add(const Duration(minutes: 90));
      if (next.hour > 22) {
        next = DateTime(now.year, now.month, now.day + 1, 8, 0);
      }
    }
    final h    = next.hour > 12 ? next.hour - 12 : (next.hour == 0 ? 12 : next.hour);
    final m    = next.minute.toString().padLeft(2, '0');
    final ampm = next.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final nextTime = hp.waterReminders ? _nextReminderTime() : null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hp.waterReminders
              ? const Color(0xFF2196F3).withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF2196F3), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Smart Reminders', style: AppTextStyles.h5),
                    Text('Every 90 min · 8:00 AM – 10:00 PM',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              Switch(
                value: hp.waterReminders,
                onChanged: (v) async {
                  context.read<HealthProvider>().toggleWaterReminders(v);
                  await NotificationService.instance.setHydrationReminders(v);
                },
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return const Color(0xFF2196F3);
                  return AppColors.textMuted;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFF2196F3).withValues(alpha: 0.35);
                  }
                  return AppColors.border;
                }),
              ),
            ],
          ),
          if (hp.waterReminders && nextTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Color(0xFF2196F3), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Next reminder: $nextTime',
                    style: AppTextStyles.bodySm.copyWith(color: const Color(0xFF2196F3)),
                  ),
                  const Spacer(),
                  Text(
                    '💧 "Time to hydrate!"',
                    style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Hydration Tip ───────────────────────────────────────
class _HydrationTip extends StatefulWidget {
  @override
  State<_HydrationTip> createState() => _HydrationTipState();
}

class _HydrationTipState extends State<_HydrationTip> {
  String _tip = 'Drinking water 30 min before meals can reduce calorie intake by up to 13%.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTip());
  }

  double _parseSleepHours(String s) {
    try {
      final h = RegExp(r'(\d+\.?\d*)h').firstMatch(s);
      final m = RegExp(r'(\d+)m').firstMatch(s);
      final hours = double.tryParse(h?.group(1) ?? '0') ?? 0;
      final mins  = double.tryParse(m?.group(1) ?? '0') ?? 0;
      return hours + mins / 60;
    } catch (_) { return 7.0; }
  }

  Future<void> _loadTip() async {
    if (!mounted) return;
    final hp = context.read<HealthProvider>();
    try {
      final tip = await ClaudeHealthTipsService.instance.getHydrationNudge(
        currentMl: hp.waterConsumed,
        goalMl: hp.waterGoal > 0 ? hp.waterGoal : 2500,
        sleepHours: _parseSleepHours(hp.sleepDuration),
        score: hp.score.toInt(),
      );
      if (mounted) setState(() => _tip = tip);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message: _tip,
      icon: Icons.tips_and_updates_rounded,
      color: const Color(0xFF2196F3),
    );
  }
}
