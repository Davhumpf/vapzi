import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  Future<void> init() async {
    if (ready) return;
    tz.initializeTimeZones();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
    await plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    ready = true;
  }

  Future<void> schedule(int id, DateTime date, String body) async {
    await init();
    final at = tz.TZDateTime.from(
      DateTime(date.year, date.month, date.day, 9),
      tz.local,
    );
    if (at.isBefore(tz.TZDateTime.now(tz.local))) return;
    await plugin.zonedSchedule(
      id,
      'Cobro pendiente',
      body,
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'collections',
          'Cobros',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> cancel(int id) => plugin.cancel(id);
}
