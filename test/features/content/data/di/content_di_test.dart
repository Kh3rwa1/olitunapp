import 'package:appwrite/appwrite.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/content/data/datasources/audio_track_remote_datasource.dart';
import 'package:itun/features/content/data/datasources/localized_content_remote_datasource.dart';
import 'package:itun/features/content/data/datasources/story_segment_remote_datasource.dart';
import 'package:itun/features/content/data/di/content_di.dart';
import 'package:itun/features/content/data/repositories/audio_track_repository_impl.dart';
import 'package:itun/features/content/data/repositories/localized_content_repository_impl.dart';
import 'package:itun/features/content/data/repositories/story_segment_repository_impl.dart';
import 'package:itun/features/content/domain/repositories/audio_track_repository.dart';
import 'package:itun/features/content/domain/repositories/localized_content_repository.dart';
import 'package:itun/features/content/domain/repositories/story_segment_repository.dart';
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

  test('audio track wiring builds impl-backed datasource and repository', () {
    final datasource = container.read(audioTrackRemoteDataSourceProvider);
    expect(datasource, isA<AudioTrackRemoteDataSourceImpl>());

    final repository = container.read(audioTrackRepositoryProvider);
    expect(repository, isA<AudioTrackRepositoryImpl>());
    expect(repository, isA<AudioTrackRepository>());
  });

  test(
    'localized content wiring builds impl-backed datasource and repository',
    () {
      final datasource = container.read(
        localizedContentRemoteDataSourceProvider,
      );
      expect(datasource, isA<LocalizedContentRemoteDataSourceImpl>());

      final repository = container.read(localizedContentRepositoryProvider);
      expect(repository, isA<LocalizedContentRepositoryImpl>());
      expect(repository, isA<LocalizedContentRepository>());
    },
  );

  test('story segment wiring builds impl-backed datasource and repository', () {
    final datasource = container.read(storySegmentRemoteDataSourceProvider);
    expect(datasource, isA<StorySegmentRemoteDataSourceImpl>());

    final repository = container.read(storySegmentRepositoryProvider);
    expect(repository, isA<StorySegmentRepositoryImpl>());
    expect(repository, isA<StorySegmentRepository>());
  });

  test('repository providers reuse the same underlying client', () {
    final service = container.read(appwriteAuthServiceProvider);
    final datasourceA = container.read(audioTrackRemoteDataSourceProvider);
    final datasourceB = container.read(audioTrackRemoteDataSourceProvider);

    expect(identical(datasourceA, datasourceB), isTrue);
    expect(service.client, isA<Client>());
  });
}
