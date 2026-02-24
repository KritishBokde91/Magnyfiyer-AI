import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  late bool _isDark;

  ThemeProvider({required StorageService storage}) : _storage = storage {
    _isDark = storage.isDarkMode;
  }

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggle() async {
    _isDark = !_isDark;
    await _storage.setDarkMode(_isDark);
    notifyListeners();
  }

  Future<void> setDark(bool value) async {
    _isDark = value;
    await _storage.setDarkMode(_isDark);
    notifyListeners();
  }
}
