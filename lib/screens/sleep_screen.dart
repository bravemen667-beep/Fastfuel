// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Sleep Analysis Screen
//
//  On first open:
//    1. Checks if Health Connect / HealthKit permission is already granted.
//    2. If not → shows PermissionGateScreen overlay.
//    3. If granted (or after grant) → auto-syncs real sleep data.
//    4. Shows "Synced X min ago" badge when real data is live.
//    5. If denied → falls back to Firestore / manual data silently.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../providers/health_provider.dart';
import '../services/health_sync_service.dart';
import '../services/claude_health_tips_service.dart';
import '../widgets/common_widgets.dart';
import 'permission_gate_screen.dart';

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  static const _prefKey = 'sleep_health_asked';
  bool _gateChecked = false;

  @override
  void initState() {
    super.initState();
    // Defer permission check until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPermission());
  }

  Future<void> _checkPermission() async {
    if (!mounted) return;
    final hp = context.read<HealthProvider>();

    // ── 1. Already granted? Sync immediately ──────────────────────────────
    final status = await hp.checkHealthPermission();
    if (status == HealthPermissionStatus.granted) {
      await hp.refreshHealthData();
      if (mounted) setState(() => _gateChecked = true);
      return;
    }

    // ── 2. Web / unsupported → skip gate ────────────────────────────────
    if (kIsWeb || status == HealthPermissionStatus.notAvailable) {
      if (mounted) setState(() => _gateChecked = true);
      return;
    }

    // ── 3. First time? Show gate ─────────────────────────────────────────
    final prefs = await SharedPreferences.getInstance();
    final alreadyAsked = prefs.getBool(_prefKey) ?? false;
    if (!alreadyAsked && mounted) {
      await prefs.setBool(_prefKey, true);
      if (!mounted) return;
      final granted = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const PermissionGateScreen(context: 'sleep'),
        ),
      );
      if ((granted ?? false) && mounted) {
        await hp.refreshHealthData();
      }
    }

    if (mounted) setState(() => _gateChecked = true);
  }

  @override
  Widget build(BuildContext context) {
    final hp = context.watch<HealthProvider>();

    if (hp.isLoading || !_gateChecked) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9C27B0), strokeWidth: 2,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: const Color(0xFF9C27B0),
        backgroundColor: AppColors.cardBg,
        onRefresh: () async {
          final status = await hp.checkHealthPermission();
          if (status == HealthPermissionStatus.granted) {
            await hp.refreshHealthData();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _header(hp),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Sync status banner ──────────────────────────────────
                  _SyncBanner(hp: hp).animate().fade(duration: 400.ms),
                  if (hp.syncLabel.isNotEmpty) const SizedBox(height: 12),

                  _SleepScoreCard(hp: hp).animate().fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _SleepTimesCard(hp: hp)
                      .animate(delay: 100.ms).fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _SleepStagesCard(hp: hp)
                      .animate(delay: 150.ms).fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _WeeklyTrend(hp: hp)
                      .animate(delay: 200.ms).fade(duration: 500.ms),
                  const SizedBox(height: 20),
                  _SleepTip().animate(delay: 250.ms).fade(duration: 500.ms),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _header(HealthProvider hp) {
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
                    Text('Sleep Analysis', style: AppTextStyles.h3),
                    hp.syncLabel.isNotEmpty
                        ? _SyncChip(label: hp.syncLabel)
                        : GFTag(label: 'Last Night', color: const Color(0xFF9C27B0)),
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

// ── Sync Status Banner ────────────────────────────────────────────────────────
class _SyncBanner extends StatelessWidget {
  final HealthProvider hp;
  const _SyncBanner({required this.hp});

  @override
  Widget build(BuildContext context) {
    // Syncing spinner
    if (hp.healthSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                color: Color(0xFF9C27B0), strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Syncing from ${hp.healthSource.isEmpty ? "Health" : hp.healthSource}…',
              style: AppTextStyles.bodySm.copyWith(color: const Color(0xFFBA68C8)),
            ),
          ],
        ),
      );
    }

    // Error banner
    if (hp.healthSyncError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Health sync unavailable — showing saved data',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    // Synced successfully
    if (hp.syncLabel.isNotEmpty && hp.healthSource.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${hp.syncLabel} from ${hp.healthSource} · Pull to refresh',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.success),
              ),
            ),
            const Icon(Icons.refresh_rounded, color: AppColors.success, size: 16),
          ],
        ),
      );
    }

    // No banner needed
    return const SizedBox.shrink();
  }
}

