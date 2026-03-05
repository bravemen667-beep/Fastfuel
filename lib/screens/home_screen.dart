import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import '../services/claude_health_tips_service.dart';
import 'workout_screen.dart';
import 'log_meal_screen.dart';
import 'stats_screen.dart';
import 'notifications_screen.dart';
import 'score_breakdown_screen.dart';
import 'scan_food_screen.dart';
import 'hydration_screen.dart';
import 'sleep_screen.dart';
import 'calorie_screen.dart';
import 'vitamin_screen.dart';
import 'inapp_browser_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRequestReview();
    });
  }

  Future<void> _maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstLaunch = prefs.getString('first_launch_date');
      final now = DateTime.now();
      if (firstLaunch == null) {
        await prefs.setString('first_launch_date', now.toIso8601String());
        return;
      }
      final first = DateTime.parse(firstLaunch);
      final diff = now.difference(first).inDays;
      if (diff >= 7) {
        final reviewDone = prefs.getBool('review_requested') ?? false;
        if (!reviewDone) {
          final inAppReview = InAppReview.instance;
          if (await inAppReview.isAvailable()) {
            await inAppReview.requestReview();
            await prefs.setBool('review_requested', true);
          }
        }
      }
    } catch (_) {
      // Silently ignore review errors
    }
  }

  Future<void> _onRefresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final hp   = context.read<HealthProvider>();
      final auth = context.read<GFAuthProvider>();
      final uid  = auth.uid.isEmpty ? auth.firestoreUid : auth.uid;
      await hp.initForUser(uid, auth.userName);
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp   = context.watch<HealthProvider>();
    final auth = context.watch<GFAuthProvider>();

    if (hp.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              SizedBox(height: 16),
              Text('Syncing with Firestore…',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (hp.error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(hp.error!, style: const TextStyle(color: AppColors.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    final uid = auth.uid.isEmpty ? auth.firestoreUid : auth.uid;
                    hp.initForUser(uid, auth.userName);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        displacement: 60,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
          _buildAppBar(context, hp),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. GoFaster Score (clickable)
                _ClickableScoreHero(hp: hp).animate().fade(duration: 500.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 20),
                // 2. Quick Actions (moved above vitals)
                _QuickActions(context).animate(delay: 100.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                // 3. Today's Vitals
                _VitalsGrid(hp: hp).animate(delay: 150.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                // 4. Tablet reminder banner
                _VitaminBanner(hp: hp).animate(delay: 180.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                // 5. Buy GoFaster Tablets / Shopify
                _ShopifyBanner().animate(delay: 200.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _GoogleFitBanner(hp: hp).animate(delay: 220.ms).fade(duration: 500.ms),
                const SizedBox(height: 20),
                _TodayTip().animate(delay: 250.ms).fade(duration: 500.ms),
              ]),
            ),
          ),
        ],
        ),   // CustomScrollView
      ),     // RefreshIndicator
    );
  }

  Widget _buildAppBar(BuildContext context, HealthProvider hp) {
    final auth = context.watch<GFAuthProvider>();
    final greeting = '${auth.greeting}! 💪';
    final displayName = hp.profileName.isNotEmpty
        ? hp.profileName
        : (auth.userName.isEmpty ? 'User' : auth.userName);
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: false,
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
                        ),
                        Text(displayName, style: AppTextStyles.h3),
                      ],
                    ),
                    Row(
                      children: [
                        _IconBtn(icon: Icons.notifications_rounded, onTap: () {
                          Navigator.push(context, fadeRoute(const NotificationsScreen()));
                        }),
                        const SizedBox(width: 8),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: AppGradients.fire,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                        ),
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

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

// ─── Shopify Banner ──────────────────────────────────────
class _ShopifyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => InAppBrowserScreen.open(context, url: 'https://gofaster.in', title: 'GoFaster Shop'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16, spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Shop GoFaster Vitamins & Supplements',
                style: AppTextStyles.h5.copyWith(color: Colors.white),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Shop', style: AppTextStyles.buttonSm.copyWith(color: Colors.white)),
                  const SizedBox(width: 4),
                  const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Clickable Score Hero ─────────────────────────────────
class _ClickableScoreHero extends StatelessWidget {
  final HealthProvider hp;
  const _ClickableScoreHero({required this.hp});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, fadeRoute(const ScoreBreakdownScreen())),
      child: _ScoreHero(hp: hp),
    );
  }
}

