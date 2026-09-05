import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/motion/pressable_scale.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/home/presentation/widgets/home_content_grid.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

Future<void> _pump(WidgetTester tester, String categoryId) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, state) => Scaffold(
          body: SingleChildScrollView(
            child: HomeContentGrid(
              isDark: false,
              cols: 2,
              categories: [
                CategoryEntity(
                  id: categoryId,
                  titleLatin: 'Words',
                  titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/lessons/:id',
        builder: (_, state) => Text('opened:${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/letter/standalone/all',
        builder: (_, state) => const Text('opened:alphabet'),
      ),
      GoRoute(
        path: '/translate',
        builder: (_, state) => const Text('opened:translate'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reduceVisualEffectsProvider.overrideWithValue(true),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _card(String id) => find.byKey(ValueKey('home_category_$id'));

void main() {
  testWidgets('category semantics is actionable', (tester) async {
    final handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    await _pump(tester, 'words');

    final data = tester.getSemantics(_card('words')).getSemanticsData();
    expect(data.hasFlag(SemanticsFlag.isButton), isTrue);
    expect(data.hasAction(SemanticsAction.tap), isTrue);
    expect(data.label, isNotEmpty);
    expect(data.label, isNot(contains('Double tap')));
    final action = tester.widget<PressableScale>(_card('words'));
    expect(data.label, action.semanticLabel);
    final semanticWidgets = find.descendant(
      of: _card('words'),
      matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.onTap != null,
      ),
    );
    expect(semanticWidgets, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final id in ['words', 'cat_alphabets', 'cat_letters', 'letters']) {
    testWidgets('semantic tap routes $id', (tester) async {
      final handle = tester.ensureSemantics();
      addTearDown(handle.dispose);
      await _pump(tester, id);
      final data = tester.getSemantics(_card(id)).getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      final semantics = tester.widget<Semantics>(
        find.descendant(
          of: _card(id),
          matching: find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.onTap != null,
          ),
        ),
      );
      semantics.properties.onTap!();
      await tester.pumpAndSettle();
      expect(
        find.text(id == 'words' ? 'opened:words' : 'opened:alphabet'),
        findsOneWidget,
      );
    });
  }

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('keyboard ${key.keyLabel}', (tester) async {
      await _pump(tester, 'words');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      expect(find.text('opened:words'), findsOneWidget);
    });
  }
}
