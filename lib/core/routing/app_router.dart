import 'package:flutter/material.dart';
import 'package:flynse/features/analytics/analytics_page.dart';
import 'package:flynse/features/debt/debt.dart';
import 'package:flynse/features/security/pin_lock_page.dart';
import 'package:flynse/features/settings/admin_page.dart';
import 'package:flynse/features/settings/manage_friends_page.dart';
import 'package:flynse/features/settings/settings_page.dart';
import 'package:flynse/features/transaction/add_edit_transaction_page.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:flynse/ui/home_page.dart';
import 'package:flynse/ui/onboarding_page.dart';
import 'package:flynse/ui/splash_screen.dart';

/// Centralized route management for the application.
class AppRouter {
  static const String splashScreen = '/';
  static const String onboardingPage = '/onboarding';
  static const String homePage = '/home';
  static const String pinLockPage = '/pin-lock';
  static const String settingsPage = '/settings';
  static const String manageFriendsPage = '/settings/friends';
  static const String adminPage = '/settings/admin';
  static const String addEditTransactionPage = '/transaction/add-edit';
  static const String addDebtPage = '/debt/add';
  static const String analyticsPage = '/analytics';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashScreen:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboardingPage:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case homePage:
        return MaterialPageRoute(builder: (_) => const MyHomePage());
      case pinLockPage:
        final args = settings.arguments as PinLockPageArgs?;
        return MaterialPageRoute(
          builder: (_) => PinLockPage(
            mode: args?.mode ?? PinLockMode.enter,
            onPinCreated: args?.onPinCreated,
            onPinCorrect: args?.onPinCorrect,
            title: args?.title,
          ),
        );
      case settingsPage:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case manageFriendsPage:
        return MaterialPageRoute(builder: (_) => const ManageFriendsPage());
      case adminPage:
        return MaterialPageRoute(builder: (_) => const AdminPage());
      case addEditTransactionPage:
        final args = settings.arguments as AddEditTransactionPageArgs?;
        return MaterialPageRoute(
          builder: (_) => AddEditTransactionPage(
            transaction: args?.transaction,
            isSaving: args?.isSaving ?? false,
            isLoanToFriend: args?.isLoanToFriend ?? false,
          ),
        );
      case addDebtPage:
        return MaterialPageRoute(builder: (_) => const AddDebtPage());

      case analyticsPage:
        final args = settings.arguments as AnalyticsPageArgs;
        return MaterialPageRoute(
            builder: (_) => AnalyticsPage(
                  selectedYear: args.selectedYear,
                  selectedMonth: args.selectedMonth,
                ));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
