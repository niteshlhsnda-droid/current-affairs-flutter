// Daily study reminder via a local notification.
// Scheduled with inexact timing so no exact-alarm permission is needed.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    // The audience is Indian exam aspirants: pin the schedule to
    // Asia/Kolkata so the reminder fires at the right local time even
    // if the device timezone is misconfigured.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (_) {},
    );
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'daily_digest',
        'Daily current affairs reminder',
        description: 'Reminds you to read the day\'s current affairs digest',
        importance: Importance.high,
      ),
    );
    _ready = true;
  }

  Future<void> scheduleDaily(int minutesAfterMidnight) async {
    await init();
    await _plugin.cancel(7);
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      minutesAfterMidnight ~/ 60,
      minutesAfterMidnight % 60,
    );
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      7,
      '📰 Today\'s current affairs are here',
      'Your exam-ready digest — stories, rapid-fire one-liners and a 10-question quiz.',
      when,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_digest',
          'Daily current affairs reminder',
          channelDescription:
              'Reminds you to read the day\'s current affairs digest',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancel() async {
    await init();
    await _plugin.cancel(7);
  }
}
