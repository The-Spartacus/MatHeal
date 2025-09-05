// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static late tz.Location _local;

  /// Initializes the notification service and sets the local timezone.
  /// MUST be called from main.dart at startup.
  static Future<void> init(String s, {required String timeZoneName
  ,    required Function(NotificationResponse) onDidReceiveNotificationResponse,
}) async {
    try {
      debugPrint("[NotificationService] Initializing timezone database...");
      tz.initializeTimeZones();
      _local = tz.getLocation(timeZoneName);
      tz.setLocalLocation(_local);
      debugPrint("[NotificationService] Timezone set to: ${tz.local.name}");

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(requestAlertPermission: true);

      const InitializationSettings initializationSettings =
          InitializationSettings(
              android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

            await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      );

      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
        }
      }
      debugPrint("[NotificationService] INIT COMPLETE.");
    } catch (e) {
      debugPrint("[NotificationService] FATAL ERROR during init: $e");
    }
  }

  /// Schedules a notification.
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String repeatInterval = 'none',
  }) async {
    try {
      // Create a TZDateTime object using the explicitly set local timezone
      final tz.TZDateTime scheduledTZDate =
          tz.TZDateTime.from(scheduledDate, _local);

      debugPrint(
          "[NotificationService] Scheduling notification with parameters:");
      debugPrint("  ID: $id");
      debugPrint("  Title: $title");
      debugPrint("  Scheduled Date (in ${_local.name}): $scheduledTZDate");
      debugPrint("  Repeat Interval: $repeatInterval");


  
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'matheal_reminders_channel_alarm', 'MatHeal Alarms',
          channelDescription: 'Channel for medicine and appointment alarm.',
          importance: Importance.max,
          priority: Priority.high,

          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,

        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      );

      DateTimeComponents? matchDateTimeComponents;
      if (repeatInterval == 'daily') {
        matchDateTimeComponents = DateTimeComponents.time;
      } else if (repeatInterval == 'weekly') {
        matchDateTimeComponents = DateTimeComponents.dayOfWeekAndTime;
      }

      await _notifications.zonedSchedule(
        id, title, body, scheduledTZDate,
        notificationDetails,
        payload: 'alarm',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );

      debugPrint("[NotificationService] SUCCESSFULLY SCHEDULED for $scheduledTZDate.");
    } catch (e) {
      debugPrint(
          "[NotificationService] FATAL ERROR during scheduleNotification: $e");
    }
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}

