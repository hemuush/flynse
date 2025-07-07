import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flynse/core/data/backup_service.dart';
import 'package:flynse/core/data/repositories/settings_repository.dart';
import 'package:flynse/core/data/repositories/transaction_repository.dart';
import 'package:flynse/core/routing/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SettingsRepository _settingsRepo = SettingsRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  String _userName = '';
  String get userName => _userName;

  String? _profileImageBase64;
  String? get profileImageBase64 => _profileImageBase64;

  // MODIFICATION: Renamed properties to reflect they are seed colors for the theme
  Color? _seedColorLight;
  Color? get seedColorLight => _seedColorLight;
  Color? _seedColorDark;
  Color? get seedColorDark => _seedColorDark;

  String _autoBackupFrequency = 'Off';
  String get autoBackupFrequency => _autoBackupFrequency;

  String _salaryCycle = 'start_of_month';
  String get salaryCycle => _salaryCycle;

  // Helper method to load a color from settings
  Future<Color?> _loadColor(String key) async {
    final colorStr = await _settingsRepo.getSetting(key);
    if (colorStr != null) {
      try {
        return Color(int.parse(colorStr, radix: 16));
      } catch (e) {
        log("Error parsing color for key $key: $e");
        return null;
      }
    }
    return null;
  }

  Future<void> loadAppSettings() async {
    await loadUserNameAndProfile();
    final prefs = await SharedPreferences.getInstance();
    _autoBackupFrequency = prefs.getString('autoBackupFrequency') ?? 'Off';
    _salaryCycle = prefs.getString('salaryCycle') ?? 'start_of_month';

    // MODIFICATION: Load seed colors instead of specific background colors
    _seedColorLight = await _loadColor('seed_color_light');
    _seedColorDark = await _loadColor('seed_color_dark');
    
    notifyListeners();
  }

  Future<void> loadUserNameAndProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? '';
    _profileImageBase64 = await _settingsRepo.getProfileImage();
    notifyListeners();
  }

  // Generic method to set and save a color
  Future<void> _setColor(
      String key, Color color, Function(Color) setter) async {
    setter(color);
    await _settingsRepo.saveSetting(key, color.value.toRadixString(16));
    notifyListeners();
  }

  // MODIFICATION: Renamed method to be more descriptive of its new function
  Future<void> setThemeSeedColor(Color color, bool isDarkMode) async {
    await _setColor(
        isDarkMode ? 'seed_color_dark' : 'seed_color_light',
        color,
        (c) => isDarkMode ? _seedColorDark = c : _seedColorLight = c);
  }

  Future<void> setSalaryCycle(String cycle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('salaryCycle', cycle);
    _salaryCycle = cycle;
    notifyListeners();
  }

  Future<void> setAutoBackupFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autoBackupFrequency', frequency);
    _autoBackupFrequency = frequency;
    notifyListeners();
  }

  Future<void> checkAndPerformAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final frequency = prefs.getString('autoBackupFrequency') ?? 'Off';
    final backupPath = prefs.getString('backup_location');

    if (frequency == 'Off' || backupPath == null) {
      return;
    }

    final lastBackupString = prefs.getString('lastAutoBackupDate');
    final now = DateTime.now();
    DateTime? lastBackupDate;
    if (lastBackupString != null) {
      lastBackupDate = DateTime.tryParse(lastBackupString);
    }

    bool shouldBackup = false;
    if (lastBackupDate == null) {
      shouldBackup = true;
    } else {
      final difference = now.difference(lastBackupDate);
      if (frequency == 'Daily' && difference.inDays >= 1) {
        shouldBackup = true;
      } else if (frequency == 'Weekly' && difference.inDays >= 7) {
        shouldBackup = true;
      } else if (frequency == 'Monthly' && now.month != lastBackupDate.month) {
        shouldBackup = true;
      }
    }

    if (shouldBackup) {
      log('Performing automatic backup...');
      final success = await BackupService.performBackup();
      if (success) {
        await prefs.setString('lastAutoBackupDate', now.toIso8601String());
        log('Automatic backup successful!');
      } else {
        log('Automatic backup failed.');
      }
    }
  }

  Future<void> deleteMonthlyData(int year, int month) async {
    await _transactionRepo.deleteTransactionsForMonth(year, month);
    notifyListeners();
  }

  Future<void> clearAllData(BuildContext context) async {
    await _transactionRepo.deleteAllData();
    // Clear shared preferences to ensure a full reset
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRouter.onboardingPage, (route) => false);
    }
  }
}
