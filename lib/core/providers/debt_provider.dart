import 'dart:developer';
import 'package:flynse/core/data/repositories/debt_repository.dart';
import 'package:flynse/core/providers/base_provider.dart';

class DebtProvider extends BaseProvider {
  final DebtRepository _debtRepo = DebtRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  double _totalPendingDebt = 0.0;
  double get totalPendingDebt => _totalPendingDebt;

  List<Map<String, dynamic>> _userDebts = [];
  List<Map<String, dynamic>> get userDebts => _userDebts;

  List<Map<String, dynamic>> _completedUserDebts = [];
  List<Map<String, dynamic>> get completedUserDebts => _completedUserDebts;

  /// Fetches only personal (non-friend) debt data.
  Future<void> loadDebts() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _debtRepo.applyAnnualInterest();

      _userDebts = await _debtRepo.getDebts(isClosed: false);
      _completedUserDebts = await _debtRepo.getDebts(isClosed: true);

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

  /// --- NEW: Triggers a recalculation for all personal debts and refreshes the UI. ---
  Future<void> recalculateAllPersonalDebts() async {
    _isLoading = true;
    notifyListeners();
    try {
        await _debtRepo.recalculateAllPersonalDebts();
        // After recalculating, we must reload the data to reflect the changes.
        await loadDebts();
    } catch (e) {
        log("Error recalculating personal debts: $e");
    } finally {
        _isLoading = false;
        notifyListeners();
    }
  }

  Future<void> addDebt(Map<String, dynamic> data) async {
    await _debtRepo.addDebt(data);
    await loadDebts();
  }

  /// Adds a repayment for a personal debt and now includes the prepayment option.
  Future<void> addRepayment(
      int debtId, String description, double amount, DateTime date,
      {String? prepaymentOption}) async {
    await _debtRepo.addRepaymentWithDate(debtId, description, amount, date,
        prepaymentOption: prepaymentOption);
    await loadDebts();
  }

  Future<void> forecloseDebt(int debtId, String debtName, DateTime date,
      {double? foreclosurePenaltyPercentage}) async {
    await _debtRepo.forecloseDebt(debtId, debtName, date,
        foreclosurePenaltyPercentage: foreclosurePenaltyPercentage);
    await loadDebts();
  }

  /// Updates details for a personal debt.
  Future<void> updateDebtDetails(
      int debtId, double? newInterestRate, int? newTermYears) async {
    await _debtRepo.updateDebtInfo(
      debtId: debtId,
      newInterestRate: newInterestRate,
      newTermYears: newTermYears,
    );
    await loadDebts();
  }

  Future<void> deleteDebt(int debtId) async {
    await _debtRepo.deleteDebtAndTransactions(debtId);
    await loadDebts();
  }
}
