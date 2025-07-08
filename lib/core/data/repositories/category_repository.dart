import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all category and sub-category related database queries.
class CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// Retrieves a list of categories for a given transaction type.
  Future<List<Map<String, dynamic>>> getCategories(String type,
      {String? filter}) async {
    final db = await _database;
    String where = 'type = ?';
    List<dynamic> whereArgs = [type];
    if (filter != null && filter.isNotEmpty) {
      where += ' AND name LIKE ?';
      whereArgs.add('%$filter%');
    }
    return await db.query('categories',
        where: where, whereArgs: whereArgs, orderBy: 'name');
  }

  /// Inserts a new category into the database.
  Future<int> insertCategory(Map<String, dynamic> row) async {
    final db = await _database;
    return await db.insert('categories', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Deletes a category from the database by its ID.
  Future<int> deleteCategory(int id) async {
    final db = await _database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  /// Retrieves a list of sub-categories for a given category ID.
  Future<List<Map<String, dynamic>>> getSubCategories(int categoryId,
      {String? filter}) async {
    final db = await _database;
    String? where = 'category_id = ?';
    List<dynamic> whereArgs = [categoryId];

    if (filter != null && filter.isNotEmpty) {
      where += ' AND name LIKE ?';
      whereArgs.add('%$filter%');
    }
    return await db.query('sub_categories',
        where: where, whereArgs: whereArgs, orderBy: 'name');
  }

  /// Inserts a new sub-category into the database.
  Future<int> insertSubCategory(Map<String, dynamic> row) async {
    final db = await _database;
    return await db.insert('sub_categories', row);
  }

  /// Deletes a sub-category from the database by its ID.
  Future<int> deleteSubCategory(int id) async {
    final db = await _database;
    return await db.delete('sub_categories', where: 'id = ?', whereArgs: [id]);
  }
  
  // --- NEW METHOD ---
  /// Moves a sub-category to a new parent category and updates all associated transactions.
  Future<void> moveSubCategory({
    required int subCategoryId,
    required String subCategoryName,
    required String oldParentCategoryName,
    required int newParentCategoryId,
    required String newParentCategoryName,
  }) async {
    final db = await _database;
    await db.transaction((txn) async {
      // Step 1: Update the parent category for the sub-category itself.
      await txn.update(
        'sub_categories',
        {'category_id': newParentCategoryId},
        where: 'id = ?',
        whereArgs: [subCategoryId],
      );

      // Step 2: Find all transactions with the old category and specific sub-category and update them.
      await txn.update(
        'transactions',
        {'category': newParentCategoryName},
        where: 'category = ? AND sub_category = ?',
        whereArgs: [oldParentCategoryName, subCategoryName],
      );
    });
  }
}
