import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:stepz_attendance/features/employee/presentation/controllers/employee_dashboard_controller.dart';

@pragma('vm:entry-point')
Future<void> geofenceTriggerCallback(GeofenceCallbackParams params) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final event = params.event;
  final hasOfficeGeofence = params.geofences.any((g) => g.id == 'office_geofence');
  if (!hasOfficeGeofence) {
    debugPrint('--- BACKGROUND GEOFENCE TRIGGERED: ${event.toString()} for non-office geofences ---');
    return;
  }
  
  debugPrint('--- BACKGROUND GEOFENCE TRIGGERED: ${event.toString()} for zone: office_geofence ---');

  final prefs = await SharedPreferences.getInstance();
  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 1. Handle Geofence Entry
  if (event == GeofenceEvent.enter) {
    // Save current status: inside office
    await prefs.setBool('is_currently_inside_geofence', true);
    await prefs.setString('last_geofence_entry_time', DateTime.now().toIso8601String());

    // Check configuration preferences
    final bool geofenceEnabled = prefs.getBool('geofence_notification_enabled') ?? true;
    final bool attendanceReminderEnabled = prefs.getBool('attendance_reminder_enabled') ?? true;

    if (geofenceEnabled) {
      // Rule 2: If employee already checked in today, never show notification
      final String checkedInDate = prefs.getString('checked_in_today_date') ?? '';
      if (checkedInDate != todayStr) {
        // Rule 1 & 3: Reset notification status automatically at midnight (shown once per day)
        final String lastGeofenceDate = prefs.getString('last_geofence_notification_date') ?? '';
        if (lastGeofenceDate != todayStr) {
          await _showLocalNotification(
            id: 999,
            title: 'Welcome to STEPZ Invention 👋',
            body: 'You are inside the office area. Please mark your attendance.',
            payload: 'punch_in',
            actionText: 'Punch In Now',
          );
          await prefs.setString('last_geofence_notification_date', todayStr);
        }
      }
    }

    // Schedule Morning Reminder if before 09:15 AM and enabled
    if (attendanceReminderEnabled) {
      final String checkedInDate = prefs.getString('checked_in_today_date') ?? '';
      if (checkedInDate != todayStr) {
        final now = DateTime.now();
        
        // Parse morning time from admin settings in SharedPreferences (default 09:15 AM)
        final String morningTimeStr = prefs.getString('morning_reminder_time') ?? '09:15 AM';
        try {
          final parts = morningTimeStr.split(' ');
          final timeParts = parts[0].split(':');
          int hour = int.parse(timeParts[0]);
          final int minute = int.parse(timeParts[1]);
          final String ampm = parts[1].toUpperCase();

          if (ampm == 'PM' && hour != 12) {
            hour += 12;
          } else if (ampm == 'AM' && hour == 12) {
            hour = 0;
          }

          final morningReminderTime = DateTime(now.year, now.month, now.day, hour, minute);
          
          if (now.isBefore(morningReminderTime)) {
            debugPrint('Scheduling background morning reminder for: $morningReminderTime');
            await _scheduleLocalNotification(
              id: 101,
              title: 'Attendance Reminder',
              body: 'Good Morning 👋\nYou are in the office. Please mark your attendance.',
              scheduledTime: morningReminderTime,
              payload: 'punch_in',
            );
          }
        } catch (e) {
          debugPrint('Error scheduling morning reminder in background: $e');
        }
      }
    }
  }

  // 2. Handle Geofence Exit
  if (event == GeofenceEvent.exit) {
    await prefs.setBool('is_currently_inside_geofence', false);
    debugPrint('Exited geofence. Cancelling scheduled morning reminder.');
    // Cancel Morning Reminder since they left the office area
    await _cancelNotification(101);
  }
}

