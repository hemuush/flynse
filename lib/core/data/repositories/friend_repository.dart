import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all friend-related database queries.
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

  /// Updates the avatar for a friend.
  Future<void> updateFriendAvatar(int id, String avatar) async {
    final db = await _database;
    await db.update('friends', {'avatar': avatar}, where: 'id = ?', whereArgs: [id]);
  }

  /// Checks if a friend has any pending (unclosed) debts.
  Future<bool> hasPendingDebts(int friendId) async {
    final db = await _database;
    final result = await db.query(
      'debts',
      where: 'friend_id = ? AND is_closed = 0',
      whereArgs: [friendId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Deletes a friend and disassociates them from transactions.
  Future<void> deleteFriend(int friendId) async {
    final db = await _database;
    await db.transaction((txn) async {
      await txn.update('transactions', {'friend_id': null}, where: 'friend_id = ?', whereArgs: [friendId]);
      await txn.delete('friends', where: 'id = ?', whereArgs: [friendId]);
    });
  }

  /// Retrieves the complete transaction history with a specific friend.
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
}