import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all analytics-related database queries.
class AnalyticsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// Parses the raw query result into a map of totals by type.
  Map<String, double> _parseTotals(List<Map<String, dynamic>> result) {
    final Map<String, double> totals = {
      'Income': 0.0,
      'Expense': 0.0,
      'Saving': 0.0
    };
    for (var row in result) {
      if (row['type'] != null && totals.containsKey(row['type'])) {
        totals[row['type']] = (row['total'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return totals;
  }

  /// Gets the total income, expense, and savings for a specific month and year.
  Future<Map<String, double>> getTotalsForPeriod(int year, int month) async {
    Database db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT type, SUM(amount) as total FROM transactions WHERE strftime('%Y-%m', transaction_date) = ? AND NOT (type = 'Income' AND category = 'From Savings') GROUP BY type",
        [period]);
    return _parseTotals(result);
  }

  /// Gets the total income, expense, and savings for a specific year.
  Future<Map<String, double>> getTotalsForYear(int year) async {
    Database db = await _database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
        "SELECT type, SUM(amount) as total FROM transactions WHERE strftime('%Y', transaction_date) = ? AND NOT (type = 'Income' AND category = 'From Savings') GROUP BY type",
        [year.toString()]);
    return _parseTotals(result);
  }

  /// Gets the cumulative totals for all transactions up to a given month and year.
  Future<Map<String, double>> getTotalsUpToPeriod(int year, int month) async {
    Database db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT type, SUM(amount) as total FROM transactions WHERE strftime('%Y-%m', transaction_date) <= ? AND NOT (type = 'Income' AND category = 'From Savings') GROUP BY type",
      [period],
    );
    return _parseTotals(result);
  }

  /// Gets the breakdown of all expenses by category for a specific month and year.
  Future<List<Map<String, dynamic>>> getCategoryBreakdownForPeriod(
      int year, int month) async {
    Database db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    return await db.rawQuery(
        "SELECT category, SUM(amount) as total FROM transactions WHERE type = 'Expense' AND strftime('%Y-%m', transaction_date) = ? GROUP BY category ORDER BY total DESC",
        [period]);
  }
  
  /// Gets the breakdown of expenses by sub-category for a specific category, month, and year.
  Future<List<Map<String, dynamic>>> getSubCategoryBreakdownForMonth(int year, int month, String category) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    return await db.rawQuery('''
      SELECT 
        sub_category, 
        SUM(amount) as total
      FROM transactions 
      WHERE 
        type = 'Expense' AND 
        strftime('%Y-%m', transaction_date) = ? AND 
        category = ? AND
        sub_category IS NOT NULL AND 
        sub_category != ''
      GROUP BY sub_category 
      ORDER BY total DESC
    ''', [period, category]);
  }

  /// Gets the breakdown of all expenses by category for a specific year.
  Future<List<Map<String, dynamic>>> getCategoryBreakdownForYear(
      int year) async {
    Database db = await _database;
    return await db.rawQuery(
        "SELECT category, SUM(amount) as total FROM transactions WHERE type = 'Expense' AND strftime('%Y', transaction_date) = ? GROUP BY category ORDER BY total DESC",
        [year.toString()]);
  }

  /// Gets the total expense for each month in a given year.
  Future<List<Map<String, dynamic>>> getMonthlyExpenseTotalsForYear(int year) async {
    final db = await _database;
    return db.rawQuery('''
      SELECT 
        strftime('%m', transaction_date) as month,
        SUM(amount) as total
      FROM transactions
      WHERE type = 'Expense' AND strftime('%Y', transaction_date) = ?
      GROUP BY month
      ORDER BY month ASC
    ''', [year.toString()]);
  }

  /// Gets the monthly breakdown of income, expenses, and savings for a given year.
  Future<List<Map<String, dynamic>>> getMonthlyBreakdownForYear(int year) async {
    Database db = await _database;
    return await db.rawQuery('''
      SELECT 
        strftime('%m', transaction_date) as month,
        type,
        SUM(amount) as total
      FROM transactions
      WHERE strftime('%Y', transaction_date) = ? AND NOT (type = 'Income' AND category = 'From Savings')
      GROUP BY month, type
      ORDER BY month, type
    ''', [year.toString()]);
  }

  /// Finds the highest or lowest transaction of a certain type for a given period.
  Future<Map<String, dynamic>?> getExtremeTransaction(
      String type, int year, int month,
      {required bool highest}) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    final String orderBy = highest ? 'DESC' : 'ASC';

    final result = await db.query(
      'transactions',
      where: "type = ? AND strftime('%Y-%m', transaction_date) = ?",
      whereArgs: [type, period],
      orderBy: 'amount $orderBy',
      limit: 1,
    );

    return result.isNotEmpty ? result.first : null;
  }

  /// NEW: Gets the breakdown of debt repayments by debt name for a specific month and year.
  Future<List<Map<String, dynamic>>> getDebtRepaymentBreakdownForMonth(int year, int month) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    return await db.rawQuery('''
      SELECT 
        d.name, 
        SUM(t.amount) as total
      FROM transactions t
      JOIN debts d ON t.debt_id = d.id
      WHERE 
        t.category = 'Debt Repayment' AND 
        strftime('%Y-%m', t.transaction_date) = ?
      GROUP BY d.name 
      ORDER BY total DESC
    ''', [period]);
  }

  /// NEW: Gets the breakdown of expenses to friends by friend name for a specific month and year.
  Future<List<Map<String, dynamic>>> getFriendExpenseBreakdownForMonth(int year, int month) async {
    final db = await _database;
    final String period = '$year-${month.toString().padLeft(2, '0')}';
    return await db.rawQuery('''
      SELECT 
        f.name, 
        SUM(t.amount) as total
      FROM transactions t
      JOIN friends f ON t.friend_id = f.id
      WHERE 
        t.category = 'Friends' AND
        t.type = 'Expense' AND 
        strftime('%Y-%m', t.transaction_date) = ?
      GROUP BY f.name 
      ORDER BY total DESC
    ''', [period]);
  }
}
