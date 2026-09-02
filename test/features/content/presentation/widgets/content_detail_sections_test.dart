import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/content/presentation/content_detail_screen.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/content_providers.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:shared_preferences/shared_preferences.dart';

/// AudioService double: records played URLs and never touches real audio
/// (story_player_body_test.dart precedent).
class _MockAudioService extends AudioService {
  final List<String> playedUrls = [];

  @override
  Future<bool> tryPlayUrl(String url) async {
    playedUrls.add(url);
    return true;
  }

  @override
  Future<void> playUrl(String url) async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> setSpeed(double speed) async {}

  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();
}

class _MockAnalyticsService implements LearningAnalyticsService {
  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ContentItem _lesson(List<ContentBlock> blocks) => ContentItem(
  id: 'lesson_blocks',
  kind: ContentKind.lesson,
  categoryId: 'alphabets',
  title: 'Block Tour',
  blocks: blocks,
  updatedAt: DateTime(2026, 5, 25),
);

Future<void> _pumpDetail(
  WidgetTester tester, {
  required ContentItem item,
  _MockAudioService? audio,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final audioService = audio ?? _MockAudioService();

  final router = GoRouter(
    initialLocation: '/content/lesson/lesson_blocks',
    routes: [
      GoRoute(
        path: '/content/lesson/:id',
        builder: (context, state) => ContentDetailScreen(
          kind: ContentKind.lesson,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/quiz/:quizId',
        builder: (context, state) =>
            Center(child: Text('Quiz ${state.pathParameters['quizId']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        audioServiceProvider.overrideWithValue(audioService),
        learningAnalyticsServiceProvider.overrideWithValue(
          _MockAnalyticsService(),
        ),
        playbackControllerProvider.overrideWithValue(
          PlaybackController(audioService: audioService),
        ),
        contentDetailProvider((
          ContentKind.lesson,
          'lesson_blocks',
        )).overrideWith((ref) => item),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // This suite exercises the _ContentBlockRenderer + _ContentDetailFooter
  // members of the content_detail_sections.dart part of
  // content_detail_screen.dart.

  testWidgets('renders markdown text blocks', (tester) async {
    await _pumpDetail(
      tester,
      item: _lesson([
        const TextBlock(
          id: 'b1',
          order: 0,
          markdown: 'This is the first letter of Ol Chiki.',
        ),
      ]),
    );

    expect(find.textContaining('first letter of Ol Chiki'), findsOneWidget);
  });

  testWidgets(
    'glyph blocks render script, latin and play through the controller',
    (tester) async {
      // Tall portrait surface so the glyph's play button is on-screen.
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audio = _MockAudioService();
      await _pumpDetail(
        tester,
        audio: audio,
        item: _lesson([
          const GlyphBlock(
            id: 'b2',
            order: 0,
            olChiki: 'ᱚ',
            latin: 'a',
            audioUrl: 'https://cdn.test/glyph-a.mp3',
          ),
        ]),
      );

      expect(find.text('ᱚ'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      expect(audio.playedUrls, contains('https://cdn.test/glyph-a.mp3'));
    },
  );

  testWidgets('callout blocks render variant icon and text', (tester) async {
    await _pumpDetail(
      tester,
      item: _lesson([
        const CalloutBlock(
          id: 'b3',
          order: 0,
          text: 'Pronounce from the throat',
          variant: CalloutVariant.tip,
        ),
      ]),
    );

    expect(find.text('Pronounce from the throat'), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
  });

  testWidgets('quiz blocks deep-link into the quiz route', (tester) async {
    await _pumpDetail(
      tester,
      item: _lesson([const QuizBlock(id: 'b4', order: 0, quizId: 'quiz-42')]),
    );

    expect(find.text('Take a Quiz'), findsOneWidget);
    expect(find.text('Test your knowledge now!'), findsOneWidget);

    await tester.tap(find.text('Take a Quiz'));
    await tester.pumpAndSettle();

    expect(find.text('Quiz quiz-42'), findsOneWidget);
  });

  testWidgets('lesson footer offers the finish CTA once tracing is satisfied', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      item: _lesson([
        const TextBlock(id: 'b5', order: 0, markdown: 'Plain text body'),
      ]),
    );

    // Lessons complete tracing implicitly, so the CTA is enabled.
    expect(find.text('Finish Practice (+25 stars)'), findsOneWidget);
    expect(find.text('Complete Tracing Exercise first'), findsNothing);
  });
}
