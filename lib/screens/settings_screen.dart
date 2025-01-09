import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotificationsEnabled = false;
  TimeOfDay _notificationTime = TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationsEnabled = prefs.getBool('isNotificationsEnabled') ?? true;
      final hour = prefs.getInt('notificationTimeHour') ?? 8;
      final minute = prefs.getInt('notificationTimeMinute') ?? 0;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationsEnabled', _isNotificationsEnabled);
    await prefs.setInt('notificationTimeHour', _notificationTime.hour);
    await prefs.setInt('notificationTimeMinute', _notificationTime.minute);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Настройки"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            ListTile(
              title: Text('Тема'),
              trailing: DropdownButton<ThemeMode>(
                value: themeProvider.themeMode,
                items: ThemeMode.values.map((ThemeMode mode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Text(_getThemeModeName(mode)),
                  );
                }).toList(),
                onChanged: (ThemeMode? value) {
                  if (value != null) {
                    themeProvider.setTheme(value);
                    _saveThemeMode(value);
                  }
                },
              ),
            ),
            SwitchListTile(
              title: Text('Включить уведомления'),
              value: _isNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _isNotificationsEnabled = value;
                  _saveSettings();
                });
              },
            ),
            if (_isNotificationsEnabled)
              ListTile(
                title: Text('Время уведомления'),
                subtitle: Text('${_notificationTime.format(context)}'),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () async {
                    final newTime = await showTimePicker(
                      context: context,
                      initialTime: _notificationTime,
                    );

                    if (newTime != null) {
                      setState(() {
                        _notificationTime = newTime;
                        _saveSettings();
                      });
                    }
                  },
                ),
              ),
            ListTile(
              title: Text('Политика конфиденциальности'),
              onTap: () {
                _showPrivacyPolicy(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Тёмная';
      case ThemeMode.light:
        return 'Светлая';
      case ThemeMode.system:
      default:
        return 'Системная';
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.toString().split('.').last);
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Политика конфиденциальности"),
          content: SingleChildScrollView(
            child: Text(_privacyPolicyText),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  String get _privacyPolicyText {
    return '''
    Политика конфиденциальности для приложения по отслеживанию срока годности продуктов.

    1. Мы уважаем вашу конфиденциальность и принимаем меры для защиты ваших личных данных.
    
    2. Данные, которые вы вводите в приложении (например, информация о продуктах), сохраняются на вашем устройстве и используются только для предоставления услуг в рамках данного приложения.
    
    3. Приложение не собирает и не передает вашу личную информацию третьим сторонам без вашего согласия.
    
    4. Мы используем уведомления для напоминания о сроках годности продуктов, и вы можете настроить их в разделе настроек.
    
    5. Время, которое вы устанавливаете для уведомлений, сохраняется на устройстве и используется только в рамках приложения.
    
    6. Мы используем стандартные методы для обеспечения безопасности ваших данных.
    
    7. Это приложение не собирает персональные данные, не использует файлы cookie или трекинг-данные.

    8. Для получения дополнительной информации, пожалуйста, свяжитесь с нами по адресу электронной почты. (Denn100500@yandex.ru)
    ''';
  }
}
