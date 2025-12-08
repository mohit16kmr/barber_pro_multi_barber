import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyDark = 'pref_dark_mode';
  static const String _keyLang = 'pref_language';

  final SharedPreferences _prefs;
  bool _isDark;
  String _language;

  ThemeProvider._(this._prefs)
    : _isDark = _prefs.getBool(_keyDark) ?? false,
      _language = _prefs.getString(_keyLang) ?? 'English';

  static Future<ThemeProvider> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ThemeProvider._(prefs);
  }

  bool get isDark => _isDark;
  String get language => _language;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> setDarkMode(bool value) async {
    _isDark = value;
    await _prefs.setBool(_keyDark, value);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    await _prefs.setString(_keyLang, lang);
    notifyListeners();
  }
}