// Background Helper: Show immediately
Future<void> _showLocalNotification({
  required int id,
  required String title,
  required String body,
  required String payload,
  required String actionText,
}) async {
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await localNotifications.initialize(
    settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  final androidDetails = AndroidNotificationDetails(
    'geofence_reminder_channel',
    'Geofence Reminders',
    channelDescription: 'Channel for geofence entry and checkout reminders',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    actions: <AndroidNotificationAction>[
      AndroidNotificationAction(
        payload,
        actionText,
        showsUserInterface: true,
      ),
    ],
  );
  
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  await localNotifications.show(
    id: id,
    title: title,
    body: body,
    notificationDetails: details,
    payload: payload,
  );
}

// Background Helper: Schedule at specific time
Future<void> _scheduleLocalNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledTime,
  required String payload,
}) async {
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await localNotifications.initialize(
    settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  tz.initializeTimeZones();
  String timeZoneName = 'UTC';
  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    timeZoneName = timezoneInfo.identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (_) {}

  final androidDetails = AndroidNotificationDetails(
    'scheduled_reminder_channel',
    'Scheduled Reminders',
    channelDescription: 'Channel for morning and evening scheduled reminders',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
  
  await localNotifications.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
    notificationDetails: details,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: payload,
  );
}

// Background Helper: Cancel scheduled
Future<void> _cancelNotification(int id) async {
  final localNotifications = FlutterLocalNotificationsPlugin();
  await localNotifications.cancel(id: id);
}

class GeofenceReminderService extends GetxService {
  static GeofenceReminderService get to => Get.find();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<GeofenceReminderService> init() async {
    if (_isInitialized) return this;

    // Initialize timezones for scheduled notifications
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('GeofenceReminderService Timezone initialized to: $timeZoneName');
    } catch (e) {
      debugPrint('GeofenceReminderService failed to load local timezone: $e');
    }

    // Initialize local notifications plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint('GeofenceReminderService Local Notifications Initialized.');

    // Schedule Mon-Sat 9:20 AM / 5:00 PM reminders
    await scheduleWorkingDaysReminders();

    return this;
  }

  Future<void> scheduleWorkingDaysReminders() async {
    try {
      // Cancel old daily reminders first (IDs 201-206 for morning, 301-306 for evening)
      for (int i = 1; i <= 6; i++) {
        await _localNotifications.cancel(id: 200 + i);
        await _localNotifications.cancel(id: 300 + i);
      }

      final androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'Daily Reminders',
        channelDescription: 'Channel for daily punch-in and punch-out reminders',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      );
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final days = [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
        DateTime.saturday,
      ];

      final now = tz.TZDateTime.now(tz.local);

      for (var day in days) {
        // 1. Morning Punch In at 9:20 AM
        var scheduledMorning = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          9, // 9 AM
          20, // 20 minutes
        );
        while (scheduledMorning.weekday != day) {
          scheduledMorning = scheduledMorning.add(const Duration(days: 1));
        }
        if (scheduledMorning.isBefore(now)) {
          scheduledMorning = scheduledMorning.add(const Duration(days: 7));
        }

        await _localNotifications.zonedSchedule(
          id: 200 + day,
          title: 'Punch In Reminder ⏰',
          body: 'Good morning! 9:30 AM is your check-in time. This is a reminder to check in.',
          scheduledDate: scheduledMorning,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'punch_in',
        );

        // 2. Evening Punch Out at 5:00 PM (17:00)
        var scheduledEvening = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          17, // 5 PM
          0, // 0 minutes
        );
        while (scheduledEvening.weekday != day) {
          scheduledEvening = scheduledEvening.add(const Duration(days: 1));
        }
        if (scheduledEvening.isBefore(now)) {
          scheduledEvening = scheduledEvening.add(const Duration(days: 7));
        }

        await _localNotifications.zonedSchedule(
          id: 300 + day,
          title: 'Punch Out Reminder ⏰',
          body: '5:30 PM is your check-out time. This is a reminder for check-out.',
          scheduledDate: scheduledEvening,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'checkout',
        );
      }
      debugPrint('Scheduled working days reminders for Mon-Sat (9:20 AM and 5:00 PM).');
    } catch (e) {
      debugPrint('Error scheduling working days reminders: $e');
    }
  }

  // Handle notification or notification action tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local Notification tapped with payload: ${response.payload}');
    
    // Both actions should open the Attendance Center (Home Screen tab 0)
    // Tapping notification automatically wakes up/opens app. 
    // Redirect to employee dashboard and switch to Home (tab 0).
    if (Get.isRegistered<EmployeeDashboardController>()) {
      final controller = Get.find<EmployeeDashboardController>();
      controller.activeTabIndex.value = 0;
      controller.useRealLocation(); // Refresh location to allow check in/out immediately
    }
    
    Get.toNamed('/employee/dashboard');
  }

  // Request all necessary permissions for local notifications and geofencing
  Future<bool> requestPermissions() async {
    try {
      // 1. Notification Permission (Android 13+)
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
      
      final iosPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error requesting notifications permissions: $e');
      return false;
    }
  }

  // Registers the native office geofence with OS
  Future<void> registerOfficeGeofence({
    required double latitude,
    required double longitude,
    required double radius,
    required bool enabled,
  }) async {
    // Remove old geofence first
    try {
      await NativeGeofenceManager.instance.removeGeofenceById('office_geofence');
    } catch (_) {}

    if (!enabled || latitude == 0.0 || longitude == 0.0) {
      debugPrint('Office geofence registration skipped (disabled or invalid coords)');
      return;
    }

    final geofence = Geofence(
      id: 'office_geofence',
      location: Location(latitude: latitude, longitude: longitude),
      radiusMeters: radius,
      triggers: {GeofenceEvent.enter, GeofenceEvent.exit},
      iosSettings: const IosGeofenceSettings(initialTrigger: true),
      androidSettings: const AndroidGeofenceSettings(
        initialTriggers: {GeofenceEvent.enter, GeofenceEvent.exit},
      ),
    );

    try {
      await NativeGeofenceManager.instance.createGeofence(
        geofence,
        geofenceTriggerCallback,
      );
      debugPrint('Office Geofence successfully registered: Lat=$latitude, Lng=$longitude, Rad=$radius');
    } catch (e) {
      debugPrint('Error creating geofence region: $e');
    }
  }

  // Schedule Evening Checkout Reminder (05:30 PM)
  Future<void> scheduleEveningCheckoutReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('checkout_reminder_enabled') ?? true;
    if (!enabled) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('checked_in_today_date', todayStr);

    final String checkoutTimeStr = prefs.getString('checkout_reminder_time') ?? '05:30 PM';
    try {
      final parts = checkoutTimeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String ampm = parts[1].toUpperCase();

      if (ampm == 'PM' && hour != 12) {
        hour += 12;
      } else if (ampm == 'AM' && hour == 12) {
        hour = 0;
      }

      final now = DateTime.now();
      final checkoutReminderTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Only schedule if 5:30 PM is in the future
      if (now.isBefore(checkoutReminderTime)) {
        debugPrint('Scheduling Evening Checkout Reminder for: $checkoutReminderTime');
        
        final androidDetails = AndroidNotificationDetails(
          'scheduled_reminder_channel',
          'Scheduled Reminders',
          channelDescription: 'Channel for morning and evening scheduled reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'checkout',
              'Checkout Now',
              showsUserInterface: true,
            ),
          ],
        );
        
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        );

        final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

        await _localNotifications.zonedSchedule(
          id: 102, // Checkout Reminder ID
          title: 'Checkout Reminder',
          body: 'Your workday is complete. Please mark your checkout.',
          scheduledDate: tz.TZDateTime.from(checkoutReminderTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'checkout',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling checkout reminder: $e');
    }
  }

  // Cancel Evening Checkout Reminder (when employee checks out)
  Future<void> cancelEveningCheckoutReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('checked_out_today_date', todayStr);
    
    debugPrint('Cancelling Evening Checkout Reminder');
    await _localNotifications.cancel(id: 102);
  }

  // Schedule Morning Reminder (called from app foreground if they open app in office and aren't checked in yet)
  Future<void> scheduleMorningReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final bool enabled = prefs.getBool('attendance_reminder_enabled') ?? true;
    if (!enabled) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String checkedInDate = prefs.getString('checked_in_today_date') ?? '';
    if (checkedInDate == todayStr) return;

    final String morningTimeStr = prefs.getString('morning_reminder_time') ?? '09:15 AM';
    try {
      final parts = morningTimeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final String ampm = parts[1].toUpperCase();

      if (ampm == 'PM' && hour != 12) {
        hour += 12;
      } else if (ampm == 'AM' && hour == 12) {
        hour = 0;
      }

      final now = DateTime.now();
      final morningReminderTime = DateTime(now.year, now.month, now.day, hour, minute);

      if (now.isBefore(morningReminderTime)) {
        debugPrint('Scheduling Morning Attendance Reminder for: $morningReminderTime');
        
        final androidDetails = AndroidNotificationDetails(
          'scheduled_reminder_channel',
          'Scheduled Reminders',
          channelDescription: 'Channel for morning and evening scheduled reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          actions: <AndroidNotificationAction>[
            const AndroidNotificationAction(
              'punch_in',
              'Punch In Now',
              showsUserInterface: true,
            ),
          ],
        );
        
        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        );

        final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

        await _localNotifications.zonedSchedule(
          id: 101, // Morning Reminder ID
          title: 'Attendance Reminder',
          body: 'Good Morning 👋\nYou are in the office. Please mark your attendance.',
          scheduledDate: tz.TZDateTime.from(morningReminderTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'punch_in',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling morning reminder: $e');
    }
  }

  // Cancel Morning Reminder (when employee checks in or exits geofence)
  Future<void> cancelMorningReminder() async {
    debugPrint('Cancelling Morning Attendance Reminder');
    await _localNotifications.cancel(id: 101);
  }
}
