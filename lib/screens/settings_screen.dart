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

  1. Мы уважаем вашу конфиденциальность и принимаем все необходимые меры для защиты ваших личных данных в соответствии с действующим законодательством Российской Федерации.

  2. Данные, которые вы вводите в приложении, сохраняются исключительно на вашем устройстве и используются только для предоставления услуг в рамках данного приложения. Мы не осуществляем сбор и обработку данных, которые не являются необходимыми для функционирования приложения.

  3. Приложение не собирает и не передает вашу личную информацию третьим лицам без вашего предварительного согласия, за исключением случаев, предусмотренных законодательством Российской Федерации.

  4. Мы используем уведомления для напоминания о сроках годности продуктов. Вы имеете возможность настраивать параметры уведомлений в разделе настроек приложения.

  5. Время, которое вы устанавливаете для уведомлений, сохраняется на вашем устройстве и используется исключительно в рамках данного приложения.

  6. Мы применяем стандартные методы и технологии для обеспечения безопасности ваших данных, включая шифрование и защиту от несанкционированного доступа.

  7. Данное приложение не собирает персональные данные, не использует файлы cookie или трекинг-данные, за исключением случаев, когда это необходимо для выполнения функций приложения.

  8. Вы имеете право в любой момент отозвать свое согласие на обработку ваших данных, удалив приложение с вашего устройства. После удаления приложения все данные, связанные с вашим использованием, будут удалены.

  9. Используя данное приложение, вы подтверждаете свое согласие с настоящей Политикой конфиденциальности. Если вы не согласны с условиями данной Политики, пожалуйста, не используйте приложение.

  10. Для получения дополнительной информации или в случае возникновения вопросов, пожалуйста, свяжитесь с нами по адресу электронной почты: Denn100500@yandex.ru.
  ''';
}
}
