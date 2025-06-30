import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/analytics_repository.dart';
import 'package:flynse/core/data/repositories/transaction_repository.dart';

class DashboardProvider with ChangeNotifier {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Map<String, double> _monthlyTotals = {};
  Map<String, double> get monthlyTotals => _monthlyTotals;

  Map<String, double> _cumulativeTotals = {};
  Map<String, double> get cumulativeTotals => _cumulativeTotals;

  List<Map<String, dynamic>> _monthlyCategoryBreakdown = [];
  List<Map<String, dynamic>> get monthlyCategoryBreakdown =>
      _monthlyCategoryBreakdown;

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> get recentTransactions => _recentTransactions;

  Map<String, dynamic>? _highestExpense;
  Map<String, dynamic>? get highestExpense => _highestExpense;

  Map<String, dynamic>? _lowestExpense;
  Map<String, dynamic>? get lowestExpense => _lowestExpense;

  double _lastMonthExpenseTotal = 0.0;
  double get lastMonthExpenseTotal => _lastMonthExpenseTotal;
  
  double _lastMonthLowestExpenseAmount = 0.0;
  double get lastMonthLowestExpenseAmount => _lastMonthLowestExpenseAmount;


  Future<void> loadDashboardData(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _fetchMonthlyTotals(year, month),
        _fetchRecentTransactions(year, month),
        _fetchHighlightsData(year, month),
      ]);
      _monthlyCategoryBreakdown =
          await _analyticsRepo.getCategoryBreakdownForPeriod(year, month);
    } catch (e) {
      log('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchMonthlyTotals(int year, int month) async {
    _monthlyTotals = await _analyticsRepo.getTotalsForPeriod(year, month);
    _cumulativeTotals = await _analyticsRepo.getTotalsUpToPeriod(year, month);
  }

  Future<void> _fetchRecentTransactions(int year, int month) async {
    _recentTransactions = await _transactionRepo.getFilteredTransactions(
      year: year,
      month: month,
      limit: 5,
    );
  }

  Future<void> _fetchHighlightsData(int year, int month) async {
    _highestExpense = await _analyticsRepo.getExtremeTransaction(
        'Expense', year, month,
        highest: true);
    _lowestExpense = await _analyticsRepo.getExtremeTransaction(
        'Expense', year, month,
        highest: false);

    final lastMonthDate = DateTime(year, month - 1, 1);
    final lastMonthTotals = await _analyticsRepo.getTotalsForPeriod(
        lastMonthDate.year, lastMonthDate.month);
    _lastMonthExpenseTotal = lastMonthTotals['Expense'] ?? 0.0;

    final lastMonthLowestExpenseData =
        await _analyticsRepo.getExtremeTransaction('Expense', lastMonthDate.year, lastMonthDate.month, highest: false);
    _lastMonthLowestExpenseAmount = lastMonthLowestExpenseData?['amount'] ?? 0.0;

  }
}
