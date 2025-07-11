import 'dart:developer';
import 'package:flynse/core/data/repositories/analytics_repository.dart';
import 'package:flynse/core/providers/base_provider.dart';

class AnalyticsProvider extends BaseProvider {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();

  bool _isAnalyticsLoading = true;
  bool get isAnalyticsLoading => _isAnalyticsLoading;

  Map<String, double> _yearlyTotals = {};
  Map<String, double> get yearlyTotals => _yearlyTotals;

  List<Map<String, dynamic>> _yearlyCategoryBreakdown = [];
  List<Map<String, dynamic>> get yearlyCategoryBreakdown =>
      _yearlyCategoryBreakdown;

  List<Map<String, dynamic>> _yearlyMonthlyBreakdown = [];
  List<Map<String, dynamic>> get yearlyMonthlyBreakdown => _yearlyMonthlyBreakdown;

  List<Map<String, dynamic>> _monthlyExpenseTotals = [];
  List<Map<String, dynamic>> get monthlyExpenseTotals => _monthlyExpenseTotals;

  Future<void> fetchAnalyticsData(int year) async {
    _isAnalyticsLoading = true;
    notifyListeners();

    try {
      _yearlyTotals = await _analyticsRepo.getTotalsForYear(year);
      _yearlyCategoryBreakdown = await _analyticsRepo.getCategoryBreakdownForYear(year);
      _yearlyMonthlyBreakdown = await _analyticsRepo.getMonthlyBreakdownForYear(year);
      _monthlyExpenseTotals = await _analyticsRepo.getMonthlyExpenseTotalsForYear(year);

    } catch (e, stackTrace) {
      log('Error fetching analytics data: $e', stackTrace: stackTrace);
    } finally {
      _isAnalyticsLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the category breakdown for a specific month on demand.
  Future<List<Map<String, dynamic>>> getMonthlyCategoryBreakdown(int year, int month) async {
    return await _analyticsRepo.getCategoryBreakdownForPeriod(year, month);
  }

  /// Fetches the sub-category breakdown for a specific category and month.
  Future<List<Map<String, dynamic>>> getSubCategoryBreakdownForMonth(int year, int month, String category) async {
    return await _analyticsRepo.getSubCategoryBreakdownForMonth(year, month, category);
  }

  /// NEW: Fetches the debt repayment breakdown for a specific month.
  Future<List<Map<String, dynamic>>> getDebtRepaymentBreakdownForMonth(int year, int month) async {
    return await _analyticsRepo.getDebtRepaymentBreakdownForMonth(year, month);
  }

  /// NEW: Fetches the friend expense breakdown for a specific month.
  Future<List<Map<String, dynamic>>> getFriendExpenseBreakdownForMonth(int year, int month) async {
    return await _analyticsRepo.getFriendExpenseBreakdownForMonth(year, month);
  }
}
