import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/category_repository.dart';
import '../../data/datasources/category_local_datasource.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((
  ref,
) {
  final client = AppwriteAuthService().client;
  return CategoryRemoteDataSourceImpl(Databases(client));
});

final categoryLocalDataSourceProvider = Provider<CategoryLocalDataSource>((
  ref,
) {
  return CategoryLocalDataSourceImpl();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final remote = ref.watch(categoryRemoteDataSourceProvider);
  final local = ref.watch(categoryLocalDataSourceProvider);
  final network = ref.watch(networkInfoProvider);
  return CategoryRepositoryImpl(
    remoteDataSource: remote,
    localDataSource: local,
    networkInfo: network,
  );
});
