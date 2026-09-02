import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/lessons/data/datasources/lesson_local_datasource.dart';
import 'package:itun/features/lessons/data/datasources/lesson_remote_datasource.dart';
import 'package:itun/features/lessons/data/repositories/lesson_repository_impl.dart';
import 'package:itun/features/lessons/domain/repositories/lesson_repository.dart';
// Exercised through the presentation compatibility barrel on purpose: the
// barrel must keep re-exporting the data-layer DI wiring.
import 'package:itun/features/lessons/presentation/providers/lesson_providers.dart';
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

ProviderContainer containerFor() {
  final container = ProviderContainer(
    overrides: [
      appwriteAuthServiceProvider.overrideWithValue(
        _FakeAuthService(_FakeClient()),
      ),
      networkInfoProvider.overrideWithValue(_FakeNetworkInfo()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('lesson_providers compatibility barrel', () {
    test('re-exports the Appwrite-backed remote datasource provider', () {
      final container = containerFor();

      final dataSource = container.read(lessonRemoteDataSourceProvider);

      expect(dataSource, isA<LessonRemoteDataSourceImpl>());
    });

    test('re-exports the local datasource provider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dataSource = container.read(lessonLocalDataSourceProvider);

      expect(dataSource, isA<LessonLocalDataSourceImpl>());
    });

    test('re-exported repository provider builds a LessonRepository', () {
      final container = containerFor();

      final repo = container.read(lessonRepositoryProvider);

      expect(repo, isA<LessonRepositoryImpl>());
      expect(repo, isA<LessonRepository>());
    });

    test('re-exported providers are stable across reads', () {
      final container = containerFor();

      final first = container.read(lessonRepositoryProvider);
      final second = container.read(lessonRepositoryProvider);

      expect(identical(first, second), isTrue);
    });
  });
}
