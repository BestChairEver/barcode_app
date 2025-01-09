import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../db/database_helper.dart';
import '../models/product.dart';
import '../utils/notifications.dart';

class ProductProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  ThemeData get themeData {
    switch (_themeMode) {
      case ThemeMode.dark:
        return ThemeData.dark();
      case ThemeMode.light:
        return ThemeData.light();
      case ThemeMode.system:
      default:
        return ThemeData.fallback();
    }
  }
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'system';
    _themeMode = _getThemeModeFromString(themeModeString);
    notifyListeners();
  }

  Future<void> saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode.toString().split('.').last);
  }
  ThemeMode _getThemeModeFromString(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }


  List<Product> _products = [];
  DateTime? _lastCheckTime;

  List<Product> get products => _products;

  Duration notificationOffset = Duration(days: 1);

  Future<void> loadProducts() async {
    final databaseHelper = DatabaseHelper();
    _products = await databaseHelper.getProducts();
    _products.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    notifyListeners();
    await _checkAndScheduleNotifications();
  }

  Future<void> addProduct(Product product) async {
    final databaseHelper = DatabaseHelper();
    final id = await databaseHelper.insertProduct(product);
    product.id = id;
    _products.add(product);

    notifyListeners();
    await _scheduleNotificationsForProduct(product);
  }

  Future<void> deleteProduct(int id) async {
    final databaseHelper = DatabaseHelper();
    await databaseHelper.deleteProduct(id);
    _products.removeWhere((product) => product.id == id);
    notifyListeners();
  }

  Future<void> init() async {
    await loadProducts();
  }

  Future<void> _checkAndScheduleNotifications() async {
    final now = DateTime.now();

    if (_lastCheckTime != null &&
        now.difference(_lastCheckTime!).inMinutes < 5) {
      return;
    }

    _lastCheckTime = now;

    for (var product in _products) {
      await _scheduleNotificationsForProduct(product);
    }
  }

  Future<void> _scheduleNotificationsForProduct(Product product) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final expiryDate = DateTime(
    product.expiryDate.year,
    product.expiryDate.month,
    product.expiryDate.day,
  );

  try {
    if (expiryDate.isBefore(today)) {
      return;
    }
    final dayBeforeExpiry = expiryDate.subtract(Duration(days: 1));
    if (dayBeforeExpiry.isAfter(now)) {
      await _scheduleSingleNotification(
        product.name,
        expiryDate,
        Duration(days: 1),
      );
    }
    if (expiryDate.isAfter(now)) {
      await _scheduleSingleNotification(
        product.name,
        expiryDate,
        Duration.zero,
      );
    }
  } catch (e) {
    print("Ошибка при планировании уведомлений для продукта '${product.name}': $e");
  }
}

Future<void> _scheduleSingleNotification(
    String productName, DateTime expiryDate, Duration notificationOffset) async {
  try {
    await scheduleNotificationForProduct(productName, expiryDate);
  } catch (e) {
    print("Ошибка при планировании уведомления для \"$productName\": $e");
  }
    }}