import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/providers/transaction_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/shared/theme/dark_theme.dart';
import 'package:flynse/shared/theme/light_theme.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:flynse/shared/theme/theme_manager.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  tz.initializeTimeZones();

  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (context) => AppProvider(context)),
      ],
      child: const FlynseApp(),
    ),
  );
}

class FlynseApp extends StatelessWidget {
  const FlynseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, SettingsProvider>(
      builder: (context, themeNotifier, settingsProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flynse',
          theme: LightTheme.buildTheme(settingsProvider.seedColorLight),
          darkTheme: DarkTheme.buildTheme(settingsProvider.seedColorDark),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: AppRouter.splashScreen,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
