import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/notifications.dart';
import 'utils/product_provider.dart';

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.request();
  if (status.isGranted) {
    print('Permission granted');
  } else if (status.isDenied) {
    print('Permission denied');
  } else if (status.isPermanentlyDenied) {
    print('Permission permanently denied');
    openAppSettings();
  }
}

void main() async {
  final NotificationService _notificationService = NotificationService();
  WidgetsFlutterBinding.ensureInitialized();
  await _notificationService.initializeNotifications();
  await requestNotificationPermission();
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  final productProvider = ProductProvider();
  await productProvider.init();
  
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => productProvider),
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ProductProvider>(context).themeMode;

    return MaterialApp(
      title: 'Product Expiry Calendar',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('ru', ''),
      ],
      home: HomeScreen(),
    );
  }
}
