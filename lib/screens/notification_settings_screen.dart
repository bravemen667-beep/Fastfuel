// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — Notification Settings Screen
//  Toggles for: Hydration, Morning Vitamin, Evening Vitamin, Sleep Bedtime,
//  GoFaster Tablet. Each toggle subscribes/unsubscribes the FCM topic.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Toggle states
  bool _hydration    = true;
  bool _vitaminAM    = true;
  bool _vitaminPM    = true;
  bool _sleepBedtime = true;
  bool _tabletRemind = true;

  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _hydration    = p.getBool('notif_hydration')    ?? true;
      _vitaminAM    = p.getBool('notif_vitaminAM')    ?? true;
      _vitaminPM    = p.getBool('notif_vitaminPM')    ?? true;
      _sleepBedtime = p.getBool('notif_sleepBedtime') ?? true;
      _tabletRemind = p.getBool('notif_tablet')       ?? true;
      _loading = false;
    });
  }

  Future<void> _toggle(String key, bool val, Future<void> Function() action) async {
    setState(() {
      switch (key) {
        case 'hydration':    _hydration    = val; break;
        case 'vitaminAM':    _vitaminAM    = val; break;
        case 'vitaminPM':    _vitaminPM    = val; break;
        case 'sleepBedtime': _sleepBedtime = val; break;
        case 'tablet':       _tabletRemind = val; break;
      }
    });
    final p = await SharedPreferences.getInstance();
    await p.setBool('notif_$key', val);
    await action();
  }

  // Calculate next hydration reminder time (every 90 min, 8am–10pm)
  String _nextHydrationTime() {
    final now = DateTime.now();
    // Schedule starts at 8:00 AM
    var next = DateTime(now.year, now.month, now.day, 8, 0);
    while (next.isBefore(now) || next.hour > 22) {
      next = next.add(const Duration(minutes: 90));
      if (next.hour > 22) {
        // Move to next day at 8:00 AM
        next = DateTime(now.year, now.month, now.day + 1, 8, 0);
      }
    }
    final h = next.hour > 12 ? next.hour - 12 : next.hour == 0 ? 12 : next.hour;
    final m = next.minute.toString().padLeft(2, '0');
    final ampm = next.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          if (_loading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildInfoBanner(),
                  const SizedBox(height: 20),
                  _buildSection(
                    title: 'Hydration Reminders',
                    items: [
                      _NotifItem(
                        icon: Icons.water_drop_rounded,
                        color: const Color(0xFF2196F3),
                        title: 'Hydration Reminder',
                        subtitle: 'Every 90 min · 8:00 AM – 10:00 PM',
                        extraInfo: _hydration
                            ? 'Next: ${_nextHydrationTime()}'
                            : 'Off',
                        value: _hydration,
                        deepLinkScreen: 'hydration',
                        onChanged: (v) => _toggle(
                          'hydration', v,
                          () => NotificationService.instance.setHydrationReminders(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Vitamin Reminders',
                    items: [
                      _NotifItem(
                        icon: Icons.wb_sunny_rounded,
                        color: AppColors.accent,
                        title: 'Morning Vitamin',
                        subtitle: 'Daily at 6:05 AM',
                        value: _vitaminAM,
                        deepLinkScreen: 'vitamins',
                        onChanged: (v) => _toggle(
                          'vitaminAM', v,
                          () => NotificationService.instance.setVitaminMorningReminder(v),
                        ),
                      ),
                      _NotifItem(
                        icon: Icons.medication_rounded,
                        color: AppColors.success,
                        title: 'Evening Vitamin',
                        subtitle: 'Daily at 7:00 PM',
                        value: _vitaminPM,
                        deepLinkScreen: 'vitamins',
                        onChanged: (v) => _toggle(
                          'vitaminPM', v,
                          () => NotificationService.instance.setVitaminEveningReminder(v),
                        ),
                      ),
                      _NotifItem(
                        icon: Icons.local_pharmacy_rounded,
                        color: AppColors.primary,
                        title: 'GoFaster Tablet',
                        subtitle: 'Daily at 8:00 AM',
                        value: _tabletRemind,
                        deepLinkScreen: 'vitamins',
                        onChanged: (v) => _toggle(
                          'tablet', v,
                          () => NotificationService.instance.setTabletReminder(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Sleep Reminders',
                    items: [
                      _NotifItem(
                        icon: Icons.bedtime_rounded,
                        color: const Color(0xFF9C27B0),
                        title: 'Sleep Bedtime',
                        subtitle: 'Daily at 10:30 PM',
                        value: _sleepBedtime,
                        deepLinkScreen: 'sleep',
                        onChanged: (v) => _toggle(
                          'sleepBedtime', v,
                          () => NotificationService.instance.setSleepReminder(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFooterNote(),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 70,
      floating: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 16),
        ),
      ),
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
                Text('Notifications', style: AppTextStyles.h3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                        color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text('FCM', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Notifications are powered by Firebase Cloud Messaging (FCM) and delivered even when the app is closed.',
              style: AppTextStyles.bodySm.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<_NotifItem> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(title,
            style: AppTextStyles.h5.copyWith(color: AppColors.textMuted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(
                children: [
                  _NotifTile(item: item),
                  if (i < items.length - 1)
                    const Divider(height: 1, indent: 20, endIndent: 20, color: AppColors.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About Notifications',
            style: AppTextStyles.h5.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _noteRow('Hydration reminders are scheduled every 90 min between 8 AM – 10 PM.'),
          _noteRow('Vitamin reminders open the Daily Fuel screen when tapped.'),
          _noteRow('Sleep reminders open the Sleep Analysis screen when tapped.'),
          _noteRow('Tap any notification to open the relevant GoFaster screen.'),
        ],
      ),
    );
  }

  Widget _noteRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5, height: 5,
            decoration: const BoxDecoration(
              color: AppColors.textMuted, shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodySm.copyWith(height: 1.4))),
        ],
      ),
    );
  }
}

// ── Notification Tile ─────────────────────────────────────────────────────────
class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? extraInfo;
  final bool value;
  final String deepLinkScreen;
  final ValueChanged<bool> onChanged;

  const _NotifItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.extraInfo,
    required this.value,
    required this.deepLinkScreen,
    required this.onChanged,
  });
}

class _NotifTile extends StatelessWidget {
  final _NotifItem item;
  const _NotifTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.h5),
                const SizedBox(height: 2),
                Text(item.subtitle, style: AppTextStyles.bodySm),
                if (item.extraInfo != null && item.value) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      item.extraInfo!,
                      style: AppTextStyles.label.copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: item.value,
            onChanged: item.onChanged,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return item.color;
              return AppColors.textMuted;
            }),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return item.color.withValues(alpha: 0.35);
              }
              return AppColors.border;
            }),
          ),
        ],
      ),
    );
  }
}
