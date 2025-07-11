import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/providers/analytics_provider.dart';
import 'package:flynse/core/providers/app_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:flynse/features/dashboard/dashboard_page.dart';
import 'package:flynse/features/dashboard/widgets/financial_details_sheet.dart';
import 'package:flynse/features/debt/debt.dart';
import 'package:flynse/features/friends/friends.dart';
import 'package:flynse/features/security/pin_lock_page.dart';
import 'package:flynse/features/savings/savings_page.dart';
import 'package:flynse/features/transaction/transaction_list_page.dart';
import 'package:flynse/features/transaction/widgets/transaction_form_models.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatefulWidget {
  final bool isFirstLaunch;

  const MyHomePage({super.key, this.isFirstLaunch = false});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  DateTime? _lastPressedAt;
  bool _isLocked = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    context.read<AppProvider>().setNavigateToTab((int index) {
      if (mounted) {
        _onItemTapped(index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().checkAndPerformAutoBackup();
      if (!widget.isFirstLaunch) {
        _checkPinAndLock();
      } else {
        setState(() {
          _isLocked = false;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      if (mounted) {
        setState(() {
          _isLocked = true;
        });
      }
    }
    if (state == AppLifecycleState.resumed && _isLocked) {
      _checkPinAndLock();
    }
  }

  Future<void> _checkPinAndLock() async {
    // FIX: Prevents pushing multiple lock screens by checking a static flag.
    if (PinLockPage.isLockScreenOpen) return;

    final settingsRepo = SettingsRepository();
    final pinExists = await settingsRepo.getPin() != null;

    if (pinExists && mounted) {
      Navigator.of(context).pushNamed(
        AppRouter.pinLockPage,
        arguments: PinLockPageArgs(
          mode: PinLockMode.enter,
          onPinCorrect: () {
            if (mounted) {
              setState(() {
                _isLocked = false;
              });
            }
          },
        ),
      );
    } else {
      if (mounted) {
        setState(() {
          _isLocked = false;
        });
      }
    }
  }

  final List<Widget> _mainPages = [
    const DashboardPage(),
    const SavingsPage(),
    const DebtPage(),
    const FriendsPage(),
    const TransactionListPage(),
  ];

  static const List<String> _pageTitles = [
    'Overview',
    'Savings',
    'Debts',
    'Friends',
    'History',
  ];

  void _onItemTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToSettings() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushNamed(AppRouter.settingsPage);
  }

  void _onFabPressed() {
    HapticFeedback.mediumImpact();
    String routeName;
    Object? arguments;

    final pageIndexForAction = _selectedIndex;

    switch (pageIndexForAction) {
      case 0:
      case 4:
        routeName = AppRouter.addEditTransactionPage;
        arguments = AddEditTransactionPageArgs();
        break;
      case 1:
        routeName = AppRouter.addEditTransactionPage;
        arguments = AddEditTransactionPageArgs(isSaving: true);
        break;
      case 2:
        routeName = AppRouter.addDebtPage;
        arguments = null;
        break;
      case 3:
        routeName = AppRouter.addEditTransactionPage;
        arguments = AddEditTransactionPageArgs(isLoanToFriend: true);
        break;
      default:
        return;
    }

    Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();

    Color getStartColor() {
      if (_selectedIndex == 0) {
        return theme.colorScheme.surfaceContainer;
      }
      return theme.scaffoldBackgroundColor;
    }

    final gradientColors = [
      getStartColor(),
      theme.scaffoldBackgroundColor,
    ];

    final appBar = _selectedIndex == 0
        ? null
        : AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _pageTitles[_selectedIndex],
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
                      builder: (_) => const FinancialDetailsSheet(sheetType: SheetType.yearly),
                    );
                  }
                },
                tooltip: 'Yearly Details',
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0, left: 8.0),
                child: GestureDetector(
                  onTap: _navigateToSettings,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        settingsProvider.profileImageBase64 != null &&
                                settingsProvider.profileImageBase64!.isNotEmpty
                            ? MemoryImage(
                                base64Decode(
                                    settingsProvider.profileImageBase64!))
                            : null,
                    child: (settingsProvider.profileImageBase64 == null ||
                            settingsProvider.profileImageBase64!.isEmpty)
                        ? (settingsProvider.userName.isNotEmpty
                            ? Text(
                                settingsProvider.userName[0].toUpperCase(),
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                              )
                            : Icon(Icons.person_outline_rounded,
                                size: 24, color: theme.colorScheme.primary))
                        : null,
                  ),
                ),
              ),
            ],
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);
        if (_selectedIndex != 0) {
          _onItemTapped(0);
        } else {
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
          appBar: appBar,
          body: IndexedStack(
            index: _selectedIndex,
            children: _mainPages,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _onFabPressed,
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: theme.colorScheme.surfaceContainer,
            type: BottomNavigationBarType.fixed,
            elevation: 8.0,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurfaceVariant,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.savings_outlined),
                activeIcon: Icon(Icons.savings_rounded),
                label: 'Savings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long_rounded),
                label: 'Debts',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline_rounded),
                activeIcon: Icon(Icons.people_rounded),
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
