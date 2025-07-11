import 'dart:developer';
import 'package:flynse/core/data/repositories/analytics_repository.dart';
import 'package:flynse/core/data/repositories/transaction_repository.dart';
import 'package:flynse/core/providers/base_provider.dart';

class DashboardProvider extends BaseProvider {
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

  // --- NEW: Property for previous month's expense total ---
  double _previousMonthExpense = 0.0;
  double get previousMonthExpense => _previousMonthExpense;


  Future<void> loadDashboardData(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _fetchMonthlyTotals(year, month),
        _fetchRecentTransactions(year, month),
        _fetchHighlightsData(year, month),
        // --- NEW: Fetch previous month's expense ---
        _fetchPreviousMonthExpense(year, month),
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

  // --- REFACTORED: Simplified to only fetch current month's data ---
  Future<void> _fetchHighlightsData(int year, int month) async {
    // Fetch current month's highest and lowest expenses.
    // The full transaction record is fetched, which includes category/sub_category.
    _highestExpense = await _analyticsRepo.getExtremeTransaction(
        'Expense', year, month,
        highest: true);
    _lowestExpense = await _analyticsRepo.getExtremeTransaction(
        'Expense', year, month,
        highest: false);
  }

  // --- NEW: Method to fetch the previous month's expense total ---
  Future<void> _fetchPreviousMonthExpense(int year, int month) async {
    DateTime previousMonthDate = DateTime(year, month - 1);
    final totals = await _analyticsRepo.getTotalsForPeriod(previousMonthDate.year, previousMonthDate.month);
    _previousMonthExpense = totals['Expense'] ?? 0.0;
  }
}
