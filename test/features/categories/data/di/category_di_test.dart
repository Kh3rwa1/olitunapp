import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/categories/data/datasources/category_local_datasource.dart';
import 'package:itun/features/categories/data/datasources/category_remote_datasource.dart';
import 'package:itun/features/categories/data/di/category_di.dart';
import 'package:itun/features/categories/data/repositories/category_repository_impl.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mocktail/mocktail.dart';

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
              Directory.systemTemp.createTempSync('appwrite_di').path,
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

  test('remote datasource is appwrite-backed from the auth service client', () {
    final datasource = container.read(categoryRemoteDataSourceProvider);
    expect(datasource, isA<CategoryRemoteDataSourceImpl>());
  });

  test('local datasource is the concrete offline store', () {
    final datasource = container.read(categoryLocalDataSourceProvider);
    expect(datasource, isA<CategoryLocalDataSourceImpl>());
  });

  test('repository provider wires remote + local + network info', () {
    final repository = container.read(categoryRepositoryProvider);
    expect(repository, isA<CategoryRepositoryImpl>());
    expect(repository, isA<CategoryRepository>());

    // Provider caching: the same instance is reused across reads.
    expect(
      identical(repository, container.read(categoryRepositoryProvider)),
      isTrue,
    );
  });
}
