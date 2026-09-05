import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/category_lessons_screen.dart';

class _Categories extends CategoryNotifier {
  final AsyncValue<List<CategoryEntity>> Function() load;

  _Categories(this.load);

  @override
  AsyncValue<List<CategoryEntity>> build() => load();
}

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<List<CategoryEntity>> Function() load, {
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/category/missing',
    routes: [
      GoRoute(
        path: '/lessons',
        builder: (_, _) => const Scaffold(body: Text('All learning paths')),
      ),
      GoRoute(
        path: '/category/:id',
        builder: (_, _) => const CategoryLessonsScreen(categoryId: 'missing'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoryNotifierProvider.overrideWith(() => _Categories(load)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('category loading has a working escape route', (tester) async {
    await _pump(tester, () => const AsyncValue.loading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('All learning paths'), findsOneWidget);
  });

  testWidgets('category errors display recovery and retry the provider', (
    tester,
  ) async {
    var attempts = 0;
    await _pump(tester, () {
      attempts++;
      return attempts == 1
          ? AsyncValue.error('private_backend_error', StackTrace.current)
          : const AsyncValue.data([]);
    });
    expect(find.text('Could not load lessons'), findsOneWidget);
    expect(find.text('private_backend_error'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Learning path not found'), findsOneWidget);
  });

  testWidgets('a missing category does not spin forever', (tester) async {
    await _pump(tester, () => const AsyncValue.data([]));
    expect(find.text('Learning path not found'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Back to learning paths'));
    await tester.pumpAndSettle();
    expect(find.text('All learning paths'), findsOneWidget);
  });

  testWidgets('recovery layout supports narrow screens and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      () => AsyncValue.error('offline', StackTrace.current),
      textScale: 2,
    );
    await tester.ensureVisible(find.text('Back to learning paths'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Back to learning paths'));
    await tester.pumpAndSettle();
    expect(find.text('All learning paths'), findsOneWidget);
  });
}
