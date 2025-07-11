import 'package:flynse/core/data/database_helper.dart';
import 'package:flynse/core/data/repositories/friend_repository.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all transaction-related database queries.
class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  // Instantiate FriendRepository to delegate friend-related logic.
  final FriendRepository _friendRepo = FriendRepository();

  Future<Database> get _database async => _dbHelper.database;

  /// Inserts a single transaction into the database.
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    Database db = await _database;
    return await db.insert('transactions', row);
  }

  /// Inserts multiple transactions, delegating friend-related logic.
  Future<void> insertMultipleTransactions(
      List<Map<String, dynamic>> rows) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (var row in rows) {
        if (row['category'] == 'Friends' && row['friend_id'] != null) {
          // Delegate the complex logic to the FriendRepository
          await _friendRepo.handleFriendTransaction(txn, row);
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
  Future<int> deleteTransaction(int id) async {
    final db = await _database;
    return await db.transaction((txn) async {
      final transactions =
          await txn.query('transactions', where: 'id = ?', whereArgs: [id]);

      if (transactions.isEmpty) {
        return 0; // Transaction doesn't exist.
      }
      final transaction = transactions.first;

      final String? pairId = transaction['pair_id'] as String?;
      if (pairId != null) {
        return await txn
            .delete('transactions', where: 'pair_id = ?', whereArgs: [pairId]);
      }

      final int? debtId = transaction['debt_id'] as int?;
      if (debtId != null) {
        await _handleDebtReversalOnDelete(txn, transaction);
      }

      return await txn.delete('transactions', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Private helper to manage all debt-related reversals when a transaction is deleted.
  Future<void> _handleDebtReversalOnDelete(
      Transaction txn, Map<String, dynamic> transaction) async {
    final double amount = transaction['amount'] as double;
    final int debtId = transaction['debt_id'] as int;
    final String type = transaction['type'] as String;
    final String category = transaction['category'] as String;

    // Scenario 1: The transaction was the CREATION of a formal loan.
    if (type == 'Income' && category == 'Loan') {
      await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
      await txn.delete('transactions', where: 'debt_id = ?', whereArgs: [debtId]);
      return;
    }
    
    // Scenario 2: The transaction was a REPAYMENT on a debt (personal or friend).
    if (category == 'Debt Repayment' || category == 'Friend Repayment') {
      await txn.rawUpdate('''
        UPDATE debts
        SET amount_paid = amount_paid - ?,
            is_closed = 0
        WHERE id = ?
      ''', [amount, debtId]);
      return;
    }
    
    // Scenario 3: The transaction was a simple "Friends" entry that created/updated a debt.
    if (category == 'Friends') {
      await txn.rawUpdate('''
        UPDATE debts
        SET total_amount = total_amount - ?,
            principal_amount = principal_amount - ?
        WHERE id = ?
      ''', [amount, amount, debtId]);

      final updatedDebtList = await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
      if (updatedDebtList.isNotEmpty) {
        final updatedDebt = updatedDebtList.first;
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
        final String period = '$year-${month.toString().padLeft(2, '0')}';
        whereClauses.add("strftime('%Y-%m', t.transaction_date) = ?");
        whereArgs.add(period);
      } else {
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

  /// Deletes all transactions for a specific month and year.
  Future<void> deleteTransactionsForMonth(int year, int month) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';

    await db.transaction((txn) async {
      final transactionsToDelete = await txn.query(
        'transactions',
        where: "strftime('%Y-%m', transaction_date) = ?",
        whereArgs: [period],
      );

      final Set<int> idsToDelete = {};

      for (var transaction in transactionsToDelete) {
        final id = transaction['id'] as int;
        if (idsToDelete.contains(id)) continue;

        final int? debtId = transaction['debt_id'] as int?;
        final String? pairId = transaction['pair_id'] as String?;
        final String type = transaction['type'] as String;
        final String category = transaction['category'] as String;

        if (pairId != null) {
          final pairedTransactions = await txn
              .query('transactions', where: 'pair_id = ?', whereArgs: [pairId]);
          for (var pairedTx in pairedTransactions) {
            idsToDelete.add(pairedTx['id'] as int);
          }
        } else if (debtId != null) {
          final debtResults =
              await txn.query('debts', where: 'id = ?', whereArgs: [debtId]);
          if (debtResults.isEmpty) {
            idsToDelete.add(id);
            continue;
          }
          final debt = debtResults.first;
          final creationDate =
              DateTime.parse(debt['creation_date'] as String);

          final isCreationTransaction = (type == 'Income' && category == 'Loan') &&
              (creationDate.year == year && creationDate.month == month);

          if (isCreationTransaction) {
            final relatedTransactions = await txn
                .query('transactions', where: 'debt_id = ?', whereArgs: [debtId]);
            for (var relatedTx in relatedTransactions) {
              idsToDelete.add(relatedTx['id'] as int);
            }
            await txn.delete('debts', where: 'id = ?', whereArgs: [debtId]);
          } else {
             // For simplicity, we just delete the transaction and let the user handle debt reconciliation manually.
             // A more robust solution might reverse the payment.
            idsToDelete.add(id);
          }
        } else {
          idsToDelete.add(id);
        }
      }

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
}
