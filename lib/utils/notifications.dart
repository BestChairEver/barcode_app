import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';

final random = Random();
final notificationId = random.nextInt(100000);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);


  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'expiry_channel',
    'Продукты с истекающим сроком', 
    description: 'Напоминания о продуктах с истекающим сроком годности',
    importance: Importance.high, 
    playSound: true, 
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  print("Уведомления инициализированы.");

  tz.initializeTimeZones();
  final String timeZoneName = tz.local.name;
  tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
  print("Таймзона настроена: $timeZoneName");
}

Future<void> scheduleNotificationForProduct(
  String productName, 
  DateTime expiryDate,
) async {
  print("Планирование уведомления для продукта: $productName");

  final now = DateTime.now();
  final expiryDateWithoutTime = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
  print("Текущее время: $now");
  print("Дата истечения срока годности (без времени): $expiryDateWithoutTime");

  if (expiryDate.isBefore(now)) {
    print("Пропущено: срок годности продукта '$productName' уже истек.");
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final notificationHour = prefs.getInt('notificationTimeHour') ?? 8;
  final notificationMinute = prefs.getInt('notificationTimeMinute') ?? 0;

  final notificationTime = DateTime(
    expiryDateWithoutTime.year,
    expiryDateWithoutTime.month,
    expiryDateWithoutTime.day,
    notificationHour,
    notificationMinute,
  );

  if (notificationTime.isBefore(now)) {
    print("Пропущено: уведомление для продукта '$productName' уже не актуально.");
    return;
  }

  final tz.TZDateTime scheduleTime = tz.TZDateTime.from(notificationTime, tz.local);
  print("Запланированное время уведомления: $scheduleTime");

  const NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'expiry_channel',
      'Продукты с истекающим сроком',
      channelDescription: 'Напоминания о продуктах с истекающим сроком годности',
      importance: Importance.max,
      priority: Priority.high,
    ),
  );

  try {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      random.nextInt(100000),
      'Продукт скоро испортится!',
      'Проверьте продукт: $productName',
      scheduleTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
    print("Уведомление для продукта '$productName' успешно запланировано.");
  } catch (e) {
    print("Ошибка при планировании уведомления: $e");
  }
}