import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:itun/features/lessons/data/di/lesson_di.dart';
import 'package:itun/features/lessons/data/repositories/lesson_repository_impl.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeClient extends Fake implements Client {}

class _FakeAuthService extends Fake implements AppwriteAuthService {
  @override
  final Client client;
  _FakeAuthService(this.client);
}

class _FakeNetworkInfo extends Fake implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'lessonRemoteDataSourceProvider builds the Appwrite-backed datasource',
    () {
      final container = ProviderContainer(
        overrides: [
          appwriteAuthServiceProvider.overrideWithValue(
            _FakeAuthService(_FakeClient()),
          ),
        ],
      );
      addTearDown(container.dispose);

      final dataSource = container.read(lessonRemoteDataSourceProvider);

      expect(dataSource, isA<LessonRemoteDataSourceImpl>());
    },
  );

  test('lessonLocalDataSourceProvider builds the local datasource', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dataSource = container.read(lessonLocalDataSourceProvider);

    expect(dataSource, isA<LessonLocalDataSourceImpl>());
  });

  test('lessonRepositoryProvider wires remote, local and network together', () {
    final container = ProviderContainer(
      overrides: [
        appwriteAuthServiceProvider.overrideWithValue(
          _FakeAuthService(_FakeClient()),
        ),
        networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(lessonRepositoryProvider);

    expect(repo, isA<LessonRepositoryImpl>());
    expect(repo, isA<LessonRepository>());
  });

  test('lesson repository provider reuses the same datasources per read', () {
    final container = ProviderContainer(
      overrides: [
        appwriteAuthServiceProvider.overrideWithValue(
          _FakeAuthService(_FakeClient()),
        ),
        networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
      ],
    );
    addTearDown(container.dispose);

    final remoteFirst = container.read(lessonRemoteDataSourceProvider);
    final remoteSecond = container.read(lessonRemoteDataSourceProvider);
    final repoFirst = container.read(lessonRepositoryProvider);
    final repoSecond = container.read(lessonRepositoryProvider);

    expect(identical(remoteFirst, remoteSecond), isTrue);
    expect(identical(repoFirst, repoSecond), isTrue);
  });
}
