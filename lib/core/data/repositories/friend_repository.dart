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

  /// Deletes a friend and disassociates them from transactions.
  /// Note: This does not delete the friend if they have pending debts.
  /// That check is handled in the UI layer before calling this method.
  Future<void> deleteFriend(int friendId) async {
    final db = await _database;
    await db.transaction((txn) async {
      // Disassociate friend from transactions to preserve history
      await txn.update('transactions', {'friend_id': null}, where: 'friend_id = ?', whereArgs: [friendId]);
      // Delete the friend record
      await txn.delete('friends', where: 'id = ?', whereArgs: [friendId]);
    });
  }
}
