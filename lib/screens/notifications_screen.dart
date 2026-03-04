import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
// common_widgets imported if needed

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_Notif> _notifs = [
    _Notif(
      icon: Icons.water_drop_rounded,
      title: 'Hydration Reminder',
      body: 'Time to drink water! You\'re 750ml behind your goal.',
      time: '10 min ago',
      color: const Color(0xFF2196F3),
      isRead: false,
    ),
    _Notif(
      icon: Icons.bolt_rounded,
      title: 'GoFaster Score Updated',
      body: 'Your score improved by +12% this week. Keep it up! 💪',
      time: '1 hour ago',
      color: AppColors.primary,
      isRead: false,
    ),
    _Notif(
      icon: Icons.medication_rounded,
      title: 'Vitamin Reminder',
      body: 'Take your GoFaster tablet with warm water now.',
      time: '2 hours ago',
      color: AppColors.success,
      isRead: true,
    ),
    _Notif(
      icon: Icons.fitness_center_rounded,
      title: 'Workout Ready',
      body: 'AI suggests a 25-min HIIT session based on your recovery score.',
      time: 'Yesterday',
      color: const Color(0xFF9C27B0),
      isRead: true,
    ),
    _Notif(
      icon: Icons.bedtime_rounded,
      title: 'Sleep Insight',
      body: 'You averaged 7h 42m sleep this week. Try for 8 hours tonight.',
      time: 'Yesterday',
      color: const Color(0xFF9C27B0),
      isRead: true,
    ),
    _Notif(
      icon: Icons.emoji_events_rounded,
      title: '14-Day Streak! 🔥',
      body: 'You\'ve been consistent for 14 days! Claim your badge.',
      time: '2 days ago',
      color: AppColors.accent,
      isRead: true,
    ),
  ];

  int get _unreadCount => _notifs.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Row(
          children: [
            Text('Notifications', style: AppTextStyles.h4),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppGradients.fire,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text('$_unreadCount', style: AppTextStyles.label.copyWith(color: Colors.white)),
              ),
            ],
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var i = 0; i < _notifs.length; i++) {
                    _notifs[i] = _notifs[i].copyWith(isRead: true);
                  }
                });
              },
              child: Text('Mark all read',
                style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: _notifs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_rounded,
                      color: AppColors.textMuted, size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('No notifications', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text('You\'re all caught up!', style: AppTextStyles.bodySm),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: _notifs.length,
              itemBuilder: (_, i) {
                return _NotifTile(
                  notif: _notifs[i],
                  onTap: () => setState(() {
                    _notifs[i] = _notifs[i].copyWith(isRead: true);
                  }),
                  onDismiss: () => setState(() => _notifs.removeAt(i)),
                ).animate(delay: Duration(milliseconds: i * 60)).fade(duration: 400.ms).slideX(begin: 0.1, end: 0);
              },
            ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final _Notif notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifTile({required this.notif, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notif.title + notif.time),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif.isRead ? AppColors.cardBg : notif.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.isRead ? AppColors.border : notif.color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: notif.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(notif.icon, color: notif.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(notif.title, style: AppTextStyles.h5.copyWith(
                            fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w700,
                          )),
                        ),
                        if (!notif.isRead)
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: notif.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notif.body, style: AppTextStyles.bodySm.copyWith(height: 1.4)),
                    const SizedBox(height: 6),
                    Text(notif.time, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notif {
  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;
  final bool isRead;

  const _Notif({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.isRead,
  });

  _Notif copyWith({bool? isRead}) => _Notif(
    icon: icon, title: title, body: body, time: time, color: color,
    isRead: isRead ?? this.isRead,
  );
}
