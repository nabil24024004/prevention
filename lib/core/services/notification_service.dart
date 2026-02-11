import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
// ... (I need to be careful with replace, better to use multi_replace if changing import and usage)
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationsEnabledKey = 'daily_notifications_enabled';

  // Expose the plugin for advanced usage if needed
  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = fln.AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = fln.DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const settings = fln.InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');

      // If enabled in prefs, ensure they are scheduled
      if (await areNotificationsEnabled()) {
        await scheduleDailyNotifications();
      }
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Requests notification permissions from the system.
  /// Returns true if granted, false otherwise.
  Future<bool> requestPermissions() async {
    try {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin
          >();

      final bool? granted = await androidImplementation
          ?.requestNotificationsPermission();

      // Also check/request for exact alarm permission on Android 12+
      await androidImplementation?.requestExactAlarmsPermission();

      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin
          >();

      final bool? iosGranted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return granted ?? iosGranted ?? false;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  final List<String> _duasAndQuotes = [
    "Indeed, with hardship will be ease. (Quran 94:6)",
    "Do not lose hope, nor be sad. (Quran 3:139)",
    "Allah does not burden a soul beyond that it can bear. (Quran 2:286)",
    "Call upon Me; I will respond to you. (Quran 40:60)",
    "And whoever fears Allah - He will make for him a way out. (Quran 65:2)",
    "Every step away from sin is a step closer to Allah.",
    "Patience is beautiful. (Quran 12:18)",
    "Your past does not define your future.",
    "Stay strong, your journey is valid.",
    "This dunya is temporary, focus on the eternal.",
    "Turn to Allah before you return to Allah.",
    "The best sinner is the one who repents.",
    "Keep going, you are stronger than your urges.",
    "Verify your intention, purify your heart.",
    "Prayer is better than sleep.",
    "Do not despair of the mercy of Allah.",
    "Be patient, for what was written for you was written by the greatest of writers.",
    "Trust Allah's timing.",
    "Protect your gaze, protect your heart.",
    "Jannah is worth the struggle.",
  ];

  /// Shows an immediate notification with a random motivation.
  /// Intended to be called when the app is opened/resumed.
  Future<void> showMotivationalNotification() async {
    if (!await areNotificationsEnabled()) return;

    try {
      final randomQuote =
          _duasAndQuotes[Random().nextInt(_duasAndQuotes.length)];

      const androidDetails = fln.AndroidNotificationDetails(
        'immediate_motivation_channel',
        'Instant Motivation',
        channelDescription: 'Motivational quotes shown on app open',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
      );

      const details = fln.NotificationDetails(
        android: androidDetails,
        iOS: fln.DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        999, // Fixed ID for instant notifications, replaces previous
        'Daily Reminder',
        randomQuote,
        details,
      );
      debugPrint('Instant motivational notification shown');
    } catch (e) {
      debugPrint('Error showing immediate notification: $e');
    }
  }

  /// Shows an immediate test notification.
  Future<void> showTestNotification() async {
    try {
      const androidDetails = fln.AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for testing notifications',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
      );

      const details = fln.NotificationDetails(
        android: androidDetails,
        iOS: fln.DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.show(
        888,
        'Test Notification',
        'If you can see this, notifications are working! 🚀',
        details,
      );
      debugPrint('Test notification sent');
    } catch (e) {
      debugPrint('Error showing test notification: $e');
      rethrow;
    }
  }

  Future<void> scheduleDailyNotifications() async {
    // Only schedule if actually enabled
    if (!await areNotificationsEnabled()) {
      debugPrint('Skipping schedule: Notifications disabled in settings');
      return;
    }

    try {
      // Cancel existings to start fresh
      await flutterLocalNotificationsPlugin.cancelAll();

      // Schedule 3 notifications per day: 8 AM, 4 PM, 9 PM
      await _scheduleAtTime(8, 0, 1);
      await _scheduleAtTime(16, 0, 2);
      await _scheduleAtTime(21, 0, 3);

      debugPrint('Daily notifications scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling daily notifications: $e');
    }
  }

  Future<void> _scheduleAtTime(int hour, int minute, int id) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final randomQuote =
          _duasAndQuotes[Random().nextInt(_duasAndQuotes.length)];

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Daily Reminder',
        randomQuote,
        scheduledDate,
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'daily_motivation_channel',
            'Daily Motivation',
            channelDescription: 'Motivational quotes and duas',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.time,
      );
      debugPrint('Scheduled notification $id for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling specific notification $id: $e');
    }
  }

  /// Check if daily notifications are enabled in app preferences
  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// Enable or disable daily notifications
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      // When enabling, first request permissions if not granted
      await requestPermissions();
      await scheduleDailyNotifications();
      debugPrint('Daily notifications enabled and scheduled');
    } else {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('All notifications cancelled (disabled)');
    }
  }
}
