import 'dart:developer';
import 'package:flynse/core/data/repositories/friend_repository.dart';
import 'package:flynse/core/providers/base_provider.dart';

class FriendProvider extends BaseProvider {
  final FriendRepository _friendRepo = FriendRepository();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _loansToFriends = [];
  List<Map<String, dynamic>> get loansToFriends => _loansToFriends;

  List<Map<String, dynamic>> _debtsToFriends = [];
  List<Map<String, dynamic>> get debtsToFriends => _debtsToFriends;

  List<Map<String, dynamic>> _completedFriendLoans = [];
  List<Map<String, dynamic>> get completedFriendLoans => _completedFriendLoans;

  double _totalOwedToUser = 0.0;
  double get totalOwedToUser => _totalOwedToUser;

  double _totalOwedByUser = 0.0;
  double get totalOwedByUser => _totalOwedByUser;

  /// Fetches all data related to financial interactions with friends.
  Future<void> loadFriendsData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final allFriendDebts = await _friendRepo.getFriendDebts(isClosed: false);
      _completedFriendLoans = await _friendRepo.getFriendDebts(isClosed: true);

      _loansToFriends = allFriendDebts.where((d) => d['is_user_debtor'] == 0).toList();
      _debtsToFriends = allFriendDebts.where((d) => d['is_user_debtor'] == 1).toList();

      _totalOwedToUser = _loansToFriends.fold(0.0, (sum, debt) {
        return sum + ((debt['total_amount'] as double) - (debt['amount_paid'] as double));
      });

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

  /// --- NEW: Triggers a recalculation for all friend debts and refreshes the UI. ---
  Future<void> recalculateAllFriendDebts() async {
    _isLoading = true;
    notifyListeners();
    try {
        await _friendRepo.recalculateAllFriendDebts();
        // After recalculating, we must reload the data to reflect the changes.
        await loadFriendsData();
    } catch (e) {
        log("Error recalculating friend debts: $e");
    } finally {
        _isLoading = false;
        notifyListeners();
    }
  }

  /// Adds a repayment from a friend for a loan the user gave them.
  Future<void> addRepaymentFromFriend(
      int debtId, String description, double amount, DateTime date) async {
    await _friendRepo.addRepaymentFromFriend(debtId, description, amount, date);
    await loadFriendsData();
  }
  
  /// Adds a repayment to a friend for a debt the user owes.
  Future<void> addRepaymentToFriend(
      int debtId, String description, double amount, DateTime date) async {
    await _friendRepo.addRepaymentToFriend(debtId, description, amount, date);
    await loadFriendsData();
  }
}
