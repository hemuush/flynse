import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import this
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

  // --- MODIFIED: Enable Edge-to-Edge Display ---
  // This makes the system navigation bar transparent, allowing the app to draw behind it.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);


  // Initialize database factory for web if applicable
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Initialize timezones synchronously (it's fast)
  tz.initializeTimeZones();

  // FIX: Initialize ThemeNotifier and load the theme before running the app
  // to prevent a theme flicker on startup.
  final themeNotifier = ThemeNotifier();
  await themeNotifier.loadTheme();

  runApp(
    MultiProvider(
      providers: [
        // --- CORRECTED ORDER ---
        // Independent, feature-specific providers are declared first.
        ChangeNotifierProvider.value(value: themeNotifier), // Use .value for existing instance
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => DebtProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()), // NEW
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        // The AppProvider, which depends on the others, is declared last.
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
    // FIX: Consume both ThemeNotifier and SettingsProvider to ensure the UI
    // rebuilds when either the theme mode (light/dark) or the theme color changes.
    return Consumer2<ThemeNotifier, SettingsProvider>(
      builder: (context, themeNotifier, settingsProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flynse',
          // Build themes dynamically using seed colors from settings
          theme: LightTheme.buildTheme(settingsProvider.seedColorLight),
          darkTheme: DarkTheme.buildTheme(settingsProvider.seedColorDark),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          
          // Use the AppRouter for all navigation.
          initialRoute: AppRouter.splashScreen,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
