import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all friend and friend-debt related database queries.
class FriendRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// Retrieves a list of friends, with optional filtering.
  Future<List<Map<String, dynamic>>> getFriends({String? filter}) async {
    final db = await _database;
    String? where;
    List<dynamic>? whereArgs;
    if (filter != null && filter.isNotEmpty) {
      where = 'name LIKE ?';
      whereArgs = ['%$filter%'];
    }
    return db.query('friends', where: where, whereArgs: whereArgs, orderBy: 'name');
  }

  /// Adds a new friend to the database.
  Future<int> addFriend(String name) async {
    final db = await _database;
    return db.insert('friends', {'name': name}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Deletes a friend. This is only allowed if they have no pending debts.
  Future<void> deleteFriend(int friendId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update('transactions', {'friend_id': null}, where: 'friend_id = ?', whereArgs: [friendId]);
      await txn.delete('friend_debts', where: 'friend_id = ?', whereArgs: [friendId]);
      await txn.delete('friends', where: 'id = ?', whereArgs: [friendId]);
    });
  }

  /// Fetches all debts (loans to/from) associated with friends.
  Future<List<Map<String, dynamic>>> getFriendDebts({bool isClosed = false}) async {
    final db = await _database;
    return db.query(
      'friend_debts',
      where: 'is_closed = ?',
      whereArgs: [isClosed ? 1 : 0],
      orderBy: '(total_amount - amount_paid) DESC',
    );
  }

  /// Checks if a friend has any pending (unclosed) debts.
  Future<bool> hasPendingDebtsForFriend(int friendId) async {
    final db = await _database;
    final result = await db.query(
      'friend_debts',
      where: 'friend_id = ? AND is_closed = 0',
      whereArgs: [friendId],
      limit: 1,
    );
    return result.isNotEmpty;
  }
  
  /// --- REWRITTEN: Recalculates the debt state for ALL friends to fix inconsistencies. ---
  Future<void> recalculateAllFriendDebts() async {
    final db = await _database;
    await db.transaction((txn) async {
        final friends = await txn.query('friends', columns: ['id']);
        for (final friend in friends) {
            final friendId = friend['id'] as int;
            await recalculateFriendDebtState(txn, friendId);
        }
    });
  }

  /// --- REWRITTEN: This method now robustly rebuilds the debt state from scratch. ---
  Future<void> recalculateFriendDebtState(Transaction txn, int friendId) async {
    // Step 1: Get all transaction IDs related to this friend *before* deleting anything.
    // This is crucial for not losing history.
    final transactionIdsResult = await txn.rawQuery('''
        SELECT t.id FROM transactions t
        LEFT JOIN friend_debts fd ON t.friend_debt_id = fd.id
        WHERE t.friend_id = ? OR fd.friend_id = ?
    ''', [friendId, friendId]);
    final transactionIds = transactionIdsResult.map((row) => row['id'] as int).toList();

    // Step 2: Clear existing debt records for this friend to start fresh.
    await txn.delete('friend_debts', where: 'friend_id = ?', whereArgs: [friendId]);

    if (transactionIds.isEmpty) return; // No history, nothing to do.

    // Step 3: Fetch the full details of these transactions, ordered chronologically.
    final transactions = await txn.query(
        'transactions',
        where: 'id IN (${List.filled(transactionIds.length, '?').join(',')})',
        whereArgs: transactionIds,
        orderBy: 'transaction_date ASC, id ASC'
    );

    // Step 4: Replay the entire history, one transaction at a time.
    for (final transaction in transactions) {
        final transactionMap = Map<String, dynamic>.from(transaction);
        await handleFriendTransaction(txn, transactionMap, isRecalculation: true);
    }
  }


  /// Adds a repayment from a friend for a loan the user gave them.
  Future<void> addRepaymentFromFriend(
      int debtId, String description, double amount, DateTime date) async {
    final db = await _database;
    await db.transaction((txn) async {
      final debtRecord = await txn.query('friend_debts', where: 'id = ?', whereArgs: [debtId], limit: 1);
      if (debtRecord.isEmpty) return;
      final friendId = debtRecord.first['friend_id'];

      await txn.insert('transactions', {
        'description': description,
        'amount': amount,
        'type': 'Income',
        'category': 'Friend Repayment',
        'transaction_date': date.toIso8601String(),
        'friend_debt_id': debtId,
        'friend_id': friendId,
      });

      await txn.rawUpdate('''
        UPDATE friend_debts
        SET amount_paid = amount_paid + ?
        WHERE id = ?
      ''', [amount, debtId]);

      final result =
          await txn.query('friend_debts', where: 'id = ?', whereArgs: [debtId]);
      if (result.isNotEmpty) {
        final debt = result.first;
        if ((debt['amount_paid'] as num) >=
            (debt['total_amount'] as num) - 0.01) {
          await txn.update('friend_debts', {'is_closed': 1},
              where: 'id = ?', whereArgs: [debtId]);
        }
      }
    });
  }

  /// Adds a repayment to a friend for a debt the user owes.
  Future<void> addRepaymentToFriend(
      int debtId, String description, double amount, DateTime date) async {
    final db = await _database;
    await db.transaction((txn) async {
      final debtRecord = await txn.query('friend_debts', where: 'id = ?', whereArgs: [debtId], limit: 1);
      if (debtRecord.isEmpty) return;
      final friendId = debtRecord.first['friend_id'];

      await txn.insert('transactions', {
        'description': description,
        'amount': amount,
        'type': 'Expense',
        'category': 'Friends',
        'transaction_date': date.toIso8601String(),
        'friend_debt_id': debtId,
        'friend_id': friendId,
      });

      await txn.rawUpdate('''
        UPDATE friend_debts
        SET amount_paid = amount_paid + ?
        WHERE id = ?
      ''', [amount, debtId]);

      final result =
          await txn.query('friend_debts', where: 'id = ?', whereArgs: [debtId]);
      if (result.isNotEmpty) {
        final debt = result.first;
        if ((debt['amount_paid'] as num) >=
            (debt['total_amount'] as num) - 0.01) {
          await txn.update('friend_debts', {'is_closed': 1},
              where: 'id = ?', whereArgs: [debtId]);
        }
      }
    });
  }


  /// Retrieves the complete transaction history with a specific friend.
  Future<List<Map<String, dynamic>>> getFriendTransactionHistory(int friendId) async {
    final db = await _database;
    return db.query(
      'transactions',
      where: 'friend_id = ? OR friend_debt_id IN (SELECT id FROM friend_debts WHERE friend_id = ?)',
      whereArgs: [friendId, friendId],
      orderBy: 'transaction_date DESC, id DESC',
    );
  }

  /// --- REWRITTEN: This logic is now more robust and handles all edge cases. ---
  Future<void> handleFriendTransaction(
      Transaction txn, Map<String, dynamic> transactionData, {bool isRecalculation = false}) async {
    final friendId = transactionData['friend_id'] as int;
    final transactionAmount = transactionData['amount'] as double;
    final isExpense = transactionData['type'] == 'Expense';
    final isIncome = transactionData['type'] == 'Income';
    final friendNameResult = await txn.query('friends', where: 'id = ?', whereArgs: [friendId]);
    if (friendNameResult.isEmpty) return;
    final friendName = friendNameResult.first['name'] as String;

    int? finalDebtId;

    if (isExpense) { // Money paid to a friend
      final debtsYouOwe = await txn.query('friend_debts',
          where: 'friend_id = ? AND is_user_debtor = 1 AND is_closed = 0',
          whereArgs: [friendId]);

      if (debtsYouOwe.isNotEmpty) { // Repaying a debt you owe to them
        final debt = debtsYouOwe.first;
        final debtId = debt['id'] as int;
        final remainingAmount =
            (debt['total_amount'] as double) - (debt['amount_paid'] as double);

        if (transactionAmount >= remainingAmount - 0.01) {
          await txn.update(
              'friend_debts', {'amount_paid': debt['total_amount'], 'is_closed': 1},
              where: 'id = ?', whereArgs: [debtId]);

          final overpayment = transactionAmount - remainingAmount;
          if (overpayment > 0.01) {
            final newLoanId = await txn.insert('friend_debts', {
              'name': friendName, 'principal_amount': overpayment, 'total_amount': overpayment,
              'amount_paid': 0, 'is_user_debtor': 0, 'creation_date': transactionData['transaction_date'],
              'friend_id': friendId,
            });
            finalDebtId = newLoanId;
          }
        } else {
          await txn.update('friend_debts',
              {'amount_paid': (debt['amount_paid'] as double) + transactionAmount},
              where: 'id = ?', whereArgs: [debtId]);
          finalDebtId = debtId;
        }
      } else { // This is a new loan to them
        final existingLoansToFriend = await txn.query('friend_debts',
            where: 'friend_id = ? AND is_user_debtor = 0 AND is_closed = 0',
            whereArgs: [friendId]);
        if (existingLoansToFriend.isNotEmpty) {
          final loan = existingLoansToFriend.first;
          final loanId = loan['id'] as int;
          final newTotal = (loan['total_amount'] as double) + transactionAmount;
          await txn.update(
              'friend_debts', {'total_amount': newTotal, 'principal_amount': newTotal},
              where: 'id = ?', whereArgs: [loanId]);
          finalDebtId = loanId;
        } else {
          final newLoanId = await txn.insert('friend_debts', {
            'name': friendName, 'principal_amount': transactionAmount, 'total_amount': transactionAmount,
            'is_user_debtor': 0, 'creation_date': transactionData['transaction_date'], 'friend_id': friendId,
          });
          finalDebtId = newLoanId;
        }
      }
    } else if (isIncome) { // Money received from a friend
      final loansToYou = await txn.query('friend_debts',
          where: 'friend_id = ? AND is_user_debtor = 0 AND is_closed = 0',
          whereArgs: [friendId]);

      if (loansToYou.isNotEmpty) { // They are repaying a loan
        final loan = loansToYou.first;
        final loanId = loan['id'] as int;
        final remainingAmount =
            (loan['total_amount'] as double) - (loan['amount_paid'] as double);

        if (transactionAmount >= remainingAmount - 0.01) {
          await txn.update(
              'friend_debts', {'amount_paid': loan['total_amount'], 'is_closed': 1},
              where: 'id = ?', whereArgs: [loanId]);

          final overpayment = transactionAmount - remainingAmount;
          if (overpayment > 0.01) {
            final newDebtId = await txn.insert('friend_debts', {
              'name': friendName, 'principal_amount': overpayment, 'total_amount': overpayment,
              'amount_paid': 0, 'is_user_debtor': 1, 'creation_date': transactionData['transaction_date'],
              'friend_id': friendId,
            });
            finalDebtId = newDebtId;
          }
        } else {
          await txn.update('friend_debts',
              {'amount_paid': (loan['amount_paid'] as double) + transactionAmount},
              where: 'id = ?', whereArgs: [loanId]);
          finalDebtId = loanId;
        }
      } else { // This is a new debt you owe them
        final existingDebtsToFriend = await txn.query('friend_debts',
            where: 'friend_id = ? AND is_user_debtor = 1 AND is_closed = 0',
            whereArgs: [friendId]);
        if (existingDebtsToFriend.isNotEmpty) {
          final debt = existingDebtsToFriend.first;
          final debtId = debt['id'] as int;
          final newTotal = (debt['total_amount'] as double) + transactionAmount;
          await txn.update(
              'friend_debts', {'total_amount': newTotal, 'principal_amount': newTotal},
              where: 'id = ?', whereArgs: [debtId]);
          finalDebtId = debtId;
        } else {
          final newDebtId = await txn.insert('friend_debts', {
            'name': friendName, 'principal_amount': transactionAmount, 'total_amount': transactionAmount,
            'is_user_debtor': 1, 'creation_date': transactionData['transaction_date'], 'friend_id': friendId,
          });
          finalDebtId = newDebtId;
        }
      }
    }

    if (isRecalculation) {
        await txn.update('transactions', {'friend_debt_id': finalDebtId}, where: 'id = ?', whereArgs: [transactionData['id']]);
    } else {
        transactionData['friend_debt_id'] = finalDebtId;
        await txn.insert('transactions', transactionData);
    }
  }
}
