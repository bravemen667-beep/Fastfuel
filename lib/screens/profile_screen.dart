import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          GlowBlob(color: AppColors.primary, size: 300, alignment: const Alignment(0, -0.8), opacity: 0.1),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Header ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profile', style: AppTextStyles.headingMd),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: glassDecoration(borderRadius: 12),
                          child: const Icon(Icons.settings_rounded, color: AppColors.textSecondary, size: 18),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),

                  const SizedBox(height: 24),

                  // ── Avatar & Name ────────────────────────
                  _AvatarSection().animate().fadeIn(delay: 100.ms, duration: 600.ms),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // ── Stats Row ──────────────────────
                        _StatsRow().animate().fadeIn(delay: 200.ms, duration: 500.ms),

                        const SizedBox(height: 20),

                        // ── GoFaster Membership ────────────
                        _MembershipCard().animate().fadeIn(delay: 300.ms, duration: 500.ms),

                        const SizedBox(height: 20),

                        // ── Settings Menu ──────────────────
                        _SettingsMenu().animate().fadeIn(delay: 400.ms, duration: 500.ms),

                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Avatar Section
// ─────────────────────────────────────────────────────
class _AvatarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primaryGradient,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 28),
                ],
              ),
            ),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceDark,
              ),
            ),
            Text('A',
              style: AppTextStyles.displayMedium.copyWith(
                fontSize: 38,
                foreground: Paint()
                  ..shader = AppGradients.primaryGradient.createShader(
                    const Rect.fromLTWH(0, 0, 60, 60),
                  ),
              )),
          ],
        ),
        const SizedBox(height: 14),
        Text('Alex Johnson',
          style: AppTextStyles.headingMd.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_rounded, color: AppColors.textMuted, size: 14),
            const SizedBox(width: 3),
            Text('San Francisco, CA',
              style: AppTextStyles.body.copyWith(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        NeonBadge(label: '⚡ GoFaster Elite Member', color: AppColors.primary),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
//  Stats Row
// ─────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(value: '88', label: 'Avg Score')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '14', label: 'Day Streak')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(value: '124', label: 'Workouts')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: glassDecoration(borderRadius: 18),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (r) => AppGradients.primaryGradient.createShader(r),
            child: Text(value,
              style: AppTextStyles.headingXL.copyWith(fontSize: 26)),
          ),
          const SizedBox(height: 4),
          Text(label,
            style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
//  Membership Card
// ─────────────────────────────────────────────────────
class _MembershipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.25), AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('GoFaster Elite',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                )),
              NeonBadge(label: 'Active', color: AppColors.neonGreen),
            ],
          ),
          const SizedBox(height: 6),
          Text('Member since January 2024',
            style: AppTextStyles.body.copyWith(fontSize: 12)),
          const SizedBox(height: 16),
          // Feature list
          ...['AI Workout Plans', 'Advanced Sleep Analysis', 'Priority Support'].map((f) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 16),
                  const SizedBox(width: 8),
                  Text(f,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16)],
                  ),
                  child: const Center(
                    child: Text('Manage Plan',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      )),
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
//  Settings Menu
// ─────────────────────────────────────────────────────
class _SettingsMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(Icons.person_outline_rounded, 'Edit Profile', AppColors.primary),
      _MenuItem(Icons.notifications_outlined, 'Notifications', AppColors.neonBlue),
      _MenuItem(Icons.health_and_safety_outlined, 'Health Sync', AppColors.accentGreen),
      _MenuItem(Icons.fitness_center_outlined, 'Goals & Targets', AppColors.neonOrange),
      _MenuItem(Icons.privacy_tip_outlined, 'Privacy & Data', AppColors.textMuted),
      _MenuItem(Icons.help_outline_rounded, 'Help & Support', AppColors.textMuted),
      _MenuItem(Icons.logout_rounded, 'Sign Out', AppColors.error),
    ];

    return Container(
      decoration: glassDecoration(borderRadius: 22),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(item.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: item.color == AppColors.error ? AppColors.error : AppColors.textPrimary,
                          fontSize: 14,
                        )),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.05),
                  indent: 68,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem(this.icon, this.label, this.color);
}
