import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/appwrite_functions_service.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/lesson_local_datasource.dart';
import '../datasources/lesson_remote_datasource.dart';
import '../repositories/lesson_repository_impl.dart';
import '../../domain/repositories/lesson_repository.dart';

// Data-layer DI wiring for the lessons feature. Lives beside the
// datasources/repositories it constructs so `package:appwrite` never
// leaks into presentation.

final lessonRemoteDataSourceProvider = Provider<LessonRemoteDataSource>((ref) {
  final client = ref.watch(appwriteAuthServiceProvider).client;
  final functions = ref.watch(appwriteFunctionsServiceProvider);
  return LessonRemoteDataSourceImpl(
    Databases(client),
    functionsService: functions,
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
  );
});
