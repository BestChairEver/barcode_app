import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'utils/notifications.dart';
import 'utils/product_provider.dart';
import 'utils/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ProductProvider()..init()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> _initializeApp() async {
  await _requestNotificationPermissions();
  await initializeNotifications();
  print("Инициализация приложения завершена.");
}

Future<void> _requestNotificationPermissions() async {
  final status = await Permission.notification.request();
  if (status.isGranted) {
    print("Разрешение на уведомления предоставлено.");
  } else if (status.isPermanentlyDenied) {
    print("Разрешение на уведомления постоянно отклонено. Откройте настройки для предоставления доступа.");
  } else {
    print("Разрешение на уведомления отклонено.");
  }
}

class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Календарь сроков годности',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
