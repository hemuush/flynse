import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all transaction-related database queries.
class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// Inserts a single transaction into the database.
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await _database;
    return await db.insert('transactions', row);
  }

  /// Inserts multiple transactions, handling special logic for friend-related transactions.
  Future<void> insertMultipleTransactions(
      List<Map<String, dynamic>> rows) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (var row in rows) {
        // The logic to automatically create/update debts for friend transactions
        // is complex and better handled in the DebtRepository to keep concerns separate.
        // For now, we assume the logic here is intended.
        if (row['category'] == 'Friends' && row['friend_id'] != null) {
          await _handleFriendTransaction(txn, row);
        } else {
          await txn.insert('transactions', row);
        }
      }
    });
  }

  /// Updates an existing transaction in the database.
  Future<int> updateTransaction(Map<String, dynamic> row) async {
    Database db = await _database;
    int id = row['id'];
    return await db
        .update('transactions', row, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a transaction and handles all related data integrity updates.
  /// This method is refactored for clarity and correctness.
  Future<int> deleteTransaction(int id) async {
    final db = await _database;
    return await db.transaction((txn) async {
      // Step 1: Get the transaction details BEFORE deleting it.
      final transactions =
          await txn.query('transactions', where: 'id = ?', whereArgs: [id]);

      if (transactions.isEmpty) {
        return 0; // Transaction doesn't exist.
      }
      final transaction = transactions.first;

      // Step 2: Handle special cases based on transaction properties.

      // Case A: Paired Transaction (e.g., "Use Savings")
      // These have a `pair_id` and both sides must be deleted together.
      final String? pairId = transaction['pair_id'] as String?;
      if (pairId != null) {
        return await txn
            .delete('transactions', where: 'pair_id = ?', whereArgs: [pairId]);
      }

      // Case B: Debt-Related Transaction
      // These have a `debt_id` and require updating the corresponding debt record.
      final int? debtId = transaction['debt_id'] as int?;
      if (debtId != null) {
        await _handleDebtReversalOnDelete(txn, transaction);
      }

      // Step 3: Delete the original transaction record.
      return await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Private helper to manage all debt-related reversals when a transaction is deleted.
  /// This keeps the main `deleteTransaction` method clean.
  Future<void> _handleDebtReversalOnDelete(
      Transaction txn, Map<String, dynamic> transaction) async {
    final double amount = transaction['amount'] as double;
    final int debtId = transaction['debt_id'] as int;
    final String type = transaction['type'] as String;
    final String category = transaction['category'] as String;

    // Scenario 1: The transaction was the CREATION of a formal loan.
    // Deleting it should remove the entire loan and all its associated repayments.
    if (type == 'Income' && category == 'Loan') {
      await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
      await txn.delete('transactions', where: 'debt_id = ?', whereArgs: [debtId]);
      return;
    }
    
    // Scenario 2: The transaction was a formal REPAYMENT on a debt.
    // Deleting it should subtract the amount from `amount_paid` and reopen the debt.
    if (category == 'Debt Repayment' || category == 'Friend Repayment') {
      await txn.rawUpdate('''
        UPDATE debts
        SET amount_paid = amount_paid - ?,
            is_closed = 0
        WHERE id = ?
      ''', [amount, debtId]);
      return;
    }
    
    // Scenario 3 (THE FIX): The transaction was a simple "Friends" entry that
    // automatically created or updated a debt. Deleting it should reverse this change.
    if (category == 'Friends') {
      // This transaction either created or increased a debt. We reverse it by subtracting the amount.
      await txn.rawUpdate('''
        UPDATE debts
        SET total_amount = total_amount - ?,
            principal_amount = principal_amount - ?
        WHERE id = ?
      ''', [amount, amount, debtId]);

      // After reversal, check if the debt is now empty and should be deleted.
      final updatedDebtList = await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (updatedDebtList.isNotEmpty) {
        final updatedDebt = updatedDebtList.first;
        // Use a small tolerance for floating-point inaccuracies.
        if ((updatedDebt['total_amount'] as double) <= 0.01) {
          await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
        }
      }
      return;
    }
  }


  /// Retrieves a list of transactions based on various filters.
  Future<List<Map<String, dynamic>>> getFilteredTransactions({
    String? type,
    int? year,
    int? month,
    String? sortBy,
    bool ascending = false,
    String? query,
    int? limit,
  }) async {
    final db = await _database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    String sql = '''
      SELECT t.*, f.name as friend_name
      FROM transactions t
      LEFT JOIN friends f ON t.friend_id = f.id
    ''';

    if (type != null && type != 'All') {
      whereClauses.add('t.type = ?');
      whereArgs.add(type);
    }

    if (year != null) {
      if (month != null) {
        // Filter by year and month
        final String period = '$year-${month.toString().padLeft(2, '0')}';
        whereClauses.add("strftime('%Y-%m', t.transaction_date) = ?");
        whereArgs.add(period);
      } else {
        // Filter only by year
        whereClauses.add("strftime('%Y', t.transaction_date) = ?");
        whereArgs.add(year.toString());
      }
    }

    if (query != null && query.isNotEmpty) {
      whereClauses.add(
          '(t.description LIKE ? OR t.category LIKE ? OR t.sub_category LIKE ? OR f.name LIKE ?)');
      whereArgs.add('%$query%');
      whereArgs.add('%$query%');
      whereArgs.add('%$query%');
      whereArgs.add('%$query%');
    }

    if (whereClauses.isNotEmpty) {
      sql += ' WHERE ${whereClauses.join(' AND ')}';
    }

    String orderByClause;
    if (sortBy == 'amount') {
      orderByClause = 't.amount ${ascending ? 'ASC' : 'DESC'}';
    } else {
      orderByClause =
          't.transaction_date ${ascending ? 'ASC' : 'DESC'}, t.id ${ascending ? 'ASC' : 'DESC'}';
    }

    sql += ' ORDER BY $orderByClause';

    if (limit != null) {
      sql += ' LIMIT $limit';
    }

    return await db.rawQuery(sql, whereArgs);
  }

  /// NEW: Retrieves the complete transaction history with a specific friend.
  Future<List<Map<String, dynamic>>> getFriendTransactionHistory(int friendId) async {
    final db = await _database;
    // This query now correctly joins all transactions linked via friend_id OR a debt linked to the friend_id
    return db.query(
      'transactions',
      where: 'friend_id = ? OR debt_id IN (SELECT id FROM debts WHERE friend_id = ?)',
      whereArgs: [friendId, friendId],
      orderBy: 'transaction_date DESC',
    );
  }

  /// Deletes all transactions for a specific month and year, ensuring data integrity.
  Future<void> deleteTransactionsForMonth(int year, int month) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      // Get all transactions for the month before deleting them
      final transactionsToDelete = await txn.query(
        'transactions',
        where: "strftime('%Y-%m', transaction_date) = ?",
        whereArgs: [period],
      );

      // Use a Set to avoid trying to delete the same ID multiple times.
      final Set<int> idsToDelete = {};

      for (var transaction in transactionsToDelete) {
        final id = transaction['id'] as int;
        if (idsToDelete.contains(id)) continue;

        final double amount = transaction['amount'] as double;
        final int? debtId = transaction['debt_id'] as int?;
        final String? pairId = transaction['pair_id'] as String?;
        final String type = transaction['type'] as String;
        final String category = transaction['category'] as String;

        // Case 1: Handle paired transactions (e.g., Use Savings)
        if (pairId != null) {
          final pairedTransactions = await txn
              .query('transactions', where: 'pair_id = ?', whereArgs: [pairId]);
          for (var pairedTx in pairedTransactions) {
            idsToDelete.add(pairedTx['id'] as int);
          }
          // Case 2: Handle transactions linked to a debt
        } else if (debtId != null) {
          final debtResults =
              await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
          if (debtResults.isEmpty) {
            idsToDelete.add(id);
            continue;
          }
          final debt = debtResults.first;
          final isUserDebtor = debt['is_user_debtor'] == 1;
          final creationDate =
              DateTime.parse(debt['creation_date'] as String);

          final isCreationTransaction = ((type == 'Income' &&
                      category == 'Loan' &&
                      isUserDebtor) ||
                  (type == 'Expense' &&
                      category == 'Friends' &&
                      !isUserDebtor)) &&
              (creationDate.year == year && creationDate.month == month);

          // Subcase 2.1: This transaction created the debt in the deleted month
          if (isCreationTransaction) {
            final relatedTransactions = await txn
                .query('transactions', where: 'debt_id = ?', whereArgs: [debtId]);
            for (var relatedTx in relatedTransactions) {
              idsToDelete.add(relatedTx['id'] as int);
            }
            await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);

            // Subcase 2.2: This is a repayment on an existing debt
          } else if (category == 'Debt Repayment' ||
              category == 'Friend Repayment') {
            await txn.rawUpdate('''
                    UPDATE debts
                    SET amount_paid = amount_paid - ?,
                        is_closed = 0
                    WHERE id = ?
                ''', [amount, debtId]);
            idsToDelete.add(id);
            // Subcase 2.3: Any other linked transaction (should be rare, but handle defensively)
          } else {
            idsToDelete.add(id);
          }
          // Case 3: Handle standard, unlinked transactions
        } else {
          idsToDelete.add(id);
        }
      }

      // Finally, perform a single bulk deletion
      if (idsToDelete.isNotEmpty) {
        await txn.delete(
          'transactions',
          where: 'id IN (${List.filled(idsToDelete.length, '?').join(',')})',
          whereArgs: idsToDelete.toList(),
        );
      }
    });
  }

  /// Deletes all user data by resetting the database.
  Future<void> deleteAllData() async {
    await _dbHelper.resetDatabase();
  }

  /// Private helper to handle the logic of creating or updating debts when a transaction with a friend occurs.
  Future<void> _handleFriendTransaction(
      Transaction txn, Map<String, dynamic> transactionData) async {
    final friendId = transactionData['friend_id'] as int;
    final transactionAmount = transactionData['amount'] as double;
    final isExpense = transactionData['type'] == 'Expense';
    final isIncome = transactionData['type'] == 'Income';
    final friendName =
        (await txn.query('friends', where: 'id = ?', whereArgs: [friendId]))
            .first['name'] as String;

    int? finalDebtId;

    if (isExpense) {
      // Money paid to a friend
      final debtsYouOwe = await txn.query('debts',
          where: 'friend_id = ? AND is_user_debtor = 1 AND is_closed = 0',
          whereArgs: [friendId]);

      if (debtsYouOwe.isNotEmpty) {
        // If you already owe them money (this is a repayment)
        final debt = debtsYouOwe.first;
        final debtId = debt['id'] as int;
        final remainingAmount =
            (debt['total_amount'] as double) - (debt['amount_paid'] as double);

        if (transactionAmount >= remainingAmount) {
          // If this payment clears the debt
          await txn.update(
              'debts', {'amount_paid': debt['total_amount'], 'is_closed': 1},
              where: 'id = ?', whereArgs: [debtId]);

          final overpayment = transactionAmount - remainingAmount;
          if (overpayment > 0) {
            // If you overpaid, it becomes a new loan to them
            final newLoanId = await txn.insert('debts', {
              'name': friendName,
              'principal_amount': overpayment,
              'total_amount': overpayment,
              'amount_paid': 0,
              'is_user_debtor': 0,
              'creation_date': transactionData['transaction_date'],
              'friend_id': friendId,
            });
            finalDebtId = newLoanId;
          }
        } else {
          // Partial repayment
          await txn.update('debts',
              {'amount_paid': (debt['amount_paid'] as double) + transactionAmount},
              where: 'id = ?', whereArgs: [debtId]);
          finalDebtId = debtId;
        }
      } else {
        // You didn't owe them, so this is a new loan. Check if one to them already exists.
        final existingLoansToFriend = await txn.query('debts',
            where: 'friend_id = ? AND is_user_debtor = 0 AND is_closed = 0',
            whereArgs: [friendId]);
        if (existingLoansToFriend.isNotEmpty) {
          // Aggregate with existing loan
          final loan = existingLoansToFriend.first;
          final loanId = loan['id'] as int;
          final newPrincipal =
              (loan['principal_amount'] as double) + transactionAmount;
          await txn.update(
              'debts', {'total_amount': newPrincipal, 'principal_amount': newPrincipal},
              where: 'id = ?', whereArgs: [loanId]);
          finalDebtId = loanId;
        } else {
          // Create a new loan record
          final newLoanId = await txn.insert('debts', {
            'name': friendName,
            'principal_amount': transactionAmount,
            'total_amount': transactionAmount,
            'is_user_debtor': 0,
            'creation_date': transactionData['transaction_date'],
            'friend_id': friendId,
          });
          finalDebtId = newLoanId;
        }
      }
    } else if (isIncome) {
      // Money received from a friend
      final loansToYou = await txn.query('debts',
          where: 'friend_id = ? AND is_user_debtor = 0 AND is_closed = 0',
          whereArgs: [friendId]);

      if (loansToYou.isNotEmpty) {
        // If they already owed you money
        final loan = loansToYou.first;
        final loanId = loan['id'] as int;
        final remainingAmount =
            (loan['total_amount'] as double) - (loan['amount_paid'] as double);

        if (transactionAmount >= remainingAmount) {
          // If this payment clears their loan
          await txn.update(
              'debts', {'amount_paid': loan['total_amount'], 'is_closed': 1},
              where: 'id = ?', whereArgs: [loanId]);

          final overpayment = transactionAmount - remainingAmount;
          if (overpayment > 0) {
            // If they overpaid, you now owe them
            final newDebtId = await txn.insert('debts', {
              'name': friendName,
              'principal_amount': overpayment,
              'total_amount': overpayment,
              'amount_paid': 0,
              'is_user_debtor': 1,
              'creation_date': transactionData['transaction_date'],
              'friend_id': friendId,
            });
            finalDebtId = newDebtId;
          }
        } else {
          // Partial repayment from them
          await txn.update('debts',
              {'amount_paid': (loan['amount_paid'] as double) + transactionAmount},
              where: 'id = ?', whereArgs: [loanId]);
          finalDebtId = loanId;
        }
      } else {
        // They didn't owe you, so this is a new debt you owe them. Check if one exists.
        final existingDebtsToFriend = await txn.query('debts',
            where: 'friend_id = ? AND is_user_debtor = 1 AND is_closed = 0',
            whereArgs: [friendId]);
        if (existingDebtsToFriend.isNotEmpty) {
          // Aggregate with existing debt
          final debt = existingDebtsToFriend.first;
          final debtId = debt['id'] as int;
          final newPrincipal =
              (debt['principal_amount'] as double) + transactionAmount;
          await txn.update(
              'debts', {'total_amount': newPrincipal, 'principal_amount': newPrincipal},
              where: 'id = ?', whereArgs: [debtId]);
          finalDebtId = debtId;
        } else {
          // Create a new debt record
          final newDebtId = await txn.insert('debts', {
            'name': friendName,
            'principal_amount': transactionAmount,
            'total_amount': transactionAmount,
            'is_user_debtor': 1,
            'creation_date': transactionData['transaction_date'],
            'friend_id': friendId,
          });
          finalDebtId = newDebtId;
        }
      }
    }

    transactionData['debt_id'] = finalDebtId;
    await txn.insert('transactions', transactionData);
  }
}
