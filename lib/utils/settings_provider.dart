import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  TimeOfDay _notificationTime = TimeOfDay(hour: 9, minute: 0);
  bool _someOtherSetting = false;

  ThemeMode get themeMode => _themeMode;
  TimeOfDay get notificationTime => _notificationTime;
  bool get someOtherSetting => _someOtherSetting;

  void updateThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void updateNotificationTime(TimeOfDay time) {
    _notificationTime = time;
    notifyListeners();
  }

  void toggleOtherSetting(bool value) {
    _someOtherSetting = value;
    notifyListeners();
  }
}
