import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/categories/data/datasources/category_local_datasource.dart';
import 'package:itun/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:itun/features/categories/data/models/category_model.dart';
import 'package:itun/features/categories/data/repositories/category_repository_impl.dart';

class _MockRemote extends Mock implements CategoryRemoteDataSource {}

class _MockLocal extends Mock implements CategoryLocalDataSource {}

class _MockNetwork extends Mock implements NetworkInfo {}

CategoryModel _cat(String id) =>
    CategoryModel(id: id, titleOlChiki: 'ᱚ', titleLatin: 'a');

void main() {
  late _MockRemote remote;
  late _MockLocal local;
  late _MockNetwork network;
  late CategoryRepositoryImpl repo;

  setUp(() {
    remote = _MockRemote();
    local = _MockLocal();
    network = _MockNetwork();
    repo = CategoryRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: network,
    );
    registerFallbackValue(<CategoryModel>[]);
  });

  test('returns remote categories and caches them when online', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(() => remote.getCategories()).thenAnswer((_) async => [_cat('1')]);
    when(() => local.cacheCategories(any())).thenAnswer((_) async {});

    final result = await repo.getCategories();

    result.match(
      (_) => fail('should be right'),
      (cats) => expect(cats.single.id, '1'),
    );
    verify(() => local.cacheCategories(any())).called(1);
  });

  test('falls back to cache when remote throws ServerException', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(
      () => remote.getCategories(),
    ).thenThrow(ServerException(message: 'boom', code: 500));
    when(() => local.getCategories()).thenAnswer((_) async => [_cat('c')]);

    final result = await repo.getCategories();

    result.match(
      (_) => fail('should be right'),
      (cats) => expect(cats.single.id, 'c'),
    );
  });

  test('returns ServerFailure when offline AND cache miss '
      '(propagates "No internet connection" message)', () async {
    when(() => network.isConnected).thenAnswer((_) async => false);
    when(
      () => local.getCategories(),
    ).thenThrow(CacheException(message: 'no cache'));

    final result = await repo.getCategories();

    result.match((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'No internet connection');
    }, (_) => fail('should be left'));
  });

  test('getCategoryById surfaces ServerFailure on remote error', () async {
    when(() => network.isConnected).thenAnswer((_) async => true);
    when(
      () => remote.getCategoryById(any()),
    ).thenThrow(ServerException(message: 'gone', code: 404));

    final result = await repo.getCategoryById('x');

    result.match((failure) {
      expect(failure, isA<ServerFailure>());
      expect(failure.code, 404);
    }, (_) => fail('should be left'));
  });
}
