import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(settings);
    
    // Request permissions specifically for Android 13+
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
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
    "Jannah is worth the struggle."
  ];

  Future<void> scheduleDailyNotifications() async {
    // Cancel existing to avoid duplicates
    await _notifications.cancelAll();

    // Schedule 3 notifications per day (every 8 hours approx)
    // For simplicity, we'll schedule a recurring notification interval or just periodic.
    // Periodic is limited on Android.
    // Better to schedule a few discrete times or use `periodicallyShow` with RepeatInterval.everyMinute for testing?
    // No, RepeatInterval.daily is too slow. RepeatInterval is limited.
    // Let's use zonedSchedule for 8am, 4pm, 12am roughly? 
    // Or just "Every 8 hours" using RepeatInterval? local_notifications doesn't have "Every 8 hours".
    // It has `everyMinute`, `hourly`, `daily`, `weekly`.
    
    // So we will schedule 3 fixed times for "Daily" checks.
    // 8:00 AM
    // 4:00 PM
    // 9:00 PM
    
    await _scheduleAtTime(8, 0, 1);
    await _scheduleAtTime(16, 0, 2);
    await _scheduleAtTime(21, 0, 3);
  }

  Future<void> _scheduleAtTime(int hour, int minute, int id) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Pick a random quote
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
      matchDateTimeComponents: DateTimeComponents.time, // Repeats every day at this time
    );
  }
}
