import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/reviews/review_eligibility.dart';
import 'package:itun/core/storage/cache_service.dart';
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockDbService extends Mock implements AppwriteDbService {}

UserEntity _user() =>
    const UserEntity(id: 'learner_1', email: 'learner@example.com');

void main() {
  late Directory tempDir;
  late _MockDbService db;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test_hive_review');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    CacheService.resetForTesting();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    CacheService.resetForTesting();
    // The Hive box persists across tests in this suite (same temp dir);
    // wipe the eligibility key so each test starts cache-clean.
    final box = await Hive.openBox('content_cache');
    await box.delete('has_unlocked_via_review');
    db = _MockDbService();
  });

  /// riverpod 2.6.1 quirk: on a FutureProvider that watches another
  /// overridden async provider, awaiting `.future` as the first interaction
  /// can stall. Driving the provider through [listen] resolves reliably.
  Future<bool> readResult(ProviderContainer c) {
    final done = Completer<bool>();
    final sub = c.listen(
      hasUnlockedViaReviewProvider,
      (previous, next) {
        if (next.hasValue && !done.isCompleted) done.complete(next.value!);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!done.isCompleted) done.completeError(error, stackTrace);
      },
    );
    return done.future.whenComplete(sub.close);
  }

  ProviderContainer container({required bool signedIn}) {
    return ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (ref) async => signedIn ? _user() : null,
        ),
        appwriteDbServiceProvider.overrideWithValue(db),
      ],
    );
  }

  test('returns false without any network call for guests', () async {
    final c = container(signedIn: false);
    addTearDown(c.dispose);

    final result = await readResult(c);

    expect(result, isFalse);
    verifyNever(() => db.listDocuments(any(), queries: any(named: 'queries')));
  });

  test(
    'queries verified play_store_review unlocks and caches the answer',
    () async {
      when(
        () => db.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer(
        (_) async => [
          {'id': 'purchase_1', 'status': 'verified'},
        ],
      );

      final c = container(signedIn: true);
      addTearDown(c.dispose);

      final result = await readResult(c);
      expect(result, isTrue);

      // The answer is persisted in the cache for subsequent sessions.
      final cached = await CacheService.get(
        'has_unlocked_via_review',
        (json) => json['value'] as bool,
      );
      expect(cached, isTrue);

      // A fresh container now reads from cache: no additional remote query.
      final c2 = container(signedIn: true);
      addTearDown(c2.dispose);
      expect(await readResult(c2), isTrue);
      verify(
        () => db.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).called(1);
    },
  );

  test(
    'returns false (and caches it) when no verified review exists',
    () async {
      when(
        () => db.listDocuments(
          'course_purchases',
          queries: any(named: 'queries'),
        ),
      ).thenAnswer((_) async => const []);

      final c = container(signedIn: true);
      addTearDown(c.dispose);

      expect(await readResult(c), isFalse);

      final cached = await CacheService.get(
        'has_unlocked_via_review',
        (json) => json['value'] as bool,
      );
      expect(cached, isFalse);
    },
  );

  test('falls back to false when the remote query throws', () async {
    when(
      () =>
          db.listDocuments('course_purchases', queries: any(named: 'queries')),
    ).thenThrow(Exception('offline'));

    final c = container(signedIn: true);
    addTearDown(c.dispose);

    expect(await readResult(c), isFalse);
  });
}
