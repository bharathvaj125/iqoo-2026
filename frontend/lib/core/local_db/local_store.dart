import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real on-device SQLite store (`sqflite`, already a
/// dependency) described in the tech-stack doc. shared_preferences' JSON
/// storage persists identically on the web preview and on a real device, so
/// this is genuine cross-restart persistence today; swap the body of this
/// class for a sqflite-backed one once building specifically against
/// Android/iOS, without touching the repositories that call it.
class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _prefsInstance async => _prefs ??= await SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await _prefsInstance;
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await _prefsInstance;
    await prefs.setString(key, jsonEncode(items));
  }

  Future<bool> hasKey(String key) async {
    final prefs = await _prefsInstance;
    return prefs.containsKey(key);
  }

  /// Drops the cached SharedPreferences handle so a test can swap in fresh mock values.
  @visibleForTesting
  void resetForTest() => _prefs = null;
}
