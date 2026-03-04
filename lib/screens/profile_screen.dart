import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_widgets.dart';
import 'notification_settings_screen.dart';
import 'fitness_preferences_screen.dart';
import 'share_progress_screen.dart';
import 'help_support_screen.dart';
import 'inapp_browser_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hp   = context.watch<HealthProvider>();
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: hp.isLoading
          ? const _LoadingBody()
          : hp.error != null
              ? _ErrorBody(error: hp.error!, onRetry: () {
                  final uid  = auth.uid.isEmpty ? 'guest_user' : auth.uid;
                  hp.initForUser(uid, auth.userName);
                })
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildAppBar(context, hp),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _ProfileHero(hp: hp, auth: auth).animate().fade(duration: 500.ms),
                          const SizedBox(height: 20),
                          _StatsRow(hp: hp).animate(delay: 100.ms).fade(duration: 500.ms),
                          const SizedBox(height: 20),
                          _GoalsSection(hp: hp).animate(delay: 150.ms).fade(duration: 500.ms),
                          const SizedBox(height: 20),
                          _SettingsSection().animate(delay: 200.ms).fade(duration: 500.ms),
                          const SizedBox(height: 20),
                          _LogoutButton().animate(delay: 225.ms).fade(duration: 500.ms),
                          const SizedBox(height: 20),
                          _GoFasterBrand().animate(delay: 250.ms).fade(duration: 500.ms),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, HealthProvider hp) {
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
                    Text('Profile', style: AppTextStyles.h3),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showEditGoalsSheet(context, hp),
                        borderRadius: BorderRadius.circular(50),
                        splashColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_rounded, color: AppColors.primary, size: 14),
                              const SizedBox(width: 6),
                              Text('Edit Goals', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
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

  // ── Edit Goals Bottom Sheet ──────────────────────────────
  void _showEditGoalsSheet(BuildContext context, HealthProvider hp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditGoalsSheet(hp: hp),
    );
  }
}

// ── Loading Body ─────────────────────────────────────────
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2,
      ),
    );
  }
}

// ── Error Body ───────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(error, style: AppTextStyles.bodySm, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
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
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final HealthProvider hp;
  final AuthProvider auth;
  const _ProfileHero({required this.hp, required this.auth});

  @override
  Widget build(BuildContext context) {
    // Show Firestore name if available, fall back to auth name
    final displayName = hp.profileName.isNotEmpty
        ? hp.profileName
        : (auth.isGuest ? 'Guest User' : (auth.userName.isEmpty ? 'Alex Kumar' : auth.userName));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  gradient: AppGradients.fire,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 48),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    gradient: AppGradients.fire,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(displayName, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(auth.isGuest ? 'Guest · Full Access Enabled' : 'Everyday Athlete · GoFaster',
            style: AppTextStyles.bodySm),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GFTag(label: 'GoFaster Member', color: AppColors.primary),
              const SizedBox(width: 8),
              GFTag(label: '${hp.streakDays} Day Streak', color: AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ───────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final HealthProvider hp;
  const _StatsRow({required this.hp});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatData('Water',    '${hp.waterConsumed.toInt()} ml', const Color(0xFF2196F3)),
      _StatData('Calories', '${hp.caloriesBurned.toInt()} kcal', AppColors.accent),
      _StatData('Sleep',    hp.sleepDuration,                 const Color(0xFF7C4DFF)),
      _StatData('Vitamins', '${hp.vitaminsDone}/${hp.vitamins.length}', AppColors.success),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: stats.map((s) {
          final isLast = s == stats.last;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: s.color, shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(s.label, style: AppTextStyles.body),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.value,
                        style: AppTextStyles.h5.copyWith(color: s.color),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressFor(s.label, hp),
                            backgroundColor: AppColors.border,
                            valueColor: AlwaysStoppedAnimation<Color>(s.color),
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isLast) ...[const SizedBox(height: 14), const Divider(height: 1, color: AppColors.border), const SizedBox(height: 14)],
            ],
          );
        }).toList(),
      ),
    );
  }

  double _progressFor(String label, HealthProvider hp) {
    switch (label) {
      case 'Water':    return hp.waterProgress;
      case 'Calories': return hp.caloriesProgress;
      case 'Sleep':    return hp.sleepProgress;
      case 'Vitamins': return hp.vitamins.isEmpty ? 0 : hp.vitaminsDone / hp.vitamins.length;
      default:         return 0;
    }
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;
  const _StatData(this.label, this.value, this.color);
}

// ─── Goals Section (live Firestore data) ─────────────────
class _GoalsSection extends StatelessWidget {
  final HealthProvider hp;
  const _GoalsSection({required this.hp});

