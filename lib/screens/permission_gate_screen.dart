// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — PermissionGateScreen
//
//  Shown the first time a user opens Sleep Analysis or Calorie Dashboard.
//  Explains what data will be read and requests Health Connect / HealthKit.
//
//  If denied → pops back and lets the screen show with manual fallback.
//  If granted → pops with result = true so the screen auto-syncs.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../services/health_sync_service.dart';

enum _PermStep { intro, requesting, granted, denied }

class PermissionGateScreen extends StatefulWidget {
  /// Which context triggered this gate: 'sleep' or 'calories'
  final String context;
  const PermissionGateScreen({super.key, required this.context});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> {
  _PermStep _step = _PermStep.intro;

  String get _platformName => HealthSyncService.instance.platformName;

  bool get _isWeb => kIsWeb;

  Future<void> _requestPermission() async {
    setState(() => _step = _PermStep.requesting);

    if (_isWeb) {
      // Web: always skip to manual fallback
      setState(() => _step = _PermStep.denied);
      return;
    }

    final granted = await HealthSyncService.instance.requestPermission();
    setState(() => _step = granted ? _PermStep.granted : _PermStep.denied);

    if (granted) {
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  void _skipToManual() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildStep(),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _PermStep.intro:
        return _IntroView(
          context: widget.context,
          platformName: _isWeb ? 'Health Sync' : _platformName,
          isWeb: _isWeb,
          onAllow: _requestPermission,
          onSkip: _skipToManual,
        );
      case _PermStep.requesting:
        return const _LoadingView();
      case _PermStep.granted:
        return const _GrantedView();
      case _PermStep.denied:
        return _DeniedView(onManual: _skipToManual);
    }
  }
}

// ── Intro View ────────────────────────────────────────────────────────────────
class _IntroView extends StatelessWidget {
  final String context;
  final String platformName;
  final bool   isWeb;
  final VoidCallback onAllow;
  final VoidCallback onSkip;

  const _IntroView({
    required this.context,
    required this.platformName,
    required this.isWeb,
    required this.onAllow,
    required this.onSkip,
  });

  bool get _isSleep => context == 'sleep';

  @override
  Widget build(BuildContext ctx) {
    final perms = _isSleep
        ? [
            _PermItem(Icons.bedtime_rounded,       'Sleep Analysis',
                'Bedtime, wake time & sleep stages', const Color(0xFF9C27B0)),
            _PermItem(Icons.psychology_rounded,    'Sleep Quality Score',
                'Deep, REM and core sleep breakdown', const Color(0xFF7B1FA2)),
            _PermItem(Icons.show_chart_rounded,    '7-Day Sleep Trend',
                'Weekly sleep pattern visualisation', AppColors.accent),
          ]
        : [
            _PermItem(Icons.local_fire_department_rounded, 'Active Calories',
                'Real calories burned from workouts', AppColors.primary),
            _PermItem(Icons.directions_walk_rounded,       'Step Count',
                'Daily steps from phone & wearables', AppColors.accent),
            _PermItem(Icons.favorite_rounded,              'Heart Rate',
                'Average BPM during activities', AppColors.error),
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(
        children: [
          // Header illustration
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: _isSleep
                  ? const LinearGradient(
                      colors: [Color(0xFF4A148C), Color(0xFF9C27B0)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    )
                  : AppGradients.fire,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: (_isSleep
                      ? const Color(0xFF9C27B0)
                      : AppColors.primary).withValues(alpha: 0.4),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Icon(
              _isSleep ? Icons.bedtime_rounded : Icons.monitor_heart_rounded,
              color: Colors.white, size: 52,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOut),

          const SizedBox(height: 28),

          Text(
            _isSleep
                ? 'Real Sleep Data\nfrom $platformName'
                : 'Real Activity Data\nfrom $platformName',
            style: AppTextStyles.h2.copyWith(height: 1.3),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 100.ms),

          const SizedBox(height: 12),

          Text(
            _isSleep
                ? 'GoFaster will read your sleep records to show accurate bedtime, stages and recovery score.'
                : 'GoFaster will read your activity data to show real calories burned, steps and heart rate.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary, height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fade(delay: 150.ms),

          const SizedBox(height: 32),

          // Permissions list
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: perms.asMap().entries.map((e) {
                final i    = e.key;
                final perm = e.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: perm.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(perm.icon, color: perm.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(perm.title, style: AppTextStyles.h5),
                                Text(perm.subtitle, style: AppTextStyles.bodySm),
                              ],
                            ),
                          ),
                          Icon(Icons.lock_open_rounded,
                            color: AppColors.success, size: 18,
                          ),
                        ],
                      ),
                    ),
                    if (i < perms.length - 1)
                      const Divider(height: 1, color: AppColors.border),
                  ],
                );
              }).toList(),
            ),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),

          // Data use note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppColors.success, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GoFaster only READS your data — we never modify or share it.',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.success, height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 250.ms),

          const SizedBox(height: 32),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAllow,
              icon: Icon(
                isWeb ? Icons.edit_note_rounded : Icons.health_and_safety_rounded,
              ),
              label: Text(
                isWeb
                    ? 'Enter Data Manually'
                    : 'Connect $platformName',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isSleep
                    ? const Color(0xFF9C27B0)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: AppTextStyles.button,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ).animate().fade(delay: 300.ms),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: onSkip,
            child: Text(
              'Skip — Enter manually',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textMuted),
            ),
          ).animate().fade(delay: 350.ms),
        ],
      ),
    );
  }
}

class _PermItem {
  final IconData icon;
  final String   title;
  final String   subtitle;
  final Color    color;
  const _PermItem(this.icon, this.title, this.subtitle, this.color);
}

// ── Loading View ──────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text('Requesting permission…', style: AppTextStyles.h4),
          const SizedBox(height: 8),
          Text('Please accept in the system dialog',
            style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}

// ── Granted View ──────────────────────────────────────────────────────────────
class _GrantedView extends StatelessWidget {
  const _GrantedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 44,
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text('Permission Granted!', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text('Syncing your health data…', style: AppTextStyles.bodySm),
          const SizedBox(height: 24),
          const SizedBox(
            width: 32, height: 32,
            child: CircularProgressIndicator(
              color: AppColors.success, strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Denied View ───────────────────────────────────────────────────────────────
class _DeniedView extends StatelessWidget {
  final VoidCallback onManual;
  const _DeniedView({required this.onManual});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.no_accounts_rounded,
              color: AppColors.error, size: 44,
            ),
          ).animate().scale(duration: 400.ms),
          const SizedBox(height: 24),
          Text('Permission Denied', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            'You can still enter your sleep and calorie data manually. '
            'To enable auto-sync later, go to Settings → Health on your phone.',
            style: AppTextStyles.bodySm.copyWith(height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onManual,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Enter Data Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
