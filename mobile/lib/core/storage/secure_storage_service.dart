import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'user_data';
  static const String _keyCompany = 'company_data';
  static const String _keyOfflineQueue = 'offline_sync_queue';

  static String? _cachedToken;
  static Map<String, dynamic>? _cachedUser;
  static Map<String, dynamic>? _cachedCompany;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } catch (_) {}
    try {
      await _storage.write(key: _keyToken, value: token).timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;

    // Fast-path: read from SharedPreferences (0ms in-memory lookup in Flutter)
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getString(_keyToken);
      if (val != null && val.isNotEmpty) {
        _cachedToken = val;
        return val;
      }
    } catch (_) {}

    // Fallback: Keychain
    try {
      final val = await _storage.read(key: _keyToken).timeout(const Duration(milliseconds: 600));
      if (val != null && val.isNotEmpty) {
        _cachedToken = val;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyToken, val);
        } catch (_) {}
        return val;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    _cachedUser = user;
    final str = jsonEncode(user);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, str);
    } catch (_) {}
    try {
      await _storage.write(key: _keyUser, value: str).timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getUser() async {
    if (_cachedUser != null) return _cachedUser;

    // Fast-path: read from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyUser);
      if (str != null && str.isNotEmpty) {
        _cachedUser = jsonDecode(str) as Map<String, dynamic>;
        return _cachedUser;
      }
    } catch (_) {}

    // Fallback: Keychain
    try {
      final str = await _storage.read(key: _keyUser).timeout(const Duration(milliseconds: 600));
      if (str != null && str.isNotEmpty) {
        _cachedUser = jsonDecode(str) as Map<String, dynamic>;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUser, str);
        } catch (_) {}
        return _cachedUser;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> saveCompany(Map<String, dynamic> company) async {
    _cachedCompany = company;
    final str = jsonEncode(company);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCompany, str);
    } catch (_) {}
    try {
      await _storage.write(key: _keyCompany, value: str).timeout(const Duration(seconds: 1));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> getCompany() async {
    if (_cachedCompany != null) return _cachedCompany;

    // Fast-path: read from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyCompany);
      if (str != null && str.isNotEmpty) {
        _cachedCompany = jsonDecode(str) as Map<String, dynamic>;
        return _cachedCompany;
      }
    } catch (_) {}

    // Fallback: Keychain
    try {
      final str = await _storage.read(key: _keyCompany).timeout(const Duration(milliseconds: 600));
      if (str != null && str.isNotEmpty) {
        _cachedCompany = jsonDecode(str) as Map<String, dynamic>;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyCompany, str);
        } catch (_) {}
        return _cachedCompany;
      }
    } catch (_) {}

    return null;
  }

  static Future<void> clearSession() async {
    _cachedToken = null;
    _cachedUser = null;
    _cachedCompany = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
      await prefs.remove(_keyCompany);
    } catch (_) {}
    try {
      await _storage.delete(key: _keyToken).timeout(const Duration(milliseconds: 800));
      await _storage.delete(key: _keyUser).timeout(const Duration(milliseconds: 800));
      await _storage.delete(key: _keyCompany).timeout(const Duration(milliseconds: 800));
    } catch (_) {}
  }

  // Offline queue methods via SharedPreferences
  static Future<List<Map<String, dynamic>>> getOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_keyOfflineQueue);
    if (queueJson != null) {
      try {
        final list = jsonDecode(queueJson) as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> enqueueOfflineOperation(Map<String, dynamic> operation) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getOfflineQueue();
    queue.add(operation);
    await prefs.setString(_keyOfflineQueue, jsonEncode(queue));
  }

  static Future<void> removeOfflineOperation(String localOperationId) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = await getOfflineQueue();
    queue.removeWhere((item) => item['local_operation_id'] == localOperationId);
    await prefs.setString(_keyOfflineQueue, jsonEncode(queue));
  }

  static Future<void> clearOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOfflineQueue);
  }
}
