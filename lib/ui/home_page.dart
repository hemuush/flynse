import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/dashboard/dashboard_page.dart';
import 'package:flynse/features/dashboard/widgets/yearly_details_sheet.dart';
import 'package:flynse/features/debt/debt.dart';
import 'package:flynse/features/savings/savings_page.dart';
import 'package:flynse/features/transaction/transaction_list_page.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // The selected index for the BottomNavigationBar.
  int _selectedIndex = 0;
  // The actual page index, which skips the central action button.
  int get _pageIndex => _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex;

  // --- MODIFICATION: Variable to track the last back button press ---
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    // Set navigation callback first
    context.read<AppProvider>().setNavigateToTab((int index) {
      if (mounted) {
        // The AppProvider works with 0-3 for pages, so we map it back
        // to the BottomNavigationBar index.
        _onItemTapped(index > 1 ? index + 1 : index);
      }
    });

    // Run backup check after frame is built to avoid blocking startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().checkAndPerformAutoBackup();
    });
  }

  // A list of the main pages accessible from the bottom navigation bar.
  final List<Widget> _mainPages = [
    const DashboardPage(),
    const SavingsPage(),
    const DebtPage(),
    const TransactionListPage(),
  ];

  // Titles corresponding to each page.
  static const List<String> _pageTitles = [
    'Overview',
    'Savings',
    'Debts',
    'History',
  ];

  // Handles tap events on the bottom navigation bar items.
  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    // If the center button (index 2) is tapped, trigger the FAB action.
    if (index == 2) {
      _onFabPressed();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });

    context.read<AppProvider>().setShowFab(true);
  }

  // Navigates to the settings page.
  void _navigateToSettings() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed(AppRouter.settingsPage).then((_) {
      // Refresh state after returning from settings
      setState(() {});
    });
  }

  // Determines the action for the central button based on the current tab.
  void _onFabPressed() {
    HapticFeedback.mediumImpact();
    String routeName;
    Object? arguments;

    final debtProvider = context.read<DebtProvider>();
    final pageIndexForAction = _pageIndex;

    switch (pageIndexForAction) {
      case 0: // Overview
      case 3: // History
        routeName = AppRouter.addEditTransactionPage;
        arguments = AddEditTransactionPageArgs();
        break;
      case 1: // Savings
        routeName = AppRouter.addEditTransactionPage;
        arguments = AddEditTransactionPageArgs(isSaving: true);
        break;
      case 2: // Debts
        if (debtProvider.debtViewIndex == 0) {
          // "Your Debts" tab -> Add a loan the user took.
          routeName = AppRouter.addDebtPage;
          arguments = null;
        } else {
          // "Owed to You" tab -> Add a loan to a friend.
          routeName = AppRouter.addEditTransactionPage;
          arguments = AddEditTransactionPageArgs(isLoanToFriend: true);
        }
        break;
      default:
        return;
    }

    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final settingsProvider = context.watch<SettingsProvider>();

    // Helper to get the correct start color for the gradient based on the selected page
    Color getStartColor() {
      if (_pageIndex == 0) {
        if (isDarkMode) {
          return settingsProvider.dashboardBgDark ??
              Color.lerp(theme.colorScheme.primary, Colors.black, 0.6)!;
        } else {
          return settingsProvider.dashboardBgLight ??
              theme.colorScheme.primary.withAlpha(100);
        }
      }
      return theme.scaffoldBackgroundColor;
    }

    final gradientColors = [
      getStartColor(),
      theme.scaffoldBackgroundColor,
    ];

    String titleText;
    if (_pageIndex == 0) {
      final firstName = settingsProvider.userName.split(' ').first;
      titleText = 'Hi, ${firstName.isNotEmpty ? firstName : 'There'}';
    } else {
      titleText = _pageTitles[_pageIndex];
    }

    // --- MODIFICATION: Wrapped AnimatedContainer with PopScope ---
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        // If we are not on the dashboard page, navigate back to it.
        if (_pageIndex != 0) {
          _onItemTapped(0);
        } else {
          // If we are on the dashboard, handle the double-press to exit.
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            // If pressed again within 2 seconds, exit the app.
            if (navigator.canPop()) {
              navigator.pop();
            } else {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
            gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.6],
        )),
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              titleText,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.assessment_outlined),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  final appProvider = context.read<AppProvider>();
                  await context
                      .read<AnalyticsProvider>()
                      .fetchAnalyticsData(appProvider.selectedYear);
                  if (context.mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const YearlyDetailsSheet(),
                    );
                  }
                },
                tooltip: 'Yearly Details',
              ),
              Padding(
                padding:
                    const EdgeInsets.only(right: 8.0, top: 4.0, bottom: 4.0),
                child: GestureDetector(
                  onTap: _navigateToSettings,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        settingsProvider.profileImageBase64 != null &&
                                settingsProvider.profileImageBase64!.isNotEmpty
                            ? MemoryImage(
                                base64Decode(settingsProvider.profileImageBase64!))
                            : null,
                    child: (settingsProvider.profileImageBase64 == null ||
                            settingsProvider.profileImageBase64!.isEmpty)
                        ? (settingsProvider.userName.isNotEmpty
                            ? Text(
                                settingsProvider.userName[0].toUpperCase(),
                                style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : Icon(Icons.person_outline_rounded,
                                size: 26, color: theme.colorScheme.primary))
                        : null,
                  ),
                ),
              ),
            ],
          ),
          body: IndexedStack(
            index: _pageIndex,
            children: _mainPages,
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  backgroundColor:
                      theme.colorScheme.surfaceContainer.withAlpha(204),
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: true,
                  showUnselectedLabels: true,
                  selectedItemColor: theme.colorScheme.primary,
                  unselectedItemColor: theme.colorScheme.onSurfaceVariant,
                  elevation: 0,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard_rounded),
                      label: 'Overview',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.savings_outlined),
                      activeIcon: Icon(Icons.savings_rounded),
                      label: 'Savings',
                    ),
                    BottomNavigationBarItem(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(14),
                        child:
                            Icon(Icons.add, color: theme.colorScheme.onPrimary),
                      ),
                      label: '',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.receipt_long_outlined),
                      activeIcon: Icon(Icons.receipt_long_rounded),
                      label: 'Debts',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.history_outlined),
                      activeIcon: Icon(Icons.history_rounded),
                      label: 'History',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
