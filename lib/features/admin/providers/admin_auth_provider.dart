import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _authKey = 'is_admin_authenticated';

  /// Admin secret — must be injected at build time:
  /// --dart-define=ADMIN_SECRET_KEY=<your-secure-key>
  /// If empty, admin login is disabled (production fail-safe).
  static const String _secretKey = String.fromEnvironment('ADMIN_SECRET_KEY');

  AdminAuthNotifier(this._prefs) : super(_prefs.getBool(_authKey) ?? false);

  bool login(String key) {
    // Reject login entirely if no secret key was injected at build time
    if (_secretKey.isEmpty) return false;
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
