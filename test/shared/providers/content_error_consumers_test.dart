import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/core/error/failures.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/home/presentation/providers/home_prefetch_provider.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/shared/widgets/content_load_guard.dart';
import 'package:itun/shared/widgets/state_widgets.dart';

class _ContentRepository extends Mock implements ContentRepository {}

class _FreshPrefetch extends HomePrefetchNotifier {
  @override
  HomePrefetchState build() {
    super.build();
    return HomePrefetchState(
      isPrefetching: false,
      lastCategoryRefresh: DateTime.now(),
    );
  }
}

void main() {
  const kinds = [
    ContentKind.word,
    ContentKind.number,
    ContentKind.sentence,
    ContentKind.letter,
  ];

  for (final disposeEarly in [false, true]) {
    test(
      'delayed prefetch failures are observed; disposed=$disposeEarly',
      () async {
        final repository = _ContentRepository();
        final pending =
            <ContentKind, Completer<Either<Failure, List<ContentItem>>>>{};
        for (final kind in kinds) {
          pending[kind] = Completer<Either<Failure, List<ContentItem>>>();
          when(
            () => repository.list(kind),
          ).thenAnswer((_) => pending[kind]!.future);
        }
        final container = ProviderContainer(
          overrides: [
            contentRepositoryProvider.overrideWithValue(repository),
            isAuthenticatedProvider.overrideWith((ref) async => false),
            homePrefetchProvider.overrideWith(_FreshPrefetch.new),
          ],
        );
        var disposed = false;
        addTearDown(() {
          if (!disposed) container.dispose();
        });
        await container.read(isAuthenticatedProvider.future);
        final work = container.read(homePrefetchProvider.notifier).prefetch();
        final completed = expectLater(
          work.timeout(const Duration(seconds: 5)),
          completes,
        );
        if (disposeEarly) {
          container.dispose();
          disposed = true;
        }
        for (final completer in pending.values) {
          completer.complete(const Left(CacheFailure(message: 'Unavailable')));
        }
        await completed;
        if (!disposeEarly) {
          for (final kind in kinds) {
            expect(
              container.read(contentListProvider((kind, null))).hasError,
              isTrue,
            );
          }
        }
      },
    );
  }

  testWidgets('content guard exposes error and retry, not empty success', (
    tester,
  ) async {
    var retried = false;
    final guard = buildContentLoadGuard([
      AsyncValue<Object?>.error(const NetworkFailure(), StackTrace.current),
    ], onRetry: () => retried = true);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: guard)));
    expect(find.byType(AppErrorState), findsOneWidget);
    final state = tester.widget<AppErrorState>(find.byType(AppErrorState));
    state.onRetry!();
    expect(retried, isTrue);
  });

  test('empty successful dependencies do not become errors', () {
    expect(
      buildContentLoadGuard([
        const AsyncValue<List<ContentItem>>.data([]),
      ], onRetry: () {}),
      isNull,
    );
  });

  testWidgets('loading dependencies show progress', (tester) async {
    final guard = buildContentLoadGuard([
      const AsyncValue<Object?>.loading(),
    ], onRetry: () {});
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: guard)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AppErrorState), findsNothing);
  });
}
