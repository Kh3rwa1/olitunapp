import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _authKey = 'is_admin_authenticated';
  // Default secret key - should be changed via environment variables in production
  static const String _secretKey = String.fromEnvironment(
    'ADMIN_SECRET_KEY',
    defaultValue: 'olitun2026',
  );

  AdminAuthNotifier(this._prefs) : super(_prefs.getBool(_authKey) ?? false);

  bool login(String key) {
    if (key == _secretKey) {
      state = true;
      _prefs.setBool(_authKey, true);
      return true;
    }
    return false;
  }

  void logout() {
    state = false;
    _prefs.setBool(_authKey, false);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This will be overridden in Main
  throw UnimplementedError();
});

final adminAuthProvider = StateNotifierProvider<AdminAuthNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AdminAuthNotifier(prefs);
});
