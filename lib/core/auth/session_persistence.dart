import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    bool? isWebOverride,
  }) async {
    if (secret.isEmpty) {
      await clearLocalSessionState(client: client, prefs: prefs);
      throw AppwriteException('Cannot persist empty session secret.');
    }
    client.setSession(secret);
    final isWeb = isWebOverride ?? kIsWeb;
    try {
      if (isWeb) {
        // On Web, NEVER store raw session secret in plain SharedPreferences (window.localStorage).
        // Appwrite handles HTTP cookies (a_session_*). Store only validity metadata.
        await prefs.remove(webSessionSecretKey);
        await prefs.setInt(
          webSessionTimestampKey,
          (nowProvider?.call() ?? DateTime.now()).millisecondsSinceEpoch,
        );
        await prefs.setBool(hasLocalSessionKey, true);
      } else {
        await prefs.setString(webSessionSecretKey, secret);
        await prefs.setInt(
          webSessionTimestampKey,
          (nowProvider?.call() ?? DateTime.now()).millisecondsSinceEpoch,
        );
        await prefs.setBool(hasLocalSessionKey, true);
      }
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
    final hasSession = prefs.getBool(hasLocalSessionKey) ?? false;

    // Purge legacy plain secret string if present on Web
    if (secret != null && secret.isNotEmpty) {
      await prefs.remove(webSessionSecretKey);
    }

    if (!hasSession ||
        ts == null ||
        !isWebSessionValidTimestamp(ts, nowOverride: nowProvider?.call())) {
      AppLogger.debug(
        'Appwrite: Web session timestamp invalid; failing closed and clearing',
      );
      await clearLocalSessionState(client: client, prefs: prefs);
      return;
    }
    // On Web, session validation delegates to Appwrite cookie authentication via account.get()
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
