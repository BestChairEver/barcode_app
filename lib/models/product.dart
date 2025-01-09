import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Product {
  int? id;
  String name;
  DateTime expiryDate;
  String imageUrl;

  Product({
    this.id,
    required this.name,
    required this.expiryDate,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      expiryDate: DateTime.parse(json['expiryDate']),
      imageUrl: json['imageUrl'],
    );
  }

  Future<void> scheduleNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('app_icon'),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();

    DateTime now = DateTime.now();
    DateTime expiryDate = this.expiryDate;

    if (expiryDate.isBefore(now)) {
      return;
    }

    DateTime dayBeforeExpiry = expiryDate.subtract(Duration(days: 1));
    DateTime expiryDay = expiryDate;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      "Продукт ${this.name}",
      "Продукт \"${this.name}\" истекает завтра.",
      _convertToTZ(dayBeforeExpiry),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );


    await flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      "Продукт ${this.name}",
      "Продукт \"${this.name}\" истекает сегодня.",
      _convertToTZ(expiryDay),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  tz.TZDateTime _convertToTZ(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