// ─── Score Hero ──────────────────────────────────────────
class _ScoreHero extends StatelessWidget {
  final HealthProvider hp;
  const _ScoreHero({required this.hp});

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
            blurRadius: 30, spreadRadius: -5,
          ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text('GoFaster Score',
                            style: AppTextStyles.label.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  hp.score.toInt().toString(),
                  style: AppTextStyles.scoreLg.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, color: AppColors.success, size: 12),
                          const SizedBox(width: 4),
                          Text('+${hp.scoreDelta.toInt()}% this week',
                            style: AppTextStyles.label.copyWith(color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Keep pushing! You\'re in top 15% today.',
                  style: AppTextStyles.bodySm.copyWith(height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.textMuted, size: 12),
                    const SizedBox(width: 4),
                    Text('Tap for full breakdown',
                      style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ScoreBadge(score: hp.score, delta: hp.scoreDelta, size: 130),
        ],
      ),
    );
  }
}

// ─── Vitals Grid ─────────────────────────────────────────
class _VitalsGrid extends StatelessWidget {
  final HealthProvider hp;
  const _VitalsGrid({required this.hp});

  void _navigateTo(BuildContext context, int tabIndex) {
    // Navigate to the bottom-nav tab via MainShell
    // We use Navigator.push for screens outside shell
    switch (tabIndex) {
      case 1:
        Navigator.push(context, fadeRoute(const HydrationScreen()));
        break;
      case 2:
        Navigator.push(context, fadeRoute(const VitaminScreen()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionHeader(title: 'Today\'s Vitals'),
            // Show live sync badge when health data is synced
            if (hp.syncLabel.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
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
                    const SizedBox(width: 4),
                    Text(
                      hp.syncLabel,
                      style: AppTextStyles.tag.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              )
            else if (hp.healthSyncing)
              const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  color: AppColors.success, strokeWidth: 2,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _TappableVitalCard(
              label: 'Water',
              value: '${hp.waterConsumed.toInt()}',
              unit: 'ml / ${hp.waterGoal.toInt()}',
              progress: hp.waterProgress,
              color: const Color(0xFF2196F3),
              icon: Icons.water_drop_rounded,
              onTap: () => _navigateTo(context, 1),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TappableVitalCard(
              label: 'Calories',
              value: '${hp.caloriesBurned.toInt()}',
              unit: 'kcal burned',
              progress: hp.caloriesProgress,
              color: AppColors.primary,
              icon: Icons.local_fire_department_rounded,
              onTap: () => Navigator.push(context, fadeRoute(const CalorieScreen())),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _TappableVitalCard(
              label: 'Sleep',
              value: hp.sleepDuration,
              unit: 'Score ${hp.sleepScore.toInt()}',
              progress: hp.sleepProgress,
              color: const Color(0xFF9C27B0),
              icon: Icons.bedtime_rounded,
              onTap: () => Navigator.push(context, fadeRoute(const SleepScreen())),
            )),
            const SizedBox(width: 12),
            Expanded(child: _TappableVitalCard(
              label: 'Vitamins',
              value: '${hp.vitaminsDone}/${hp.vitamins.length}',
              unit: 'taken today',
              progress: hp.vitaminsDone / hp.vitamins.length,
              color: AppColors.success,
              icon: Icons.medication_rounded,
              onTap: () => _navigateTo(context, 2),
            )),
          ],
        ),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;
  final IconData icon;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text('${(progress * 100).toInt()}%',
                style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(unit, style: AppTextStyles.label),
          const SizedBox(height: 10),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ─── Tappable Vital Card ─────────────────────────────────
class _TappableVitalCard extends StatefulWidget {
  final String label;
  final String value;
  final String unit;
  final double progress;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _TappableVitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.progress,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TappableVitalCard> createState() => _TappableVitalCardState();
}

class _TappableVitalCardState extends State<_TappableVitalCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: _VitalCard(
          label: widget.label,
          value: widget.value,
          unit: widget.unit,
          progress: widget.progress,
          color: widget.color,
          icon: widget.icon,
        ),
      ),
    );
  }
}

// ─── Vitamin Banner ──────────────────────────────────────
class _VitaminBanner extends StatelessWidget {
  final HealthProvider hp;
  const _VitaminBanner({required this.hp});

  @override
  Widget build(BuildContext context) {
    final pending = hp.vitamins.where((v) => !v.taken).toList();
    if (pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text('All vitamins taken! Great job today.',
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.fire,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Time for GoFaster Tablet',
                  style: AppTextStyles.h5,
                ),
                const SizedBox(height: 2),
                Text('${pending.length} vitamin(s) pending today',
                  style: AppTextStyles.bodySm,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.read<HealthProvider>().toggleVitamin(
              hp.vitamins.indexOf(pending.first),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppGradients.fire,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text('Mark Taken', style: AppTextStyles.buttonSm),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions ───────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final BuildContext ctx;
  const _QuickActions(this.ctx);

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(Icons.local_fire_department_rounded, 'Log\nMeal', AppColors.primary),
      _ActionItem(Icons.water_drop_rounded, 'Add\nWater', const Color(0xFF2196F3)),
      _ActionItem(Icons.camera_alt_rounded, 'Scan\nFood', const Color(0xFFFF6B00)),
      _ActionItem(Icons.fitness_center_rounded, 'Workout', const Color(0xFF9C27B0)),
      _ActionItem(Icons.bar_chart_rounded, 'Stats', AppColors.success),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 14),
        Row(
          children: actions.map((a) {
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  if (a.label.contains('Workout')) {
                    Navigator.push(context, fadeRoute(const WorkoutScreen()));
                  } else if (a.label.contains('Water')) {
                    context.read<HealthProvider>().addWater(250);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.cardBg,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        content: Row(
                          children: [
                            const Icon(Icons.water_drop_rounded, color: Color(0xFF2196F3)),
                            const SizedBox(width: 10),
                            Text('+250 ml logged!', style: AppTextStyles.body),
                          ],
                        ),
                      ),
                    );
                  } else if (a.label.contains('Meal')) {
                    Navigator.push(context, fadeRoute(const LogMealScreen()));
                  } else if (a.label.contains('Scan')) {
                    Navigator.push(context, fadeRoute(const ScanFoodScreen()));
                  } else if (a.label.contains('Stats')) {
                    Navigator.push(context, fadeRoute(const StatsScreen()));
                  }
                },
                child: Padding(
                  padding: EdgeInsets.only(right: actions.last == a ? 0 : 8),
                  child: Column(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: a.color.withValues(alpha: 0.3)),
                        ),
                        child: Icon(a.icon, color: a.color, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, fontSize: 9),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionItem(this.icon, this.label, this.color);
}

// ─── Today Tip (Claude AI-powered) ──────────────────────
class _TodayTip extends StatefulWidget {
  @override
  State<_TodayTip> createState() => _TodayTipState();
}

class _TodayTipState extends State<_TodayTip> {
  String? _tip;

  static const _fallbackTips = [
    'Drink 500ml water before your morning workout to boost performance by 15%.',
    'Sleep 7-9 hours to maximise muscle recovery and cognitive performance.',
    'Taking vitamins at the same time daily improves absorption by 30%.',
    'A 10-minute walk after meals reduces blood sugar spikes significantly.',
    'GoFaster Score above 80? You\'re performing in the top 20% of health-conscious users!',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTip());
  }

  // Parse "7h 42m" or "7.5h" → double hours
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
      final tip = await ClaudeHealthTipsService.instance.getHomeMessage(
        userName: hp.profileName.isNotEmpty ? hp.profileName : 'Champ',
        score: hp.score.toInt(),
        waterProgress: hp.waterProgress,
        sleepHours: _parseSleepHours(hp.sleepDuration),
        vitaminsLogged: hp.vitamins.where((v) => v.taken).length,
        caloriesBurned: hp.caloriesBurned.toInt(),
      );
      if (mounted) setState(() => _tip = tip);
    } catch (_) {
      final idx = DateTime.now().day % _fallbackTips.length;
      if (mounted) setState(() => _tip = _fallbackTips[idx]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTip = _tip ?? _fallbackTips[DateTime.now().day % _fallbackTips.length];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tips_and_updates_rounded, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySm.copyWith(height: 1.5),
                children: [
                  TextSpan(
                    text: 'GoFaster AI: ',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: displayTip),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google Fit Banner ───────────────────────────────────
class _GoogleFitBanner extends StatelessWidget {
  final HealthProvider hp;
  const _GoogleFitBanner({required this.hp});

  @override
  Widget build(BuildContext context) {
    // Already connected and fetching
    if (hp.fitnessFetching) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                color: AppColors.primary, strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text('Syncing Google Fit data…', style: AppTextStyles.bodySm),
          ],
        ),
      );
    }

    // Connected — show live step count badge
    if (hp.fitnessConnected) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/icons/google_fit.png',
                width: 24, height: 24,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.success, size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Google Fit Connected',
                        style: AppTextStyles.h5.copyWith(color: AppColors.success),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hp.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} steps · ${hp.activeMinutes} active mins today',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: hp.refreshFitnessData,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.refresh_rounded,
                  color: AppColors.textMuted, size: 18,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (hp.fitnessError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(hp.fitnessError!,
                style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
              ),
            ),
            GestureDetector(
              onTap: () => context.read<HealthProvider>().connectGoogleFitness(),
              child: Text('Retry',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    // Not connected — CTA banner
    return GestureDetector(
      onTap: () => context.read<HealthProvider>().connectGoogleFitness(),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A2E1A),
              AppColors.success.withValues(alpha: 0.15),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.monitor_heart_rounded,
                color: AppColors.success, size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Connect Google Fit',
                    style: AppTextStyles.h5.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text('Sync real steps, calories & heart rate',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text('Connect',
                style: AppTextStyles.buttonSm.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
