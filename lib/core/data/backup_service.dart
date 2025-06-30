import 'dart:io';
import 'package:flynse/core/data/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  
  /// Performs a backup of the database to the specified location.
  /// 
  /// This method is now simplified and relies only on the backup path being set.
  static Future<bool> performBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupPath = prefs.getString('backup_location');

      // The backup now only depends on a path being set.
      if (backupPath == null) {
        // No backup location is set.
        return false;
      }

      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDbPath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        // The source database file doesn't exist.
        return false;
      }
      
      final backupDir = Directory(backupPath);
      // Ensure the backup directory exists.
       if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
       }

      final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final newPath = '$backupPath/flynse_backup_$formattedDate.db';
      await dbFile.copy(newPath);
      
      return true; // Backup successful
    } catch (e) {
      // Catch any potential exceptions during the backup process.
      return false;
    }
  }
}