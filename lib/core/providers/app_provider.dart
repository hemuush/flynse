import 'package:flutter/material.dart';
import 'package:flynse/core/providers/dashboard_provider.dart';
import 'package:flynse/core/providers/debt_provider.dart';
import 'package:flynse/core/providers/friend_provider.dart';
import 'package:flynse/core/providers/savings_provider.dart';
import 'package:flynse/core/providers/settings_provider.dart';
import 'package:flynse/core/providers/transaction_provider.dart';
import 'package:provider/provider.dart';

class AppProvider with ChangeNotifier {
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  late int _selectedYear;
  int get selectedYear => _selectedYear;

  late int _selectedMonth;
  int get selectedMonth => _selectedMonth;

  Function(int)? _navigateToTab;

  List<int> _availableYears = [];
  List<int> get availableYears => _availableYears;

  List<int> _availableMonths = [];
  List<int> get availableMonths => _availableMonths;

  final BuildContext context;

  AppProvider(this.context) {
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _generateAvailableYears();
    _updateAvailableMonths();
  }

  Future<void> init() async {
    if (_isInitialized) return;
    await context.read<SettingsProvider>().loadAppSettings();
    // After loading settings, regenerate the available periods
    onSettingsChanged();
    await refreshAllData();
    _isInitialized = true;
  }

  Future<void> refreshAllData() async {
    await Future.wait([
      context
          .read<DashboardProvider>()
          .loadDashboardData(_selectedYear, _selectedMonth),
      context
          .read<SavingsProvider>()
          .loadSavingsData(_selectedYear, _selectedMonth),
      context.read<DebtProvider>().loadDebts(_selectedYear, _selectedMonth),
      context.read<FriendProvider>().loadFriendsData(), // NEW
      context
          .read<TransactionProvider>()
          .loadTransactions(_selectedYear, _selectedMonth),
    ]);
    notifyListeners();
  }

  Future<void> setPeriod(int year, int month) async {
    if (year != _selectedYear || month != _selectedMonth) {
      _selectedYear = year;
      _updateAvailableMonths();
      final newMonths = getAvailableMonthsForYear(year);
      _selectedMonth = newMonths.contains(month) ? month : newMonths.first;
      await refreshAllData();
    }
  }

  void setNavigateToTab(Function(int) navigationFunction) {
    _navigateToTab = navigationFunction;
  }

  void navigateToTab(int index) {
    _navigateToTab?.call(index);
  }

  // --- MODIFIED: Regenerates available periods based on settings ---
  void onSettingsChanged() {
    _generateAvailableYears();
    _updateAvailableMonths();
    notifyListeners();
  }

  // --- MODIFIED: Considers salary cycle to allow planning for the next year ---
  void _generateAvailableYears() {
    const int startYear = 2024;
    final now = DateTime.now();
    final settingsProvider = context.read<SettingsProvider>();

    _availableYears = List.generate(
      now.year - startYear + 1,
      (index) => startYear + index,
    ).reversed.toList();

    // If salary comes at the end of the month and it's late December, add next year for planning.
    if (settingsProvider.salaryCycle == 'end_of_month' &&
        now.month == 12 &&
        now.day >= 25) {
      if (!_availableYears.contains(now.year + 1)) {
        _availableYears.insert(0, now.year + 1);
      }
    }
  }

  // --- MODIFIED: Considers salary cycle to allow planning for the next month ---
  List<int> getAvailableMonthsForYear(int year) {
    final now = DateTime.now();
    final settingsProvider = context.read<SettingsProvider>();
    final bool isSalaryAtEnd = settingsProvider.salaryCycle == 'end_of_month';

    int maxMonth = 12;

    if (year == now.year) {
      maxMonth = now.month;
      // If salary is at the end of the month and it's past the 25th, allow planning for next month.
      if (isSalaryAtEnd && now.day >= 25 && now.month < 12) {
        maxMonth = now.month + 1;
      }
    } else if (isSalaryAtEnd &&
        year == now.year + 1 &&
        now.month == 12 &&
        now.day >= 25) {
      // Allow January of next year to be selected in late December.
      maxMonth = 1;
    } else if (year > now.year) {
      // For future years (only possible with end-of-month cycle), show all months
      maxMonth = 12;
    }


    return List.generate(maxMonth, (i) => i + 1).reversed.toList();
  }

  void _updateAvailableMonths() {
    _availableMonths = getAvailableMonthsForYear(_selectedYear);
  }
}
