import 'package:itun/core/error/exceptions.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/core/network/network_info.dart';
import 'package:itun/features/content/data/datasources/localized_content_remote_datasource.dart';
import 'package:itun/features/content/data/models/localized_content_model.dart';
import 'package:itun/features/content/data/repositories/localized_content_repository_impl.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalizedContentRemoteDataSource extends Mock
    implements LocalizedContentRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

LocalizedContentModel row(
  String id, {
  String contentKind = 'word',
  String contentId = 'w1',
  String languageCode = 'hi',
  String? meaning = 'water',
  String reviewStatus = 'approved',
}) {
  return LocalizedContentModel(
    id: id,
    contentKind: contentKind,
    contentId: contentId,
    languageCode: languageCode,
    meaning: meaning,
    reviewStatusName: reviewStatus,
  );
}

void main() {
  late MockLocalizedContentRemoteDataSource remote;
  late MockNetworkInfo networkInfo;
  late LocalizedContentRepositoryImpl repository;

  setUp(() {
    remote = MockLocalizedContentRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = LocalizedContentRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: networkInfo,
    );
  });

  group('getLocalizations', () {
    test('surfaces only approved, structurally valid rows', () async {
      when(
        () => remote.getLocalizations(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer(
        (_) async => [
          row('l1'),
          row('l2', reviewStatus: 'draft'),
          row('l3', reviewStatus: 'needsReview'),
          // Structurally invalid: empty contentId maps to null entity.
          row('l4', contentId: ''),
          // Whitespace id passes the mapper but is dropped by validation.
          row('l5', contentId: ' '),
        ],
      );

      final result = await repository.getLocalizations(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(result.getOrElse((f) => []).map((c) => c.id), equals(['l1']));
    });

    test('does not memoize — every call hits the datasource', () async {
      when(
        () => remote.getLocalizations(contentKind: 'word', contentId: 'w1'),
      ).thenAnswer((_) async => [row('l1')]);

      await repository.getLocalizations(contentKind: 'word', contentId: 'w1');
      await repository.getLocalizations(contentKind: 'word', contentId: 'w1');

      verify(
        () => remote.getLocalizations(contentKind: 'word', contentId: 'w1'),
      ).called(2);
    });

    test('returns ServerFailure when the datasource throws', () async {
      when(
        () => remote.getLocalizations(contentKind: 'word', contentId: 'w1'),
      ).thenThrow(ServerException(message: 'Appwrite down'));

      final result = await repository.getLocalizations(
        contentKind: 'word',
        contentId: 'w1',
      );

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        isA<ServerFailure>(),
      );
    });
  });

  group('getLocalization', () {
    test('returns the approved localization for the language', () async {
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenAnswer((_) async => [row('l1'), row('l2', reviewStatus: 'draft')]);

      final result = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      expect(result.getOrElse((f) => null)?.id, 'l1');
    });

    test('caches the result — the second call skips the datasource', () async {
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenAnswer((_) async => [row('l1')]);

      final first = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );
      final second = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      expect(first.getOrElse((f) => null)?.id, 'l1');
      expect(second.getOrElse((f) => null)?.id, 'l1');
      verify(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).called(1);
    });

    test('caches known-missing as null — no refetch, Right(null)', () async {
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenAnswer(
        (_) async => [
          // Only unapproved rows exist for this language.
          row('l1', reviewStatus: 'draft'),
        ],
      );

      final first = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );
      final second = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      expect(
        first.getOrElse((f) => throw StateError('expected Right')),
        isNull,
      );
      expect(
        second.getOrElse((f) => throw StateError('expected Right')),
        isNull,
      );
      verify(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).called(1);
    });

    test('fetches again for a different language of the same item', () async {
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenAnswer((_) async => [row('l1')]);
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'en',
        ),
      ).thenAnswer((_) async => [row('l2', languageCode: 'en')]);

      final hi = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );
      final en = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'en',
      );

      expect(hi.getOrElse((f) => null)?.id, 'l1');
      expect(en.getOrElse((f) => null)?.id, 'l2');
    });

    test('returns ServerFailure when the datasource throws', () async {
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenThrow(ServerException(message: 'offline'));

      final result = await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        isA<ServerFailure>(),
      );
    });
  });

  group('getLocalizationsForIds', () {
    test('empty ids return immediately without touching anything', () async {
      final result = await repository.getLocalizationsForIds(
        contentKind: 'word',
        contentIds: const [],
        languageCode: 'hi',
      );

      expect(result.getOrElse((f) => []), isEmpty);
      verifyZeroInteractions(remote);
      verifyZeroInteractions(networkInfo);
    });

    test(
      'serves cached items and fetches only the missing ones when online',
      () async {
        // Pre-cache w1 through the single-item read path.
        when(
          () => remote.getLocalizationsForLanguage(
            contentKind: 'word',
            contentId: 'w1',
            languageCode: 'hi',
          ),
        ).thenAnswer((_) async => [row('l1')]);
        await repository.getLocalization(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        );

        when(() => networkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getLocalizationsForIds(
            contentKind: 'word',
            contentIds: ['w2'],
            languageCode: 'hi',
          ),
        ).thenAnswer(
          (_) async => [
            row('l2', contentId: 'w2'),
            // Unapproved batch rows must never surface.
            row('l2draft', contentId: 'w2', reviewStatus: 'draft'),
          ],
        );

        final result = await repository.getLocalizationsForIds(
          contentKind: 'word',
          contentIds: const ['w1', 'w2'],
          languageCode: 'hi',
        );

        expect(
          result.getOrElse((f) => []).map((c) => c.contentId),
          equals(['w1', 'w2']),
        );
        // Only w2 was missing — the batch query must not include w1.
        verify(
          () => remote.getLocalizationsForIds(
            contentKind: 'word',
            contentIds: ['w2'],
            languageCode: 'hi',
          ),
        ).called(1);
        verifyNever(
          () => remote.getLocalizationsForIds(
            contentKind: 'word',
            contentIds: ['w1', 'w2'],
            languageCode: 'hi',
          ),
        );
      },
    );

    test(
      'batch results are cached — a repeat batch stays fully offline',
      () async {
        when(() => networkInfo.isConnected).thenAnswer((_) async => true);
        when(
          () => remote.getLocalizationsForIds(
            contentKind: 'word',
            contentIds: ['w1', 'w2'],
            languageCode: 'hi',
          ),
        ).thenAnswer((_) async => [row('l1'), row('l2', contentId: 'w2')]);

        final first = await repository.getLocalizationsForIds(
          contentKind: 'word',
          contentIds: const ['w1', 'w2'],
          languageCode: 'hi',
        );
        final second = await repository.getLocalizationsForIds(
          contentKind: 'word',
          contentIds: const ['w1', 'w2'],
          languageCode: 'hi',
        );

        expect(first.getOrElse((f) => []).length, 2);
        expect(second.getOrElse((f) => []).length, 2);
        verify(
          () => remote.getLocalizationsForIds(
            contentKind: 'word',
            contentIds: ['w1', 'w2'],
            languageCode: 'hi',
          ),
        ).called(1);
      },
    );

    test('server failure is swallowed — cached items still served', () async {
      // Pre-cache w1.
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenAnswer((_) async => [row('l1')]);
      await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(
        () => remote.getLocalizationsForIds(
          contentKind: 'word',
          contentIds: ['w2'],
          languageCode: 'hi',
        ),
      ).thenThrow(ServerException(message: 'flaky network'));

      final result = await repository.getLocalizationsForIds(
        contentKind: 'word',
        contentIds: const ['w1', 'w2'],
        languageCode: 'hi',
      );

      // Partial success: the screen still renders cached meanings.
      expect(
        result.getOrElse((f) => []).map((c) => c.contentId),
        equals(['w1']),
      );
      expect(result.isRight(), isTrue);
    });

    test('offline serves cached items and skips the datasource', () async {
      // Pre-cache w1.
      when(
        () => remote.getLocalizationsForLanguage(
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
        ),
      ).thenAnswer((_) async => [row('l1')]);
      await repository.getLocalization(
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
      );

      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.getLocalizationsForIds(
        contentKind: 'word',
        contentIds: const ['w1', 'w2'],
        languageCode: 'hi',
      );

      expect(
        result.getOrElse((f) => []).map((c) => c.contentId),
        equals(['w1']),
      );
      verifyNever(
        () => remote.getLocalizationsForIds(
          contentKind: 'word',
          contentIds: any(named: 'contentIds', that: anything),
          languageCode: 'hi',
        ),
      );
    });
  });

  group('write operations', () {
    test('saveLocalization is rejected with AuthFailure', () async {
      final result = await repository.saveLocalization(
        const LocalizedContent(
          id: 'l1',
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'hi',
          meaning: 'water',
        ),
      );

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(
          const AuthFailure(
            message: 'Localizations are managed via the admin CMS',
          ),
        ),
      );
      verifyZeroInteractions(remote);
    });

    test('deleteLocalization is rejected with AuthFailure', () async {
      final result = await repository.deleteLocalization('l1');

      expect(
        result.swap().getOrElse((f) => throw StateError('expected Left')),
        equals(
          const AuthFailure(
            message: 'Localizations are managed via the admin CMS',
          ),
        ),
      );
      verifyZeroInteractions(remote);
    });
  });
}
