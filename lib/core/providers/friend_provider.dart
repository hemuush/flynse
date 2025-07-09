import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/repositories/debt_repository.dart';

class FriendProvider with ChangeNotifier {
  final DebtRepository _debtRepo = DebtRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // MODIFIED: Now holds separate lists for different debt types.
  List<Map<String, dynamic>> _loansToFriends = [];
  List<Map<String, dynamic>> get loansToFriends => _loansToFriends;

  List<Map<String, dynamic>> _debtsToFriends = [];
  List<Map<String, dynamic>> get debtsToFriends => _debtsToFriends;

  List<Map<String, dynamic>> _completedFriendLoans = [];
  List<Map<String, dynamic>> get completedFriendLoans => _completedFriendLoans;

  double _totalOwedToUser = 0.0;
  double get totalOwedToUser => _totalOwedToUser;

  // NEW: Total amount the user owes to friends.
  double _totalOwedByUser = 0.0;
  double get totalOwedByUser => _totalOwedByUser;

  /// Fetches all data related to financial interactions with friends.
  Future<void> loadFriendsData() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Fetch all active and completed debts associated with friends.
      final allFriendDebts = await _debtRepo.getFriendDebts(isClosed: false);
      _completedFriendLoans = await _debtRepo.getFriendDebts(isClosed: true);

      // Separate the active debts into two lists based on who the debtor is.
      _loansToFriends = allFriendDebts.where((d) => d['is_user_debtor'] == 0).toList();
      _debtsToFriends = allFriendDebts.where((d) => d['is_user_debtor'] == 1).toList();

      // Calculate the total amount friends owe to the user.
      _totalOwedToUser = _loansToFriends.fold(0.0, (sum, debt) {
        return sum + ((debt['total_amount'] as double) - (debt['amount_paid'] as double));
      });

      // Calculate the total amount the user owes to friends.
      _totalOwedByUser = _debtsToFriends.fold(0.0, (sum, debt) {
        return sum + ((debt['total_amount'] as double) - (debt['amount_paid'] as double));
      });

    } catch (e) {
      log("Error fetching friend loans data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
