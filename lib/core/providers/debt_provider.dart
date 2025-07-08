import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';

class DebtProvider with ChangeNotifier {
  final DebtRepository _debtRepo = DebtRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  double _totalPendingDebt = 0.0;
  double get totalPendingDebt => _totalPendingDebt;

  List<Map<String, dynamic>> _userDebts = [];
  List<Map<String, dynamic>> get userDebts => _userDebts;

  List<Map<String, dynamic>> _completedUserDebts = [];
  List<Map<String, dynamic>> get completedUserDebts => _completedUserDebts;

  /// MODIFIED: Fetches only non-friend related debt data.
  Future<void> loadDebts(int year, int month) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _debtRepo.applyAnnualInterest();

      // Fetch only personal (non-friend) debts.
      _userDebts = await _debtRepo.getDebts(
          isUserDebtor: true, isClosed: false, nonFriendDebtsOnly: true);
      _completedUserDebts = await _debtRepo.getDebts(
          isUserDebtor: true, isClosed: true, nonFriendDebtsOnly: true);

      _totalPendingDebt = 0.0;
      for (final debt in _userDebts) {
        _totalPendingDebt +=
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
