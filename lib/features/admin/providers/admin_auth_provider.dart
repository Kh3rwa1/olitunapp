import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/appwrite_auth_service.dart';
import '../data/admin_auth_service.dart';

export '../data/admin_auth_service.dart';

final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService(ref.watch(appwriteAuthServiceProvider));
});

/// Async source of truth for whether the current user is an admin.
/// Watch this in router guards and admin screens.
final adminAuthProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(adminAuthServiceProvider);
  return svc.isCurrentUserAdmin();
});
