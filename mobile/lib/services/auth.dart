// v0 auth: a locally-generated UUID stored in shared_preferences. No real
// account system yet — see ARCHITECTURE.md §4.
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class Auth {
  static const _userIdKey = 'user_id';
  static const _onboardedKey = 'onboarded';

  static Future<String> ensureUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_userIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = _uuid4();
    await prefs.setString(_userIdKey, id);
    return id;
  }

  static Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  static Future<void> markOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardedKey, true);
  }

  static String _uuid4() {
    // Cheap RFC4122-ish v4 — enough for a local dev identifier.
    final r = Random.secure();
    String h(int n) =>
        List<int>.generate(n, (_) => r.nextInt(256)).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h(4)}-${h(2)}-4${h(2).substring(1)}-${(8 + r.nextInt(4)).toRadixString(16)}${h(2).substring(1)}-${h(6)}';
  }
}
