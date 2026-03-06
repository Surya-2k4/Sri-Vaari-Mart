import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, bool>((ref) {
  return AdminAuthNotifier();
});

class AdminAuthNotifier extends StateNotifier<bool> {
  AdminAuthNotifier() : super(false) {
    _checkAdminStatus();
  }

  static const String _adminKey = 'is_admin_authenticated';
  static const String _adminPassword = 'vaari@admin2026'; // Secret password

  Future<void> _checkAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_adminKey) ?? false;
  }

  Future<bool> authenticate(String password) async {
    if (password == _adminPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminKey, true);
      state = true;
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminKey, false);
    state = false;
  }
}
