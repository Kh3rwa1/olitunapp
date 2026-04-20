import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/appwrite_auth_service.dart';
import '../../features/auth/data/auth_repository.dart';
import 'progress_provider.dart';

final appwriteAuthServiceProvider = Provider<AppwriteAuthService>((ref) {
  return AppwriteAuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(appwriteAuthServiceProvider));
});

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  try {
    final authRepo = ref.read(authRepositoryProvider);
    return await authRepo.isLoggedIn();
  } catch (_) {
    return false;
  }
});

final progressProvider =
    StateNotifierProvider<ProgressNotifier, UserProgressData>((ref) {
      final authRepo = ref.watch(authRepositoryProvider);
      return ProgressNotifier(authRepository: authRepo);
    });