  @override
  Widget build(BuildContext context) {
    final goals = [
      _GoalItem(
        name: 'Daily Water',
        target: '${hp.waterGoal.toInt()} ml',
        progress: hp.waterProgress,
        color: const Color(0xFF2196F3),
      ),
      _GoalItem(
        name: 'Calories Burn',
        target: '900 kcal',
        progress: hp.caloriesProgress,
        color: AppColors.primary,
      ),
      _GoalItem(
        name: 'Sleep Target',
        target: '8 hours',
        progress: hp.sleepProgress,
        color: const Color(0xFF9C27B0),
      ),
      _GoalItem(
        name: 'Vitamin Streak',
        target: '${hp.vitaminStreak} days',
        progress: (hp.vitaminStreak / 30).clamp(0.0, 1.0),
        color: AppColors.success,
      ),
    ];

    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'My Goals'),
              // Live sync indicator
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Live', style: AppTextStyles.label.copyWith(
                    color: AppColors.success, fontSize: 10,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...goals.map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(g.name, style: AppTextStyles.body),
                    Text(g.target, style: AppTextStyles.bodySm.copyWith(
                      color: g.color, fontWeight: FontWeight.w600,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: g.progress,
                    child: Container(
                      decoration: BoxDecoration(
                        color: g.color,
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [BoxShadow(
                          color: g.color.withValues(alpha: 0.4),
                          blurRadius: 6,
                        )],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${(g.progress * 100).toInt()}%',
                    style: AppTextStyles.label.copyWith(color: g.color),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _GoalItem {
  final String name;
  final String target;
  final double progress;
  final Color color;
  const _GoalItem({
    required this.name, required this.target,
    required this.progress, required this.color,
  });
}

// ─── Edit Goals Bottom Sheet ─────────────────────────────
class _EditGoalsSheet extends StatefulWidget {
  final HealthProvider hp;
  const _EditGoalsSheet({required this.hp});

  @override
  State<_EditGoalsSheet> createState() => _EditGoalsSheetState();
}

class _EditGoalsSheetState extends State<_EditGoalsSheet> {
  late final TextEditingController _waterCtrl;
  late final TextEditingController _caloriesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _waterCtrl   = TextEditingController(text: widget.hp.waterGoal.toInt().toString());
    _caloriesCtrl = TextEditingController(text: widget.hp.caloriesGoal.toInt().toString());
  }

  @override
  void dispose() {
    _waterCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final water    = double.tryParse(_waterCtrl.text);
    final calories = double.tryParse(_caloriesCtrl.text);
    if (water == null || calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.hp.updateGoals({
      'waterGoal':    water,
      'caloriesGoal': calories,
    });
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Goals saved to Firestore!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Edit Goals', style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text('Changes sync to Firestore instantly', style: AppTextStyles.bodySm),
          const SizedBox(height: 24),
          _GoalField(
            label: 'Daily Water Goal (ml)',
            controller: _waterCtrl,
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 16),
          _GoalField(
            label: 'Daily Calories Goal (kcal)',
            controller: _caloriesCtrl,
            icon: Icons.local_fire_department_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2,
                      ),
                    )
                  : Text('Save Goals', style: AppTextStyles.button),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  const _GoalField({
    required this.label, required this.controller,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: color, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Settings Section ────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _SettingItem(Icons.notifications_rounded, 'Notifications', 'Daily reminders & alerts',
        onTap: () => Navigator.push(context, fadeRoute(const NotificationSettingsScreen()))),
      _SettingItem(Icons.fitness_center_rounded, 'Fitness Preferences', 'Goals & workout types',
        onTap: () => Navigator.push(context, fadeRoute(const FitnessPreferencesScreen()))),
      _SettingItem(Icons.share_rounded, 'Share Progress', 'Share with friends',
        onTap: () => Navigator.push(context, fadeRoute(const ShareProgressScreen()))),
      _SettingItem(Icons.help_rounded, 'Help & Support', 'FAQs & contact',
        onTap: () => Navigator.push(context, fadeRoute(const HelpSupportScreen()))),
    ];
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Settings'),
          const SizedBox(height: 16),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(12),
                    splashColor: AppColors.primary.withValues(alpha: 0.1),
                    highlightColor: AppColors.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: AppTextStyles.h5),
                                Text(item.subtitle, style: AppTextStyles.bodySm),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded,
                            color: AppColors.textMuted, size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < items.length - 1) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SettingItem(this.icon, this.title, this.subtitle, {required this.onTap});
}

// ─── Logout Button ──────────────────────────────────────
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () async {
          final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Log Out?', style: AppTextStyles.h4),
            content: Text(
              'You will be redirected to the login screen.',
              style: AppTextStyles.bodySm,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted)),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                  ),
                  child: Text('Log Out', style: AppTextStyles.buttonSm),
                ),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await context.read<AuthProvider>().logout();
        }
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: AppColors.error.withValues(alpha: 0.15),
        highlightColor: AppColors.error.withValues(alpha: 0.08),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              const SizedBox(width: 10),
              Text('Log Out', style: AppTextStyles.button.copyWith(color: AppColors.error)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── GoFaster Brand ──────────────────────────────────────
class _GoFasterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => InAppBrowserScreen.open(context, url: 'https://gofaster.in', title: 'GoFaster'),
      child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.fire,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 25, spreadRadius: -5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GoFaster Health',
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text('v1.0.0 · gofaster.in',
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 20),
        ],
      ),
    ),
    );
  }
}
