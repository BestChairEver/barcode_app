import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/product.dart';
import '../db/database_helper.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  tz.initializeTimeZones();
}

Future<void> scheduleExpiryNotifications() async {
  final databaseHelper = DatabaseHelper();
  final products = await databaseHelper.getProducts();
  DateTime today = DateTime.now();
  DateTime tomorrow = today.add(Duration(days: 1));
  List<Product> expiringToday = products.where((product) {
    return product.expiryDate.year == today.year &&
        product.expiryDate.month == today.month &&
        product.expiryDate.day == today.day;
  }).toList();

  List<Product> expiringTomorrow = products.where((product) {
    return product.expiryDate.year == tomorrow.year &&
        product.expiryDate.month == tomorrow.month &&
        product.expiryDate.day == tomorrow.day;
  }).toList();

  if (expiringToday.isNotEmpty) {
    await _scheduleNotification(
      'Срок годности сегодня',
      'У ${expiringToday.length} продукта(ов) сегодня истекает срок годности',
      DateTime(today.year, today.month, today.day, 8),
    );
  }

  if (expiringTomorrow.isNotEmpty) {
    await _scheduleNotification(
      'Срок годности завтра',
      'У ${expiringTomorrow.length} продукта(ов) завтра истекает срок годности',
      DateTime(today.year, today.month, today.day, 8),
    );
  }
}


Future<void> _scheduleNotification(String title, String message, DateTime date) async {
  var scheduledNotificationDateTime = tz.TZDateTime.from(date, tz.local);
  var androidDetails = AndroidNotificationDetails(
    'channelId',
    'channelName',
    importance: Importance.high,
    priority: Priority.high,
  );
  var platformDetails = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    title,
    message,
    scheduledNotificationDateTime,
    platformDetails,
    uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}
Future<void> checkExpiringProducts() async {
  await scheduleExpiryNotifications();
}