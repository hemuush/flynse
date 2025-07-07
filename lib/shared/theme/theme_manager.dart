import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple class that notifies listeners when the theme changes.
class ThemeNotifier with ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  bool _darkTheme;

  // Getter to access the current theme mode
  bool get isDarkMode => _darkTheme;

  // FIX: Constructor is now synchronous. Default theme is set here.
  ThemeNotifier() : _darkTheme = true;

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

  // FIX: Renamed from _loadFromPrefs to a public method for explicit initialization.
  // Loads the saved theme preference from disk.
  Future<void> loadTheme() async {
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
