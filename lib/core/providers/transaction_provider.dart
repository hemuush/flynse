import 'dart:developer';
import 'package:flynse/core/data/repositories/transaction_repository.dart';
import 'package:flynse/core/providers/base_provider.dart';

class TransactionProvider extends BaseProvider {
  final TransactionRepository _transactionRepo = TransactionRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _filteredTransactions = [];
  List<Map<String, dynamic>> get filteredTransactions => _filteredTransactions;

  String _transactionSearchQuery = '';
  String get transactionSearchQuery => _transactionSearchQuery;

  String _transactionTypeFilter = 'All';
  String get transactionTypeFilter => _transactionTypeFilter;

  String _transactionSortBy = 'date';
  String get transactionSortBy => _transactionSortBy;

  bool _transactionSortAscending = false;
  bool get transactionSortAscending => _transactionSortAscending;

  String _transactionViewMode = 'Monthly';
  String get transactionViewMode => _transactionViewMode;
  
  // --- NEW: Properties to track the current filtered period ---
  int? _currentYear;
  int? get currentYear => _currentYear;

  int? _currentMonth;
  int? get currentMonth => _currentMonth;


  Future<void> loadTransactions(int year, int? month) async {
    _isLoading = true;
    notifyListeners();
    // --- FIX: Store the period being loaded ---
    _currentYear = year;
    _currentMonth = _transactionViewMode == 'Yearly' ? null : month;
    await _fetchFilteredTransactions(year, _currentMonth);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setTransactionFilters({
    required int year,
    int? month,
    String? query,
    String? type,
    String? sortBy,
    bool? sortAscending,
    String? viewMode,
  }) async {
    _transactionSearchQuery = query ?? _transactionSearchQuery;
    _transactionTypeFilter = type ?? _transactionTypeFilter;
    _transactionSortBy = sortBy ?? _transactionSortBy;
    _transactionSortAscending = sortAscending ?? _transactionSortAscending;
    _transactionViewMode = viewMode ?? _transactionViewMode;

    // If view mode is yearly, month should be null
    final effectiveMonth = _transactionViewMode == 'Yearly' ? null : month;

    // This will now call loadTransactions which updates the current period
    await loadTransactions(year, effectiveMonth);
  }

  Future<void> _fetchFilteredTransactions(int year, int? month) async {
    try {
      _filteredTransactions = await _transactionRepo.getFilteredTransactions(
        type: _transactionTypeFilter,
        year: year,
        month: month, // Pass month which can be null for yearly view
        sortBy: _transactionSortBy,
        ascending: _transactionSortAscending,
        query: _transactionSearchQuery,
      );
    } catch (e) {
      log("Error fetching filtered transactions: $e");
    }
  }
  
  Future<void> addTransaction(Map<String, dynamic> data) async {
    await _transactionRepo.insertTransaction(data);
  }

  Future<void> addMultipleTransactions(List<Map<String, dynamic>> data) async {
    await _transactionRepo.insertMultipleTransactions(data);
  }

  Future<void> updateTransaction(Map<String, dynamic> data) async {
    await _transactionRepo.updateTransaction(data);
  }

  Future<void> deleteTransaction(int id) async {
    await _transactionRepo.deleteTransaction(id);
  }
}
