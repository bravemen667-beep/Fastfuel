// ─────────────────────────────────────────────────────────────────────────────
//  GoFaster Health — NotificationService
//
//  Two-layer notification strategy:
//  ┌─────────────────────────────────────────────────────────────────────────┐
//  │  Layer 1 — FCM topics (server-side)                                     │
//  │    Requires Firebase Cloud Functions to push messages on schedule.      │
//  │    This service handles subscribe/unsubscribe and token registration.   │
//  │                                                                          │
//  │  Layer 2 — flutter_local_notifications (client-side)                   │
//  │    Schedules exact-time alarms on-device so reminders fire even when    │
//  │    the app is in the background and Firebase Functions are not set up.  │
//  │    Hydration: every 90 min 08:00–22:00 (10 daily alarms)               │
//  │    After device reboot the app must be opened once to re-schedule.      │
//  └─────────────────────────────────────────────────────────────────────────┘
//
//  Service-restart / reboot detection:
//  When init() is called we compare the list of pending local notifications
//  against what *should* be scheduled. If fewer than expected are found,
//  we transparently re-schedule them.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'firestore_service.dart';

// Background FCM handler — must be top-level
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] ${message.notification?.title}: ${message.notification?.body}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm  = FirebaseMessaging.instance;
  final _fln  = FlutterLocalNotificationsPlugin();
  bool _flnReady = false;
  bool _tzInitialised = false;

  // ── FCM Topic names ────────────────────────────────────────────────────────
  static const topicHydration    = 'hydration_reminder';
  static const topicVitaminAM    = 'vitamin_morning';
  static const topicVitaminPM    = 'vitamin_evening';
  static const topicSleepBedtime = 'sleep_bedtime';

  // ── Local notification ID ranges ──────────────────────────────────────────
  // Hydration: 100–119, Vitamin AM: 200, Vitamin PM: 201, Sleep: 202
  static const _hydrationBaseId = 100;

  // ── Android notification channel ─────────────────────────────────────────
  static const _channelId   = 'gofaster_reminders';
  static const _channelName = 'GoFaster Reminders';
  static const _channelDesc = 'Hydration, vitamin, and sleep reminders';

  // 90-min hydration slots between 08:00 and 22:00
  static const _hydrationSlots = [
    [8,  0], [9, 30], [11, 0], [12, 30], [14,  0],
    [15, 30], [17, 0], [18, 30], [20, 0], [21, 30],
  ];

  // ── Initialize ────────────────────────────────────────────────────────────
  Future<void> init({String? uid}) async {
    // ── FCM ──────────────────────────────────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final settings = await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      final token = await _fcm.getToken();
      if (token != null && uid != null) {
        await FirestoreService.instance.saveFcmToken(uid, token);
      }
      _fcm.onTokenRefresh.listen((t) async {
        if (uid != null) await FirestoreService.instance.saveFcmToken(uid, t);
      });
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      await subscribeAllReminders();
    }

    // ── Local notifications ───────────────────────────────────────────────
    if (!kIsWeb) {
      _initTimezone();
      await _initLocalNotifications();
      // Service-restart / reboot check
      await _checkAndRestoreHydrationAlarms();
    }
  }

  void _initTimezone() {
    if (_tzInitialised) return;
    tz.initializeTimeZones();
    _tzInitialised = true;
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _fln.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _flnReady = true;

    // Create persistent Android channel
    await _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );
  }

  void _onNotificationTap(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('[LocalNotif] Tapped: payload=${response.payload}');
    }
    // Deep-link routing is handled by the app's navigation layer
    // by listening for notification taps via getNotificationAppLaunchDetails
  }

  // ── Service-restart / reboot detection ──────────────────────────────────
  Future<void> _checkAndRestoreHydrationAlarms() async {
    if (!_flnReady) return;
    try {
      final pending = await _fln.pendingNotificationRequests();
      final hydrationCount = pending
          .where((n) => n.id >= _hydrationBaseId && n.id < _hydrationBaseId + 20)
          .length;
      if (hydrationCount < 3) {
        // Far fewer alarms than expected — service restarted or rebooted
        if (kDebugMode) {
          debugPrint('[LocalNotif] Only $hydrationCount hydration alarms pending. Re-scheduling…');
        }
        await _scheduleHydrationAlarms();
      } else {
        if (kDebugMode) {
          debugPrint('[LocalNotif] $hydrationCount hydration alarms OK — no restart needed');
        }
      }
    } catch (e) {
      debugPrint('[LocalNotif] checkAndRestore error: $e');
    }
  }

  // ── Schedule local hydration alarms ─────────────────────────────────────
  Future<void> _scheduleHydrationAlarms() async {
    if (!_flnReady || kIsWeb) return;
    _initTimezone();
    await _cancelHydrationAlarms();

    final now      = tz.TZDateTime.now(tz.local);
    final localTz  = tz.local;

    for (var i = 0; i < _hydrationSlots.length; i++) {
      final h = _hydrationSlots[i][0];
      final m = _hydrationSlots[i][1];

      var scheduledDate = tz.TZDateTime(
        localTz,
        now.year, now.month, now.day, h, m,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _fln.zonedSchedule(
          _hydrationBaseId + i,
          '💧 Time to hydrate!',
          'Tap to log your water intake. Stay on track!',
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              ticker: 'GoFaster Hydration',
            ),
            iOS: DarwinNotificationDetails(
              sound: 'default',
              presentAlert: true,
              presentBadge: false,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'hydration',
          matchDateTimeComponents: DateTimeComponents.time,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('[LocalNotif] Failed to schedule slot $i: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('[LocalNotif] ${_hydrationSlots.length} hydration alarms scheduled');
    }
  }

  Future<void> _cancelHydrationAlarms() async {
    if (!_flnReady || kIsWeb) return;
    for (var i = 0; i < 20; i++) {
      await _fln.cancel(_hydrationBaseId + i);
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> setHydrationReminders(bool enabled) async {
    if (enabled) {
      await _fcm.subscribeToTopic(topicHydration);
      await _scheduleHydrationAlarms();
    } else {
      await _fcm.unsubscribeFromTopic(topicHydration);
      await _cancelHydrationAlarms();
    }
    debugPrint('[Notification] Hydration reminders ${enabled ? "on" : "off"}');
  }

  Future<void> setVitaminReminders(bool enabled) async {
    await Future.wait(enabled
        ? [_fcm.subscribeToTopic(topicVitaminAM), _fcm.subscribeToTopic(topicVitaminPM)]
        : [_fcm.unsubscribeFromTopic(topicVitaminAM), _fcm.unsubscribeFromTopic(topicVitaminPM)]);
    debugPrint('[Notification] Vitamin reminders ${enabled ? "on" : "off"}');
  }

  Future<void> setVitaminMorningReminder(bool enabled) async {
    if (enabled) {
      await _fcm.subscribeToTopic(topicVitaminAM);
    } else {
      await _fcm.unsubscribeFromTopic(topicVitaminAM);
    }
    debugPrint('[Notification] Morning vitamin ${enabled ? "on" : "off"}');
  }

  Future<void> setVitaminEveningReminder(bool enabled) async {
    if (enabled) {
      await _fcm.subscribeToTopic(topicVitaminPM);
    } else {
      await _fcm.unsubscribeFromTopic(topicVitaminPM);
    }
    debugPrint('[Notification] Evening vitamin ${enabled ? "on" : "off"}');
  }

  Future<void> setTabletReminder(bool enabled) async {
    if (enabled) {
      await _fcm.subscribeToTopic(topicVitaminAM);
    } else {
      await _fcm.unsubscribeFromTopic(topicVitaminAM);
    }
    debugPrint('[Notification] Tablet reminder ${enabled ? "on" : "off"}');
  }

  Future<void> setSleepReminder(bool enabled) async {
    if (enabled) {
      await _fcm.subscribeToTopic(topicSleepBedtime);
    } else {
      await _fcm.unsubscribeFromTopic(topicSleepBedtime);
    }
    debugPrint('[Notification] Sleep reminder ${enabled ? "on" : "off"}');
  }

  Future<void> subscribeAllReminders() async {
    await Future.wait([
      _fcm.subscribeToTopic(topicHydration),
      _fcm.subscribeToTopic(topicVitaminAM),
      _fcm.subscribeToTopic(topicVitaminPM),
      _fcm.subscribeToTopic(topicSleepBedtime),
    ]);
    debugPrint('[FCM] Subscribed to all 4 reminder topics');
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n != null) {
      if (_flnReady && !kIsWeb) {
        _fln.show(
          0, n.title, n.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId, _channelName,
              channelDescription: _channelDesc,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: message.data['screen'] as String?,
        );
      }
    }
  }

  // ── Reminder metadata for Settings UI ────────────────────────────────────
  static const List<ReminderInfo> reminders = [
    ReminderInfo(
      topic: topicHydration,
      title: 'Hydration Reminder',
      description: 'Every 90 min · 8:00 AM – 10:00 PM',
      icon: 0xe3d7,
    ),
    ReminderInfo(
      topic: topicVitaminAM,
      title: 'Morning Vitamins',
      description: 'Daily at 6:05 AM',
      icon: 0xe1a7,
    ),
    ReminderInfo(
      topic: topicVitaminPM,
      title: 'Evening Vitamins',
      description: 'Daily at 7:00 PM',
      icon: 0xef64,
    ),
    ReminderInfo(
      topic: topicSleepBedtime,
      title: 'Bedtime Reminder',
      description: 'Daily at 10:30 PM',
      icon: 0xe517,
    ),
  ];
}

class ReminderInfo {
  final String topic;
  final String title;
  final String description;
  final int icon;
  const ReminderInfo({
    required this.topic,
    required this.title,
    required this.description,
    required this.icon,
  });
}
