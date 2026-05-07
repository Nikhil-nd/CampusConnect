import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:developer' as dev;

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _timezoneReady = false;

  Future<void> _configureLocalTimezone() async {
    if (_timezoneReady) {
      return;
    }

    tz.initializeTimeZones();
    // flutter_timezone v5 returns TimezoneInfo; use .identifier for the IANA name.
    final TimezoneInfo tzInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = tzInfo.identifier;
    dev.log('NotificationService: local timezone = $timeZoneName');
    tz.setLocalLocation(tz.getLocation(timeZoneName));
    _timezoneReady = true;
  }

  Future<void> initialize() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    if (kIsWeb) {
      return;
    }

    await _configureLocalTimezone();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final RemoteNotification? notification = message.notification;
      if (notification == null) {
        return;
      }

      const AndroidNotificationDetails android = AndroidNotificationDetails(
        'campusconnect_channel',
        'CampusConnect Updates',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(android: android);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
      );
    });
  }

  Future<void> subscribeToGeneralTopics() async {
    if (kIsWeb) {
      return;
    }
    await _messaging.subscribeToTopic('events');
    await _messaging.subscribeToTopic('marketplace');
  }

  Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb) {
      return;
    }

    dev.log('NotificationService: scheduleEventReminder called for id=$id at $scheduledDate');

    await _configureLocalTimezone();
    final tz.TZDateTime reminderTime = tz.TZDateTime.from(scheduledDate, tz.local);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    dev.log('NotificationService: reminderTime=$reminderTime  now=$now');

    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'event_reminder_channel',
      'Event Reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: android);

    if (reminderTime.isBefore(now)) {
      // Reminder window already passed — fire immediately.
      dev.log('NotificationService: reminder time in the past, showing immediately');
      await _localNotifications.show(id, title, body, details);
      return;
    }

    // Try exact scheduling; fall back to inexact if exact alarms are not permitted.
    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        reminderTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      dev.log('NotificationService: exact alarm scheduled successfully');
    } catch (e) {
      dev.log('NotificationService: exact alarm failed ($e), falling back to inexact');
      // Fallback: inexact alarm (no special permission required).
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        reminderTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      dev.log('NotificationService: inexact alarm scheduled as fallback');
    }
  }
}
