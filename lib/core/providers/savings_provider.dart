import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/savings_repository.dart';

class SavingsProvider with ChangeNotifier {
  final SavingsRepository _savingsRepo = SavingsRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? lastCompletedGoalName;

  double _totalSavings = 0.0;
  double get totalSavings => _totalSavings;

  double _allTimeTotalSavings = 0.0;
  double get allTimeTotalSavings => _allTimeTotalSavings;

  List<Map<String, dynamic>> _savingsTransactions = [];
  List<Map<String, dynamic>> get savingsTransactions => _savingsTransactions;

  List<Map<String, dynamic>> _yearlySavings = [];
  List<Map<String, dynamic>> get yearlySavings => _yearlySavings;

  Map<String, dynamic>? _activeSavingsGoal;
  Map<String, dynamic>? get activeSavingsGoal => _activeSavingsGoal;

  List<Map<String, dynamic>> _savingsGrowthData = [];
  List<Map<String, dynamic>> get savingsGrowthData => _savingsGrowthData;

  // NEW: To store savings breakdown by category
  List<Map<String, dynamic>> _savingsByCategory = [];
  List<Map<String, dynamic>> get savingsByCategory => _savingsByCategory;

  Future<void> loadSavingsData(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      // --- CORRECTED: Fetch cumulative total and cumulative transaction list ---
      _totalSavings = await _savingsRepo.getTotalSavingsUpToPeriod(year, month);
      
      _savingsTransactions =
          await _savingsRepo.getSavingsTransactionsUpToPeriod(year, month);

      // These remain as they are, as they deal with all-time data or yearly summaries
      _allTimeTotalSavings = await _savingsRepo.getTotalSavings();
      _activeSavingsGoal = await _savingsRepo.getActiveSavingsGoal();
      _savingsGrowthData = await _savingsRepo.getSavingsGrowthData();
      _yearlySavings = await _savingsRepo.getYearlySavings();
      _savingsByCategory = await _savingsRepo.getSavingsByCategory();
      await _checkAndCompleteSavingsGoal();
    } catch (e) {
      log("Error fetching savings data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // UPDATED: Now requires a category for withdrawal
  Future<void> useSavings(double amount, String category,
      [String? description, DateTime? date]) async {
    await _savingsRepo.useSavings(amount, category, description, date);
  }

  Future<void> setSavingsGoal(String name, double amount) async {
    final goal = {
      'name': name,
      'target_amount': amount,
      'is_completed': 0,
      'creation_date': DateTime.now().toIso8601String(),
    };
    await _savingsRepo.addOrUpdateSavingsGoal(goal);
  }

  Future<void> deleteActiveSavingsGoal() async {
    if (_activeSavingsGoal != null) {
      await _savingsRepo.deleteSavingsGoal(_activeSavingsGoal!['id']);
    }
  }

  void clearLastCompletedGoal() {
    lastCompletedGoalName = null;
  }

  Future<void> _checkAndCompleteSavingsGoal() async {
    if (_activeSavingsGoal != null) {
      final target = _activeSavingsGoal!['target_amount'] as double;
      if (_allTimeTotalSavings >= target) {
        await _savingsRepo.completeSavingsGoal(_activeSavingsGoal!['id']);
        lastCompletedGoalName = _activeSavingsGoal!['name'];
        _activeSavingsGoal = null;
      }
    }
  }
}
