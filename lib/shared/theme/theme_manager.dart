import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple class that notifies listeners when the theme changes.
class ThemeNotifier with ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  bool _darkTheme;

  // Getter to access the current theme mode
  bool get isDarkMode => _darkTheme;

  // Default to dark theme when the app starts
  ThemeNotifier() : _darkTheme = true {
    _loadFromPrefs();
  }

  // Toggles the theme and saves the preference
  void toggleTheme() {
    _darkTheme = !_darkTheme;
    _saveToPrefs();
    notifyListeners();
  }

  // Initializes the SharedPreferences instance
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Loads the saved theme preference from disk
  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    // Default to true (dark mode) if no preference is found
    _darkTheme = _prefs?.getBool(key) ?? true;
    notifyListeners();
  }

  // Saves the current theme preference to disk
  Future<void> _saveToPrefs() async {
    await _initPrefs();
    _prefs?.setBool(key, _darkTheme);
  }
}