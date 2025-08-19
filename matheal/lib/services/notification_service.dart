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
          ?.requestNotificationsPermission();
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

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}