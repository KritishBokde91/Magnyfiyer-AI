import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _conversationsKey = 'conversations';
  static const _settingsKey = 'app_settings';
  static const _themeModeKey = 'theme_mode';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Theme ──────────────────────────────────────────────────────────────────
  bool get isDarkMode => _prefs.getBool(_themeModeKey) ?? true;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_themeModeKey, value);

  // ── Settings ───────────────────────────────────────────────────────────────
  AppSettings loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw));
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  // ── Conversations ──────────────────────────────────────────────────────────
  List<Conversation> loadConversations() {
    final raw = _prefs.getString(_conversationsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((j) => Conversation.fromJson(j)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final raw = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await _prefs.setString(_conversationsKey, raw);
  }

  Future<void> deleteConversation(String id, List<Conversation> current) async {
    final updated = current.where((c) => c.id != id).toList();
    await saveConversations(updated);
  }
}
