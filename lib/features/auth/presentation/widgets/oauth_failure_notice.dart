import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/oauth_sanitizer.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/auth/auth_providers.dart';
import '../../../../core/storage/hive_service.dart';
import 'package:itun/core/logging/app_logger.dart';

/// Displays a one-time SnackBar notice when an OAuth error query parameter
/// is present in the current URI on web (e.g. `?error=...`).
class OAuthFailureNotice extends ConsumerStatefulWidget {
  const OAuthFailureNotice({super.key});

  @override
  ConsumerState<OAuthFailureNotice> createState() => _OAuthFailureNoticeState();
}

class _OAuthFailureNoticeState extends ConsumerState<OAuthFailureNotice> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  void _maybeShow() {
    if (_shown || !mounted) return;
    _shown = true;
    String raw = '';
    try {
      raw = GoRouterState.of(context).uri.queryParameters['error'] ?? '';
    } catch (_) {
      return;
    }
    if (raw.isEmpty) return;

    var message = 'Google sign-in failed. Please try again.';
    var isConflict = false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final type = '${decoded['type'] ?? ''}';
        final detail = '${decoded['message'] ?? ''}';
        if (type == 'user_already_exists' ||
            detail.contains('already exists')) {
          isConflict = true;
          message =
              'An account with this email already exists. '
              'Please sign in with Email instead.';
        } else if (detail.isNotEmpty) {
          message = 'Google sign-in failed: $detail';
        }
      }
    } catch (_) {
      // Keep the default message when the payload is not JSON.
    }

    OAuthSanitizer.clearOAuthError();
    if (isConflict) {
      // A leftover session (usually a guest) made Appwrite try to attach
      // Google to the wrong user. Clear it and retry Google once before
      // asking the user to switch to email.
      unawaited(_recoverFromConflict(message));
      return;
    }
    _showError(message, isConflict: false);
  }

  static const _retryKey = 'oauth_conflict_retry_at';
  static const _retryWindow = Duration(minutes: 2);

  Future<void> _recoverFromConflict(String message) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final lastRetry = prefs.getInt(_retryKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final alreadyRetried = now - lastRetry < _retryWindow.inMilliseconds;

    var signedOut = false;
    try {
      signedOut = await ref
          .read(appwriteAuthServiceProvider)
          .clearSessionsForOAuth();
    } catch (e) {
      AppLogger.debug(
        'Clearing sessions after an OAuth conflict failed: $e',
        name: 'OAuthFailureNotice',
      );
    }
    if (!mounted) return;

    if (signedOut && !alreadyRetried) {
      await prefs.setInt(_retryKey, now);
      await ref.read(authRepositoryProvider).signInWithGoogle();
      return;
    }
    await prefs.remove(_retryKey);
    if (mounted) _showError(message, isConflict: true);
  }

  void _showError(String message, {required bool isConflict}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: isConflict
            ? SnackBarAction(
                label: 'Use Email',
                textColor: Colors.white,
                onPressed: () => context.go('/login'),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
