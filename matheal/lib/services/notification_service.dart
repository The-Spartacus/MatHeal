// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(initializationSettings);

    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(); // Use requestPermissions() for broader compatibility
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'matheal_channel',
        'MatHeal Notifications',
        channelDescription: 'Notifications for MatHeal app',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String repeatInterval = 'none', // ✅ Add optional parameter for repeating
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'matheal_reminders',
        'MatHeal Reminders',
        channelDescription: 'Reminder notifications for MatHeal',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    // ✅ Logic to determine the repetition schedule
    DateTimeComponents? dateTimeComponents;
    switch (repeatInterval) {
      case 'daily':
        // Repeats every day at the specified time
        dateTimeComponents = DateTimeComponents.time;
        break;
      case 'weekly':
        // Repeats every week on the same day and at the same time
        dateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case 'none':
      default:
        // Does not repeat
        dateTimeComponents = null;
        break;
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // ✅ This is the key change to enable repeating alarms
      matchDateTimeComponents: dateTimeComponents,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

extension on AndroidFlutterLocalNotificationsPlugin? {
  Future<void> requestPermissions() async {}
}
