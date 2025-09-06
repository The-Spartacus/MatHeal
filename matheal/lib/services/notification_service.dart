// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Centralized notification service for appointments + medicines
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static late tz.Location _local;

  /// MUST be called in main.dart before runApp()
  static Future<void> init({
    required String timeZoneName,
    required Function(NotificationResponse) onDidReceiveNotificationResponse,
  }) async {
    try {
      debugPrint("[NotificationService] Initializing...");
      tz.initializeTimeZones();
      _local = tz.getLocation(timeZoneName);
      tz.setLocalLocation(_local);

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(requestAlertPermission: true);

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );

      // Ask permissions on Android
      if (Platform.isAndroid) {
        final androidImpl = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidImpl != null) {
          await androidImpl.requestNotificationsPermission();
          await androidImpl.requestExactAlarmsPermission();
        }
      }

      debugPrint("[NotificationService] INIT COMPLETE ✅");
    } catch (e) {
      debugPrint("[NotificationService] ERROR during init: $e");
    }
  }

  /// Generic cancel notification
  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    debugPrint("[NotificationService] Canceled ID: $id");
  }

  /// Cancel all
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint("[NotificationService] All notifications canceled");
  }

  /// 🟢 Schedule an appointment reminder (one-time only)
  static Future<void> scheduleAppointment({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final scheduledTZDate = tz.TZDateTime.from(scheduledDate, _local);

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'appointments_channel',
          'Appointments',
          channelDescription: 'Doctor appointment reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDate,
        notificationDetails,
        payload: 'appointment',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint("[NotificationService] Appointment scheduled at $scheduledTZDate ✅");
    } catch (e) {
      debugPrint("[NotificationService] ERROR scheduling appointment: $e");
    }
  }

  /// 🟢 Schedule a medicine reminder (repeatable)
// lib/services/notification_service.dart
// ... inside NotificationService class
static Future<void> scheduleMedicine({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String repeatInterval = 'none', // none, daily, weekly
  required String reminderId, // ✅ Add reminderId here
}) async {
  try {
    final scheduledTZDate = tz.TZDateTime.from(scheduledDate, _local);

    DateTimeComponents? matchDateTimeComponents;
    if (repeatInterval == 'daily') {
      matchDateTimeComponents = DateTimeComponents.time;
    } else if (repeatInterval == 'weekly') {
      matchDateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'medicine_alarm_channel',
        'Medicine Alarms',
        channelDescription: 'Channel for medicine alarms with full-screen intent',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(presentSound: true),
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTZDate,
      notificationDetails,
      payload: body, // ✅ Pass the unique reminderId as the payload
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchDateTimeComponents,
    );

    debugPrint("[NotificationService] Medicine scheduled at $scheduledTZDate ✅");
  } catch (e) {
    debugPrint("[NotificationService] ERROR scheduling medicine: $e");
  }
}
}