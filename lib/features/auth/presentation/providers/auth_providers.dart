import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final authService = ref.watch(appwriteAuthServiceProvider);
  return AuthRemoteDataSourceImpl(authService);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remote = ref.watch(authRemoteDataSourceProvider);
  final network = ref.watch(networkInfoProvider);
  return AuthRepositoryImpl(remoteDataSource: remote, networkInfo: network);
});

final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.isLoggedIn();
  return result.getOrElse((_) => false);
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  final result = await repo.getCurrentUser();
  return result.getOrElse((_) => null);
});
