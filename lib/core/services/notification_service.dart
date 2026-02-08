import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    debugPrint('NotificationService initialized');

    // Request permissions specifically for Android 13+
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    
    final bool? granted = await androidImplementation?.requestNotificationsPermission();
    debugPrint('Notification permission granted: $granted');
    
    // Also check for exact alarm permission which is required for scheduled notifications on Android 12+
    await androidImplementation?.requestExactAlarmsPermission();
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
    try {
      final randomQuote = _duasAndQuotes[Random().nextInt(_duasAndQuotes.length)];
      
      const androidDetails = AndroidNotificationDetails(
        'immediate_motivation_channel',
        'Instant Motivation',
        channelDescription: 'Motivational quotes shown on app open',
        importance: Importance.max,
        priority: Priority.high,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await _notifications.show(
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

  Future<void> scheduleDailyNotifications() async {
    try {
      // Cancel existing to avoid duplicates
      await _notifications.cancelAll();
      debugPrint('Cancelled all previous notifications');

      // Schedule 3 notifications per day
      await _scheduleAtTime(8, 0, 1);
      await _scheduleAtTime(16, 0, 2);
      await _scheduleAtTime(21, 0, 3);
      debugPrint('Scheduled daily notifications');
    } catch (e) {
      debugPrint('Error scheduling notifications: $e');
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

      final randomQuote = _duasAndQuotes[Random().nextInt(_duasAndQuotes.length)];

      await _notifications.zonedSchedule(
        id,
        'Daily Reminder',
        randomQuote,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_motivation_channel',
            'Daily Motivation',
            channelDescription: 'Motivational quotes and duas',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('Scheduled notification $id for $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }
}