// ── Sync chip (shown in header) ───────────────────────────────────────────────
class _SyncChip extends StatelessWidget {
  final String label;
  const _SyncChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(label,
            style: AppTextStyles.tag.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

// ─── Sleep Score ─────────────────────────────────────────────────────────────
class _SleepScoreCard extends StatelessWidget {
  final HealthProvider hp;
  const _SleepScoreCard({required this.hp});

  String get _qualityLabel {
    final s = hp.sleepScore;
    if (s >= 85) return 'Excellent';
    if (s >= 70) return 'Good Quality';
    if (s >= 55) return 'Fair';
    return 'Poor';
  }

  Color get _qualityColor {
    final s = hp.sleepScore;
    if (s >= 85) return AppColors.success;
    if (s >= 70) return AppColors.success;
    if (s >= 55) return AppColors.warning;
    return AppColors.error;
  }

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
            color: const Color(0xFF9C27B0).withValues(alpha: 0.12),
            blurRadius: 25,
          ),
        ],
      ),
      child: Row(
        children: [
          GlowRing(
            progress: hp.sleepProgress,
            size: 120,
            strokeWidth: 10,
            gradientColors: const [Color(0xFF9C27B0), AppColors.primary],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bedtime_rounded, color: Color(0xFFBA68C8), size: 20),
                Text(hp.sleepScore.toInt().toString(), style: AppTextStyles.h2),
                Text('/ 100', style: AppTextStyles.label),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _qualityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _qualityLabel,
                    style: AppTextStyles.tag.copyWith(color: _qualityColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Sleep Duration', style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(
                  hp.sleepDuration,
                  style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.trending_up_rounded,
                      color: AppColors.success, size: 14),
                    const SizedBox(width: 4),
                    Text('+5% vs Last Week',
                      style: AppTextStyles.label.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Efficiency: ${(hp.sleepEfficiency * 100).toInt()}%',
                  style: AppTextStyles.caption.copyWith(color: const Color(0xFFBA68C8)),
                ),
                // Heart rate hint if synced
                if (hp.heartRateBpm > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded,
                        color: AppColors.error, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Avg HR: ${hp.heartRateBpm.toInt()} bpm',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sleep Times ─────────────────────────────────────────────────────────────
class _SleepTimesCard extends StatelessWidget {
  final HealthProvider hp;
  const _SleepTimesCard({required this.hp});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TimeCard(
          label: 'Bedtime',
          time: hp.bedtime,
          icon: Icons.nightlight_round,
          color: const Color(0xFF9C27B0),
        )),
        const SizedBox(width: 12),
        Expanded(child: _TimeCard(
          label: 'Wake Up',
          time: hp.wakeTime,
          icon: Icons.wb_sunny_rounded,
          color: AppColors.accent,
        )),
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimeCard({
    required this.label, required this.time,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(time, style: AppTextStyles.h4.copyWith(color: color)),
        ],
      ),
    );
  }
}

// ─── Sleep Stages ─────────────────────────────────────────────────────────────
class _SleepStagesCard extends StatelessWidget {
  final HealthProvider hp;
  const _SleepStagesCard({required this.hp});

  static const _stageLabels = [
    _StageLabel('REM',   AppColors.sleepRem),
    _StageLabel('Core',  AppColors.sleepCore),
    _StageLabel('Deep',  AppColors.sleepDeep),
    _StageLabel('Awake', AppColors.sleepAwake),
  ];

  @override
  Widget build(BuildContext context) {
    final stages = hp.sleepStages;
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Sleep Stages'),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stages.map((s) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FractionallySizedBox(
                      heightFactor: s.heightFraction,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: s.color.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _stageLabels.map((l) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: l.color, shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(l.label, style: AppTextStyles.label),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _StageLabel {
  final String label;
  final Color color;
  const _StageLabel(this.label, this.color);
}

// ─── Weekly Trend ─────────────────────────────────────────────────────────────
class _WeeklyTrend extends StatelessWidget {
  final HealthProvider hp;
  const _WeeklyTrend({required this.hp});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final data = hp.sleepWeekly;
    return GFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: '7-Day Sleep Trend'),
              if (hp.syncLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.health_and_safety_rounded,
                        color: AppColors.success, size: 12),
                      const SizedBox(width: 4),
                      Text('Live',
                        style: AppTextStyles.tag.copyWith(color: AppColors.success),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                final isToday = i == data.length - 1;
                final barHeight = (data[i] > 0.02) ? data[i] : 0.05;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == data.length - 1 ? 0 : 6,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: barHeight,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: isToday
                                    ? AppGradients.fire
                                    : LinearGradient(
                                        colors: [
                                          const Color(0xFF9C27B0).withValues(alpha: 0.5),
                                          const Color(0xFF9C27B0),
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                      ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: isToday
                                    ? [BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _days[i % _days.length],
                          style: AppTextStyles.label.copyWith(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
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

// ─── Sleep Tip ────────────────────────────────────────────────────────────────
class _SleepTip extends StatefulWidget {
  @override
  State<_SleepTip> createState() => _SleepTipState();
}

class _SleepTipState extends State<_SleepTip> {
  String _tip = 'Consistent sleep and wake times improve deep sleep quality by up to 30%.'; 

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
      final tip = await ClaudeHealthTipsService.instance.getSleepTip(
        sleepHours: _parseSleepHours(hp.sleepDuration),
        score: hp.score.toInt(),
        deepSleepPct: hp.sleepScore > 0 ? (hp.sleepScore / 100) : 0.2,
      );
      if (mounted) setState(() => _tip = tip);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      message: _tip,
      icon: Icons.bolt_rounded,
      color: const Color(0xFF9C27B0),
    );
  }
}
