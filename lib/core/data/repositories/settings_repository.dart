import 'package:flynse/core/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Repository for handling all app settings-related database queries.
class SettingsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Database> get _database async => _dbHelper.database;

  /// Saves a key-value setting to the database.
  Future<void> saveSetting(String key, String value) async {
    final db = await _database;
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a setting value by its key.
  Future<String?> getSetting(String key) async {
    final db = await _database;
    final List<Map<String, dynamic>> result = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  /// Saves the user's PIN.
  Future<void> savePin(String pin) async {
    await saveSetting('app_pin', pin);
  }

  /// Retrieves the user's saved PIN.
  Future<String?> getPin() async {
    return await getSetting('app_pin');
  }

  /// Deletes the user's PIN from the database.
  Future<void> deletePin() async {
    final db = await _database;
    await db.delete('app_settings', where: 'key = ?', whereArgs: ['app_pin']);
  }
  
  /// Saves the user's profile image as a base64 string.
  Future<void> saveProfileImage(String base64Image) async {
    await saveSetting('profile_image', base64Image);
  }

  /// Retrieves the user's profile image.
  Future<String?> getProfileImage() async {
    return await getSetting('profile_image');
  }
}
