import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/oauth_sanitizer.dart';
import '../providers/auth_providers.dart';

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

    if (isConflict) {
      try {
        ref.read(authRepositoryProvider).signOut();
      } catch (_) {}
    }

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
    OAuthSanitizer.clearOAuthError();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
