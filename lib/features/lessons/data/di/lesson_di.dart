import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_functions_service.dart';
import '../../../../core/api/admin_content_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/auth/auth_providers.dart';
import '../datasources/lesson_local_datasource.dart';
import '../datasources/lesson_remote_datasource.dart';
import '../repositories/lesson_repository_impl.dart';
import '../../domain/repositories/lesson_repository.dart';

// Data-layer DI wiring for the lessons feature. Lives beside the
// datasources/repositories it constructs.

final lessonRemoteDataSourceProvider = Provider<LessonRemoteDataSource>((ref) {
  return LessonRemoteDataSourceImpl(
    functionsService: ref.watch(appwriteFunctionsServiceProvider),
    adminClient: ref.watch(adminContentClientProvider),
  );
});

final lessonLocalDataSourceProvider = Provider<LessonLocalDataSource>((ref) {
  return LessonLocalDataSourceImpl();
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final remote = ref.watch(lessonRemoteDataSourceProvider);
  final local = ref.watch(lessonLocalDataSourceProvider);
  final network = ref.watch(networkInfoProvider);
  return LessonRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    networkInfo: network,
    currentUserIdProvider: () async {
      try {
        final user = ref.read(currentUserProvider).value;
        if (user != null && user.id.isNotEmpty) return user.id;
        final authRepo = ref.read(authRepositoryProvider);
        final result = await authRepo.getCurrentUser();
        final String? userId = result.fold<String?>((_) => null, (u) => u?.id);
        return userId;
      } catch (_) {
        return null;
      }
    },
  );
});
