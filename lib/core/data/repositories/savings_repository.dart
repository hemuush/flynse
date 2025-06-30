import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Repository for handling all savings-related database queries.
class SavingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// Adds a new savings goal or updates the existing active one.
  Future<void> addOrUpdateSavingsGoal(Map<String, dynamic> goal) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.delete('savings_goals', where: 'is_completed = 0');
      await txn.insert('savings_goals', goal);
    });
  }

  /// Retrieves the current active (not completed) savings goal.
  Future<Map<String, dynamic>?> getActiveSavingsGoal() async {
    final db = await _database;
    final result =
        await db.query('savings_goals', where: 'is_completed = 0', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  /// Marks a savings goal as completed.
  Future<void> completeSavingsGoal(int id) async {
    final db = await _database;
    await db.update('savings_goals', {'is_completed': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a savings goal by its ID.
  Future<void> deleteSavingsGoal(int id) async {
    final db = await _database;
    await db.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves data for plotting the growth of savings over time.
  Future<List<Map<String, dynamic>>> getSavingsGrowthData() async {
    final db = await _database;
    return db.rawQuery('''
      SELECT
        t.transaction_date as date,
        (SELECT SUM(t2.amount)
         FROM transactions t2
         WHERE t2.type = 'Saving' AND date(t2.transaction_date) <= date(t.transaction_date)) as amount
      FROM transactions t
      WHERE t.type = 'Saving'
      GROUP BY date(t.transaction_date)
      ORDER BY t.transaction_date ASC
    ''');
  }

  /// Calculates the total current savings amount.
  Future<double> getTotalSavings() async {
    final db = await _database;
    final result = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'Saving'");
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Gets the cumulative total savings up to a given month and year.
  Future<double> getTotalSavingsUpToPeriod(int year, int month) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'Saving' AND strftime('%Y-%m', transaction_date) <= ?",
      [period],
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// Retrieves all transactions of type 'Saving'.
  Future<List<Map<String, dynamic>>> getSavingsTransactions() async {
    final db = await _database;
    return db.query('transactions',
        where: 'type = ?',
        whereArgs: ['Saving'],
        orderBy: 'transaction_date DESC, id DESC');
  }

  /// Retrieves the yearly breakdown of total savings.
  Future<List<Map<String, dynamic>>> getYearlySavings() async {
    final db = await _database;
    return await db.rawQuery('''
      SELECT
        strftime('%Y', transaction_date) as year,
        SUM(amount) as total_savings
      FROM transactions
      WHERE type = 'Saving'
      GROUP BY year
      ORDER BY year DESC
    ''');
  }

  /// Creates a transaction to reflect using savings for an expense.
  /// This now creates a paired transaction: a negative 'Saving' and a positive 'Income'
  /// to ensure the net balance is calculated correctly on the dashboard.
  Future<void> useSavings(double amount, String category, [String? description, DateTime? date]) async {
    final db = await _database;
    await db.transaction((txn) async {
      final transactionDate = (date ?? DateTime.now()).toIso8601String();
      final pairId = const Uuid().v4();

      // Transaction 1: The expense from savings (a negative saving)
      await txn.insert('transactions', {
        'description': description ?? 'Used Savings',
        'amount': -amount,
        'type': 'Saving',
        'category': category, // Use the provided category
        'transaction_date': transactionDate,
        'pair_id': pairId,
      });

      // Transaction 2: The corresponding income transaction
      await txn.insert('transactions', {
        'description': 'Transfer from Savings',
        'amount': amount,
        'type': 'Income',
        'category': 'From Savings', // A new category to represent this transfer
        'transaction_date': transactionDate,
        'pair_id': pairId,
      });
    });
  }

  /// NEW METHOD: Retrieves savings grouped by category.
  Future<List<Map<String, dynamic>>> getSavingsByCategory() async {
    final db = await _database;
    return db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE type = 'Saving'
      GROUP BY category
      HAVING total > 0
      ORDER BY total DESC
    ''');
  }
}