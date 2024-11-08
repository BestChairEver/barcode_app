import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/product_provider.dart';
import '../utils/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _vibrationEnabled = true;
  TimeOfDay? _notificationTime = TimeOfDay(hour: 9, minute: 0);
  ThemeMode _themeMode = ThemeMode.light;

  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _initializeNotifications();
    _loadSettings();
  }

  // Инициализация уведомлений
  Future<void> _initializeNotifications() async {
    await _notificationService.initializeNotifications();
    tz.initializeTimeZones();
  }

  // Загрузка настроек из SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
    });
  }

  void _setNotificationTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _notificationTime!,
    );

    if (picked != null && picked != _notificationTime) {
      setState(() {
        _notificationTime = picked;
      });

      final now = DateTime.now();
      final scheduledTime = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      print("Notification time set to: ${scheduledTime.toString()}");

      final tzScheduledTime = tz.TZDateTime.local(scheduledTime.year, scheduledTime.month, scheduledTime.day, scheduledTime.hour, scheduledTime.minute);

      print("Scheduling notification for (TZ): ${tzScheduledTime.toString()}");
      if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        print("Scheduled time is in the past. Skipping notification.");
        return;
      }

      // Отмена старых уведомлений и планирование нового
      await _notificationService.cancelAllNotifications();
      // Передаем нужный параметр (например, список продуктов) или используем время уведомления
      await _notificationService.scheduleExpiryNotifications([]);  // Передать пустой список, если просто время нужно
    }
  }

  void _toggleTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
    Provider.of<ProductProvider>(context, listen: false).setThemeMode(themeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки'),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text('Тема приложения'),
                    trailing: DropdownButton<ThemeMode>(
                      value: _themeMode,
                      onChanged: (ThemeMode? newMode) {
                        if (newMode != null) _toggleTheme(newMode);
                      },
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Светлая'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Темная'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('Системная'),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  SwitchListTile(
                    title: Text('Уведомления'),
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _notificationsEnabled = value;
                      });

                      if (_notificationsEnabled) {
                        final now = DateTime.now();
                        final scheduledDateTime = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          _notificationTime!.hour,
                          _notificationTime!.minute,
                        );
                        print("Notification time set to: ${scheduledDateTime.toString()}");

                        final tzScheduledTime = tz.TZDateTime.local(
                          scheduledDateTime.year,
                          scheduledDateTime.month,
                          scheduledDateTime.day,
                          scheduledDateTime.hour,
                          scheduledDateTime.minute,
                        );

                        if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
                          print("Scheduled time is in the past. Skipping notification.");
                        } else {
                          // Планирование уведомлений с учетом нового времени
                          await _notificationService.scheduleExpiryNotifications([]); // Передаем пустой список
                        }
                      } else {
                        await _notificationService.cancelAllNotifications();
                      }
                    },
                  ),
                  Divider(),
                  SwitchListTile(
                    title: Text('Вибрация'),
                    value: _vibrationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _vibrationEnabled = value;
                      });
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Время уведомления'),
                    trailing: Text(
                      '${_notificationTime!.hour}:${_notificationTime!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 18),
                    ),
                    onTap: () => _setNotificationTime(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
