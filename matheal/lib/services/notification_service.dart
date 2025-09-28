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

  // --- vvv UPDATED/NEW METHODS START HERE vvv ---

  /// 🟢 Schedules a potentially repeating medicine reminder for specific days of the week.
  static Future<void> scheduleMedicineNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required int hour,
    required int minute,
    required DateTime startDate,
    DateTime? endDate,
    required List<int> days, // 1 for Monday, 7 for Sunday
  }) async {
    try {
      // Find the next valid instance to schedule the notification
      final tz.TZDateTime nextInstance = _getNextScheduledInstance(
        hour: hour,
        minute: minute,
        startDate: startDate,
        days: days,
      );

      // If an end date is specified, don't schedule if we are past it
      if (endDate != null && nextInstance.isAfter(endDate)) {
        debugPrint("[NotificationService] First instance is after end date. Skipping schedule.");
        return;
      }

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_alarm_channel',
          'Medicine Alarms',
          channelDescription: 'Channel for medicine alarms and reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: RawResourceAndroidNotificationSound('medicine_alarm'), // Assuming 'medicine_alarm.mp3' is in android/app/src/main/res/raw/

        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        nextInstance,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        // This is the key for weekly repeats on specific days
        matchDateTimeComponents: days.isNotEmpty 
            ? DateTimeComponents.dayOfWeekAndTime 
            : DateTimeComponents.time,
      );
      
      debugPrint("[NotificationService] Medicine scheduled for next instance at $nextInstance ✅");

    } catch (e) {
      debugPrint("[NotificationService] ERROR scheduling medicine: $e");
    }
  }

  /// Helper function to calculate the next valid date and time for a reminder.
  static tz.TZDateTime _getNextScheduledInstance({
    required int hour,
    required int minute,
    required DateTime startDate,
    required List<int> days,
  }) {
    tz.TZDateTime now = tz.TZDateTime.now(_local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(_local, startDate.year, startDate.month, startDate.day, hour, minute);

    // If the start date is in the past, start checking from today
    if (scheduledDate.isBefore(now)) {
      scheduledDate = tz.TZDateTime(_local, now.year, now.month, now.day, hour, minute);
    }
    
    // If scheduling for specific days of the week
    if (days.isNotEmpty) {
      // Keep adding days until we find a day that is in our list of valid days
      while (!days.contains(scheduledDate.weekday)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
    }
    
    // If the calculated time is still in the past (for today), move to the next valid day
    if (scheduledDate.isBefore(now)) {
       scheduledDate = scheduledDate.add(const Duration(days: 1));
       if (days.isNotEmpty) {
         while (!days.contains(scheduledDate.weekday)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
       }
    }

    return scheduledDate;
  }
}