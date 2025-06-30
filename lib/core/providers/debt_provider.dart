import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';

class DebtProvider with ChangeNotifier {
  final DebtRepository _debtRepo = DebtRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  double _totalPendingDebt = 0.0;
  double get totalPendingDebt => _totalPendingDebt;

  int _activeDebtCount = 0;
  int get activeDebtCount => _activeDebtCount;

  List<Map<String, dynamic>> _userDebts = [];
  List<Map<String, dynamic>> get userDebts => _userDebts;

  List<Map<String, dynamic>> _completedUserDebts = [];
  List<Map<String, dynamic>> get completedUserDebts => _completedUserDebts;

  List<Map<String, dynamic>> _friendLoans = [];
  List<Map<String, dynamic>> get friendLoans => _friendLoans;

  List<Map<String, dynamic>> _completedFriendLoans = [];
  List<Map<String, dynamic>> get completedFriendLoans => _completedFriendLoans;

  double _totalOwedToUser = 0.0;
  double get totalOwedToUser => _totalOwedToUser;

  int _debtViewIndex = 0;
  int get debtViewIndex => _debtViewIndex;

  void setDebtViewIndex(int index) {
    if (_debtViewIndex != index) {
      _debtViewIndex = index;
      notifyListeners();
    }
  }

  /// Fetches all debt-related data from the repository.
  Future<void> loadDebts(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _debtRepo.applyAnnualInterest();

      _userDebts = await _debtRepo.getDebts(isUserDebtor: true, isClosed: false);
      _completedUserDebts =
          await _debtRepo.getDebts(isUserDebtor: true, isClosed: true);
      _friendLoans =
          await _debtRepo.getDebts(isUserDebtor: false, isClosed: false);
      _completedFriendLoans =
          await _debtRepo.getDebts(isUserDebtor: false, isClosed: true);

      _totalPendingDebt = 0.0;
      for (final debt in _userDebts) {
        _totalPendingDebt +=
            (debt['total_amount'] as double) - (debt['amount_paid'] as double);
      }
      _activeDebtCount = _userDebts.length;

      _totalOwedToUser = 0.0;
      for (final debt in _friendLoans) {
        _totalOwedToUser +=
            (debt['total_amount'] as double) - (debt['amount_paid'] as double);
      }
    } catch (e) {
      log("Error fetching debts data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDebt(Map<String, dynamic> data) async {
    await _debtRepo.addDebt(data);
  }

  /// Adds a repayment and now includes the prepayment option.
  Future<void> addRepayment(
      int debtId, String description, double amount, DateTime date,
      {String? prepaymentOption}) async {
    await _debtRepo.addRepaymentWithDate(debtId, description, amount, date,
        prepaymentOption: prepaymentOption);
  }

  Future<void> addRepaymentFromFriend(
      int debtId, String description, double amount, DateTime date) async {
    await _debtRepo.addRepaymentFromFriend(debtId, description, amount, date);
  }

  Future<void> forecloseDebt(int debtId, String debtName, DateTime date,
      {double? foreclosurePenaltyPercentage}) async {
    await _debtRepo.forecloseDebt(debtId, debtName, date,
        foreclosurePenaltyPercentage: foreclosurePenaltyPercentage);
  }

  /// MODIFICATION: This method now calls loadDebts to refresh the state after an update.
  Future<void> updateDebtDetails(
      int debtId, double? newInterestRate, int? newTermYears) async {
    await _debtRepo.updateDebtInfo(
      debtId: debtId,
      newInterestRate: newInterestRate,
      newTermYears: newTermYears,
    );
  }

  Future<void> deleteDebt(int debtId) async {
    await _debtRepo.deleteDebtAndTransactions(debtId);
  }
}
