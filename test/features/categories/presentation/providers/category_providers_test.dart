import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/categories/data/datasources/category_local_datasource.dart';
import 'package:itun/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:itun/features/categories/data/repositories/category_repository_impl.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/features/categories/presentation/providers/category_providers.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';

/// The presentation-layer barrel `category_providers.dart` only re-exports the
/// data-layer DI wiring; these tests prove the re-export resolves to the very
/// same providers so app code can keep importing either path.
class _FakeAuthService implements AppwriteAuthService {
  @override
  Client get client => Client();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // appwrite's IO client resolves a documents directory on construction;
    // answer the platform channel with a throwaway temp dir so no plugin
    // is ever loaded.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async =>
              Directory.systemTemp.createTempSync('category_barrel').path,
        );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        appwriteAuthServiceProvider.overrideWithValue(_FakeAuthService()),
        networkInfoProvider.overrideWithValue(_MockNetworkInfo()),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('the barrel re-exports the appwrite-backed repository provider', () {
    final repository = container.read(categoryRepositoryProvider);
    expect(repository, isA<CategoryRepositoryImpl>());
    expect(repository, isA<CategoryRepository>());
  });

  test('re-exported datasource providers resolve through the barrel', () {
    expect(
      container.read(categoryRemoteDataSourceProvider),
      isA<CategoryRemoteDataSourceImpl>(),
    );
    expect(
      container.read(categoryLocalDataSourceProvider),
      isA<CategoryLocalDataSourceImpl>(),
    );
  });

  test('the repository provider caches its instance when read via barrel', () {
    final repository = container.read(categoryRepositoryProvider);
    expect(
      identical(repository, container.read(categoryRepositoryProvider)),
      isTrue,
    );
  });

  test('overriding the barrel provider changes what consumers read', () {
    final fakeRepository = _StubRepository();
    final overridden = ProviderContainer(
      overrides: [categoryRepositoryProvider.overrideWithValue(fakeRepository)],
    );
    addTearDown(overridden.dispose);

    expect(overridden.read(categoryRepositoryProvider), same(fakeRepository));
  });
}

class _StubRepository implements CategoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
