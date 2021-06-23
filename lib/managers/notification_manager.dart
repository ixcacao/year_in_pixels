
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:rxdart/rxdart.dart';
//int notifHour = 6;
//int notifMinute = 0;
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
String selectedNotificationPayload;
final BehaviorSubject<String> selectNotificationSubject = BehaviorSubject<String>();
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject = BehaviorSubject<ReceivedNotification>();

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}
initializeNotifs(notifHour, notifMinute) async {
  await _configureLocalTimeZone();
  print("local timezone configured");
                                                                                                    //filename
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('hexagonal');

  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid,);
  print('initialization settings initialized');
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectedNotificationPayload = payload;
        selectNotificationSubject.add(payload);
      });

  print("notifications fully initialized");
  if(notifHour != null && notifMinute != null){
    await scheduleDailyNotification(notifHour, notifMinute);
  }

}

Future<void> _configureLocalTimeZone() async {
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}

Future<void> scheduleDailyNotification(notifHour, notifMinute) async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Hi there!',
      'Daily practice is proven to increase your skill level.',
      _nextInstanceOfTime(notifHour, notifMinute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'daily notification channel id',
            'daily notification channel name',
            'daily notification description'),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time);
}

//creates tz.TZDateTime with present date, gets scheduled date which is I guess 10 AM????
//if scheduled date is before the present, add another day
tz.TZDateTime _nextInstanceOfTime(notifHour, notifMinute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, notifHour, notifMinute);

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}