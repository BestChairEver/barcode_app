import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Product {
  String name;
  DateTime expiryDate;

  Product(this.name, this.expiryDate);
}


class NotificationService {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Future<void> initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = 
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
      },
    );

    tz.initializeTimeZones();
  }

Future<void> scheduleNotificationsForProducts(List<Product> products) async {
    await cancelAllNotifications();
    await initializeNotifications();
    await scheduleExpiryNotifications(products);
  }


Future<void> scheduleExpiryNotifications(List<Product> products) async {
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Moscow')); 

      final now = tz.TZDateTime.now(tz.local);
      print('Current time (local): $now');

      for (var product in products) {
        // Создаем время напоминания за день до истечения срока
        final reminderTime = product.expiryDate.subtract(const Duration(days: 1));
        final tzReminderTime = tz.TZDateTime.local(
          reminderTime.year,
          reminderTime.month,
          reminderTime.day,
          9, // Время напоминания - 9 утра
          0,
        );

        print('Product: ${product.name}');
        print('Expiry date: ${product.expiryDate}');
        print('Reminder time: $tzReminderTime');

        // Проверяем, что время напоминания в будущем
        if (tzReminderTime.isAfter(now)) {
          await _scheduleNotification(
            tzReminderTime, 
            'Истекает срок годности', 
            'Продукт ${product.name} скоро испортится'
          );
        } else {
          print('Reminder time is not in the future, skipping notification');
        }
      }
    } catch (e) {
      print('Error in scheduling notifications: $e');
    }
  }

Future<void> _scheduleNotification(
  tz.TZDateTime scheduledTime,
  String title,
  String body,
) async {
  final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'expiry_channel_id',
    'Срок годности',
    channelDescription: 'Уведомления о сроках годности продуктов',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iOSDetails,
  );

  try {
    print('Scheduling notification');
    print('Scheduled time: $scheduledTime');
    print('Current time: ${tz.TZDateTime.now(tz.local)}');

    await flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledTime,
      platformDetails,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print('Notification scheduled successfully');
  } catch (e) {
    print('Error scheduling notification: $e');
  }
}
 // Отмена всех уведомлений
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("All notifications cancelled.");
  }

  // Отмена конкретного уведомления
  Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
    print("Notification with ID $notificationId cancelled.");
  }
    // Метод для немедленной отправки уведомления (для теста)
  Future<void> showImmediateNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'expiry_channel_id',
      'Срок годности',
      channelDescription: 'Уведомления о сроках годности продуктов',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, 
      'Тестовое уведомление', 
      'Это проверка работы уведомлений', 
      platformDetails
    );
  }
  
}
