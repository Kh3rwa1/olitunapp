import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../logging/app_logger.dart';
import '../logging/redaction_helper.dart';
import 'session_validator.dart';

class SessionPersistence {
  static const String webSessionSecretKey = 'olitun_appwrite_session_secret';
  static const String webSessionTimestampKey = 'olitun_web_session_ts';
  static const String hasLocalSessionKey = 'olitun_has_local_session';

  static Future<void> persistWebSession({
    required Client client,
    required SharedPreferences prefs,
    required String secret,
    DateTime Function()? nowProvider,
  }) async {
    if (secret.isEmpty) {
      await clearLocalSessionState(client: client, prefs: prefs);
      throw AppwriteException('Cannot persist empty session secret.');
    }
    client.setSession(secret);
    try {
      await prefs.setString(webSessionSecretKey, secret);
      await prefs.setInt(
        webSessionTimestampKey,
        (nowProvider?.call() ?? DateTime.now()).millisecondsSinceEpoch,
      );
      await prefs.setBool(hasLocalSessionKey, true);
    } catch (e) {
      await clearLocalSessionState(client: client, prefs: prefs);
      throw AppwriteException(
        'Failed to persist web session: ${RedactionHelper.sanitize(e.toString())}',
      );
    }
  }

  static Future<void> restoreWebSession({
    required Client client,
    required SharedPreferences prefs,
    required bool isWeb,
    DateTime Function()? nowProvider,
  }) async {
    if (!isWeb) return;
    final secret = prefs.getString(webSessionSecretKey);
    final ts = prefs.getInt(webSessionTimestampKey);

    if (secret == null ||
        secret.isEmpty ||
        ts == null ||
        !isWebSessionValidTimestamp(ts, nowOverride: nowProvider?.call())) {
      AppLogger.debug(
        'Appwrite: Web session secret or timestamp invalid; failing closed and clearing',
      );
      await clearLocalSessionState(client: client, prefs: prefs);
      return;
    }
    client.setSession(secret);
  }

  static Future<void> clearLocalSessionState({
    required Client client,
    required SharedPreferences prefs,
  }) async {
    client.setSession('');
    try {
      try {
        await prefs.setBool(hasLocalSessionKey, false);
      } catch (e) {
        AppLogger.debug(
          'Appwrite: Failed to clear local session flag: ${RedactionHelper.sanitize(e.toString())}',
        );
      }
      try {
        await prefs.remove(webSessionSecretKey);
      } catch (e) {
        AppLogger.debug(
          'Appwrite: Failed to remove session secret: ${RedactionHelper.sanitize(e.toString())}',
        );
      }
      try {
        await prefs.remove(webSessionTimestampKey);
      } catch (e) {
        AppLogger.debug(
          'Appwrite: Failed to remove session timestamp: ${RedactionHelper.sanitize(e.toString())}',
        );
      }
    } catch (e) {
      AppLogger.debug(
        'Appwrite: Preference storage clear error: ${RedactionHelper.sanitize(e.toString())}',
      );
    } finally {
      client.setSession('');
    }
  }
}
