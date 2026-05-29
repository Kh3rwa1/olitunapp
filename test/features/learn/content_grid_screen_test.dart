import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/learn/presentation/screens/content_grid_screen.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';

class MockAudioService extends AudioService {
  String? lastPlayedUrl;
  bool didStopAudio = false;

  @override
  Future<void> playUrl(String url) async {
    lastPlayedUrl = url;
  }

  @override
  Future<void> stop() async {
    didStopAudio = true;
  }
}

void main() {
  final mockLetterItemWithAudioAndTracing = ContentItem(
    id: 'letter_1',
    kind: ContentKind.letter,
    categoryId: 'alphabets',
    title: 'A',
    olChiki: 'ᱚ',
    audioUrl: 'https://example.com/audio/a.mp3',
    tracing: const TracingConfig(glyph: 'ᱚ', strokes: []),
    blocks: const [],
    updatedAt: DateTime(2026, 5, 25),
  );

  final mockLetterItemSilentNoTracing = ContentItem(
    id: 'letter_2',
    kind: ContentKind.letter,
    categoryId: 'alphabets',
    title: 'B',
    olChiki: 'ᱛ',
    blocks: const [],
    updatedAt: DateTime(2026, 5, 25),
  );

  testWidgets('ContentGridScreen shows loading state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          contentListProvider((
            ContentKind.letter,
            null,
          )).overrideWith((ref) => Completer<List<ContentItem>>().future),
        ],
        child: const MaterialApp(
          home: ContentGridScreen(kind: ContentKind.letter),
        ),
      ),
    );

    expect(find.text('Johar... Loading'), findsOneWidget);
  });

  testWidgets('ContentGridScreen shows empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          contentListProvider((
            ContentKind.letter,
            null,
          )).overrideWith((ref) => []),
        ],
        child: const MaterialApp(
          home: ContentGridScreen(kind: ContentKind.letter),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No items found'), findsOneWidget);
  });

  testWidgets('ContentGridScreen shows error state and supports retry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    int callCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          contentListProvider((ContentKind.letter, null)).overrideWith((ref) {
            callCount++;
            if (callCount == 1) {
              throw Exception('Database connection error');
            }
            return [mockLetterItemSilentNoTracing];
          }),
        ],
        child: const MaterialApp(
          home: ContentGridScreen(kind: ContentKind.letter),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Database connection error'), findsOneWidget);

    // Tap retry
    await tester.tap(find.text('RETRY'));
    await tester.pumpAndSettle();

    expect(find.text('B'), findsOneWidget);
    expect(callCount, equals(2));
  });

  testWidgets('ContentGridScreen renders responsive grid columns', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Set screen width to mobile (e.g. 400 width)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          contentListProvider((
            ContentKind.letter,
            null,
          )).overrideWith((ref) => [mockLetterItemSilentNoTracing]),
        ],
        child: const MaterialApp(
          home: ContentGridScreen(kind: ContentKind.letter),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final gridView = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, equals(4));

    // Now set screen width to tablet (e.g. 800 width)
    tester.view.physicalSize = const Size(800, 800);
    await tester.pump();
    await tester.pumpAndSettle();

    final gridViewTablet = tester.widget<GridView>(find.byType(GridView));
    final delegateTablet =
        gridViewTablet.gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegateTablet.crossAxisCount, equals(6));
  });

  testWidgets(
    'ContentGridScreen triggers audio playback and conditional trace icon',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final mockAudio = MockAudioService();

      final router = GoRouter(
        initialLocation: '/grid',
        routes: [
          GoRoute(
            path: '/grid',
            builder: (context, state) =>
                const ContentGridScreen(kind: ContentKind.letter),
          ),
          GoRoute(
            path: '/practice/:char/:name',
            builder: (context, state) {
              return Scaffold(
                body: Text(
                  'Practice char: ${state.pathParameters['char']}, name: ${state.pathParameters['name']}, mode: ${state.uri.queryParameters['mode']}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            audioServiceProvider.overrideWithValue(mockAudio),
            contentListProvider((ContentKind.letter, null)).overrideWith(
              (ref) => [
                mockLetterItemWithAudioAndTracing,
                mockLetterItemSilentNoTracing,
              ],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both items render
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      // Verify trace icon is present only for item 1
      // The trace icon uses Icons.gesture_rounded
      expect(find.byIcon(Icons.gesture_rounded), findsOneWidget);

      // Tap tile 2 (silent, no tracing)
      await tester.tap(find.text('B'));
      await tester.pump();

      // Verify no audio played for item 2
      expect(mockAudio.lastPlayedUrl, isNull);

      // Tap tile 1 body (not the trace icon)
      await tester.tap(find.text('A'));
      await tester.pump();

      // Verify audio played
      expect(
        mockAudio.lastPlayedUrl,
        equals('https://example.com/audio/a.mp3'),
      );

      // Reset last played URL
      mockAudio.lastPlayedUrl = null;

      // Tap the trace icon of tile 1
      await tester.tap(find.byIcon(Icons.gesture_rounded));
      await tester.pumpAndSettle();

      // Verify navigated to practice screen with correct params
      expect(
        find.textContaining('Practice char: ᱚ, name: A, mode: trace'),
        findsOneWidget,
      );

      // Verify audio did NOT play when tapping the trace icon (HitTestBehavior.opaque nested consumption)
      expect(mockAudio.lastPlayedUrl, isNull);
    },
  );

  testWidgets('ContentGridScreen stops audio when app goes to background', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockAudio = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(mockAudio),
          contentListProvider((
            ContentKind.letter,
            null,
          )).overrideWith((ref) => [mockLetterItemWithAudioAndTracing]),
        ],
        child: const MaterialApp(
          home: ContentGridScreen(kind: ContentKind.letter),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap tile 1 to trigger audio
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(mockAudio.lastPlayedUrl, equals('https://example.com/audio/a.mp3'));

    // Trigger app backgrounding
    expect(mockAudio.didStopAudio, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // Verify audio stopped
    expect(mockAudio.didStopAudio, isTrue);
  });

  testWidgets('ContentGridScreen stops audio when screen is popped', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final mockAudio = MockAudioService();

    final router = GoRouter(
      initialLocation: '/other',
      routes: [
        GoRoute(
          path: '/grid',
          builder: (context, state) =>
              const ContentGridScreen(kind: ContentKind.letter),
        ),
        GoRoute(
          path: '/other',
          builder: (context, state) =>
              const Scaffold(body: Text('Other Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(mockAudio),
          contentListProvider((
            ContentKind.letter,
            null,
          )).overrideWith((ref) => [mockLetterItemWithAudioAndTracing]),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Other Screen'), findsOneWidget);

    // Navigate to grid screen
    router.push('/grid');
    await tester.pumpAndSettle();

    // Tap tile 1 to trigger audio
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(mockAudio.lastPlayedUrl, equals('https://example.com/audio/a.mp3'));

    // Verify didStopAudio is false initially
    expect(mockAudio.didStopAudio, isFalse);

    // Pop the screen
    final context = tester.element(find.byType(ContentGridScreen));
    context.pop();
    await tester.pumpAndSettle();

    // Verify screen popped and didStopAudio is true
    expect(mockAudio.didStopAudio, isTrue);
  });

  testWidgets(
    'ContentGridScreen shows Study Cards action button and navigates',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final router = GoRouter(
        initialLocation: '/grid/lesson_123',
        routes: [
          GoRoute(
            path: '/grid/:subcategoryId',
            builder: (context, state) => ContentGridScreen(
              kind: ContentKind.letter,
              subcategoryId: state.pathParameters['subcategoryId'],
            ),
          ),
          GoRoute(
            path: '/lesson/:lessonId',
            builder: (context, state) {
              return Scaffold(
                body: Text(
                  'Lesson Detail: ${state.pathParameters['lessonId']}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            contentListProvider((
              ContentKind.letter,
              'lesson_123',
            )).overrideWith((ref) => [mockLetterItemSilentNoTracing]),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Study Cards button is present
      expect(find.byIcon(Icons.view_carousel_rounded), findsOneWidget);

      // Tap Study Cards button
      await tester.tap(find.byIcon(Icons.view_carousel_rounded));
      await tester.pumpAndSettle();

      // Verify navigation occurred to /lesson/lesson_123
      expect(find.text('Lesson Detail: lesson_123'), findsOneWidget);
    },
  );
}
