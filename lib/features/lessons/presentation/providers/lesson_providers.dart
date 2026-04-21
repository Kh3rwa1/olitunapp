import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/lesson_repository.dart';
import '../../data/datasources/lesson_local_datasource.dart';
import '../../data/datasources/lesson_remote_datasource.dart';
import '../../data/repositories/lesson_repository_impl.dart';

final lessonRemoteDataSourceProvider = Provider<LessonRemoteDataSource>((ref) {
  final client = AppwriteAuthService().client;
  return LessonRemoteDataSourceImpl(Databases(client));
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
