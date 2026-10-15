import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/edge_json_client.dart';
import '../../../../core/api/admin_content_client.dart';
import '../../../../core/network/network_info.dart';
import '../datasources/category_local_datasource.dart';
import '../datasources/category_remote_datasource.dart';
import '../repositories/category_repository_impl.dart';
import '../../domain/repositories/category_repository.dart';

// Data-layer DI wiring for the categories feature. Lives beside the
// datasources/repositories it constructs.

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>((
  ref,
) {
  return CategoryRemoteDataSourceImpl(
    httpClient: ref.watch(edgeHttpClientProvider),
    adminClient: ref.watch(adminContentClientProvider),
  );
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
