import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/auth/account_scope.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/domain/repositories/auth_repository.dart';
import 'package:itun/features/profile/data/models/user_stats_model.dart';
import 'package:itun/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:itun/features/profile/domain/entities/user_stats_entity.dart';

class _Auth extends Mock implements AuthRepository {}

const _stats = UserStatsEntity(
  practicedLetters: {'a'},
  completedLessons: {'lesson-a'},
  quizHistory: {},
  categoryMastery: {},
  totalLearningMinutes: 5,
  lastActiveDate: '',
  currentStreak: 0,
  totalStars: 10,
);

String _encode(UserStatsEntity stats) =>
    jsonEncode(UserStatsModel.fromEntity(stats).toJson());

Future<void> _login(SharedPreferences prefs, String id) async {
  final pending = await AccountScope.beginSignIn(prefs);
  await pending.identify(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late _Auth auth;
  late ProfileRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = _Auth();
    when(
      auth.getCurrentUser,
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    when(auth.isLoggedIn).thenAnswer((_) async => const Left(NetworkFailure()));
    when(
      auth.getUserPrefs,
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    when(
      () => auth.updateUserPrefs(any()),
    ).thenAnswer((_) async => const Right(null));
    repo = ProfileRepositoryImpl(auth, prefs);
  });

  test(
    'authenticated offline writes survive repository and preference restart, then sync',
    () async {
      await _login(prefs, 'a');
      expect((await repo.updateUserStats(_stats)).isRight(), isTrue);
      expect(prefs.getString('user_stats_a'), contains('lesson-a'));
      expect(prefs.getString('user_stats_guest'), isNull);
      expect(prefs.getString('user_progress_data'), isNull);
      expect(prefs.getBool('is_stats_synced_a'), isFalse);

      final saved = {for (final key in prefs.getKeys()) key: prefs.get(key)!};
      SharedPreferences.setMockInitialValues(saved);
      prefs = await SharedPreferences.getInstance();
      repo = ProfileRepositoryImpl(auth, prefs);
      final offline = (await repo.getUserStats()).getRight().toNullable()!;
      expect(offline.completedLessons, {'lesson-a'});
      expect(prefs.getBool('is_stats_synced_a'), isFalse);
      expect((await repo.syncPendingStats()).isLeft(), isTrue);
      expect(prefs.getBool('is_stats_synced_a'), isFalse);

      when(
        auth.getUserPrefs,
      ).thenAnswer((_) async => const Right({'unrelated': 'keep'}));
      expect((await repo.syncPendingStats()).isRight(), isTrue);
      final uploaded =
          verify(() => auth.updateUserPrefs(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(uploaded['unrelated'], 'keep');
      expect(uploaded['user_progress_data'], contains('lesson-a'));
      expect(prefs.getBool('is_stats_synced_a'), isTrue);
      verifyNever(auth.getCurrentUser);
      verifyNever(auth.isLoggedIn);
    },
  );

  test('transient auth/server failure never redirects data to guest', () async {
    await _login(prefs, 'a');
    when(
      auth.getUserPrefs,
    ).thenAnswer((_) async => const Left(ServerFailure(message: '503')));
    await repo.updateUserStats(_stats);
    expect((await repo.getUserStats()).getRight().toNullable()!.totalStars, 10);
    expect(prefs.getString('user_stats_guest'), isNull);
    expect(prefs.getBool('is_stats_synced_a'), isFalse);
  });

  test('real guest retains legacy progress and never accesses cloud', () async {
    await prefs.setString('user_progress_data', _encode(_stats));
    expect((await repo.getUserStats()).getRight().toNullable()!.totalStars, 10);
    await repo.updateUserStats(_stats);
    expect(prefs.getString('user_stats_guest'), isNotNull);
    expect(prefs.getBool('is_stats_synced_guest'), isTrue);
    verifyNever(auth.getUserPrefs);
    verifyNever(() => auth.updateUserPrefs(any()));
  });

  test(
    'legacy active session with unknown owner fails closed, not guest',
    () async {
      await prefs.setBool('olitun_has_local_session', true);
      await prefs.setString('user_progress_data', _encode(_stats));
      final before = prefs.getString('user_progress_data');
      expect((await repo.getUserStats()).isLeft(), isTrue);
      expect((await repo.updateUserStats(_stats)).isLeft(), isTrue);
      expect((await repo.resetUserStats()).isLeft(), isTrue);
      expect(prefs.getString('user_progress_data'), before);
      expect(prefs.getString('user_stats_guest'), isNull);
    },
  );

  test(
    'login never imports guest/legacy data; switching preserves separate pending flags',
    () async {
      await repo.updateUserStats(_stats);
      await _login(prefs, 'a');
      expect(
        (await repo.getUserStats()).getRight().toNullable()!.totalStars,
        0,
      );
      await repo.updateUserStats(_stats.copyWith(totalStars: 20));
      await _login(prefs, 'b');
      expect(
        (await repo.getUserStats()).getRight().toNullable()!.totalStars,
        0,
      );
      await repo.updateUserStats(_stats.copyWith(totalStars: 30));
      await AccountScope.signOut(prefs);
      expect(
        (await repo.getUserStats()).getRight().toNullable()!.totalStars,
        10,
      );
      expect(prefs.getBool('is_stats_synced_a'), isFalse);
      expect(prefs.getBool('is_stats_synced_b'), isFalse);
      await _login(prefs, 'a');
      expect(
        (await repo.getUserStats()).getRight().toNullable()!.totalStars,
        20,
      );
    },
  );

  test(
    'global clean flag cannot suppress missing per-account pending flag',
    () async {
      await _login(prefs, 'a');
      await prefs.setString('user_stats_a', _encode(_stats));
      await prefs.setBool('is_stats_synced', true);
      when(auth.getUserPrefs).thenAnswer((_) async => const Right({}));
      expect((await repo.syncPendingStats()).isRight(), isTrue);
      verify(() => auth.updateUserPrefs(any())).called(1);
    },
  );

  test(
    'offline reset stays account-scoped and pending across reconnect',
    () async {
      await _login(prefs, 'a');
      await repo.updateUserStats(_stats);
      final reset = (await repo.resetUserStats()).getRight().toNullable()!;
      expect(reset.syncEpoch, 1);
      expect(reset.totalStars, 0);
      expect(prefs.getBool('is_stats_synced_a'), isFalse);
      when(
        auth.getUserPrefs,
      ).thenAnswer((_) async => Right({'user_progress_data': _encode(_stats)}));
      await repo.syncPendingStats();
      final stored = UserStatsModel.fromJson(
        jsonDecode(prefs.getString('user_stats_a')!),
      );
      expect(stored.syncEpoch, 1);
      expect(stored.completedLessons, isEmpty);
    },
  );

  for (final operation in ['get', 'update', 'reset', 'sync']) {
    for (final fails in [false, true]) {
      test(
        '$operation ignores late cloud ${fails ? 'exception' : 'response'} after account switch',
        () async {
          await _login(prefs, 'a');
          await prefs.setString('user_stats_a', _encode(_stats));
          await prefs.setBool('is_stats_synced_a', false);
          final started = Completer<void>();
          final cloud = Completer<Either<Failure, Map<String, dynamic>>>();
          when(auth.getUserPrefs).thenAnswer((_) {
            started.complete();
            return cloud.future;
          });
          final Future<dynamic> pending;
          switch (operation) {
            case 'get':
              pending = repo.getUserStats();
              break;
            case 'update':
              pending = repo.updateUserStats(_stats);
              break;
            case 'reset':
              pending = repo.resetUserStats();
              break;
            default:
              pending = repo.syncPendingStats();
          }
          await started.future;
          final aBefore = prefs.getString('user_stats_a');
          await _login(prefs, 'b');
          if (fails) {
            cloud.completeError(StateError('late transport failure'));
          } else {
            cloud.complete(
              Right({
                'user_progress_data': _encode(_stats.copyWith(totalStars: 99)),
              }),
            );
          }
          final dynamic result = await pending;
          expect(result.isLeft(), isTrue);
          expect(prefs.getString('user_stats_a'), aBefore);
          expect(prefs.getString('user_stats_b'), isNull);
          expect(prefs.getString('user_stats_guest'), isNull);
          expect(prefs.getBool('is_stats_synced_b'), isNull);
          verifyNever(() => auth.updateUserPrefs(any()));
        },
      );
    }
  }

  test('late upload success cannot mark new account clean', () async {
    await _login(prefs, 'a');
    when(auth.getUserPrefs).thenAnswer((_) async => const Right({}));
    final started = Completer<void>();
    final upload = Completer<Either<Failure, void>>();
    when(() => auth.updateUserPrefs(any())).thenAnswer((_) {
      started.complete();
      return upload.future;
    });
    final pending = repo.updateUserStats(_stats);
    await started.future;
    await _login(prefs, 'b');
    upload.complete(const Right(null));
    expect((await pending).isLeft(), isTrue);
    expect(prefs.getBool('is_stats_synced_a'), isFalse);
    expect(prefs.getBool('is_stats_synced_b'), isNull);
  });

  test(
    'A -> logout -> A invalidates in-flight and queued operations',
    () async {
      await _login(prefs, 'a');
      final started = Completer<void>();
      final cloud = Completer<Either<Failure, Map<String, dynamic>>>();
      when(auth.getUserPrefs).thenAnswer((_) {
        started.complete();
        return cloud.future;
      });
      final read = repo.getUserStats();
      await started.future;
      final queued = repo.updateUserStats(_stats);
      await AccountScope.signOut(prefs);
      await _login(prefs, 'a');
      cloud.complete(const Right({}));
      expect((await read).isLeft(), isTrue);
      expect((await queued).isLeft(), isTrue);
      expect(prefs.getString('user_stats_a'), isNull);
    },
  );
}
