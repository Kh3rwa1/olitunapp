import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/features/lessons/presentation/widgets/full_bleed_hero_media.dart';

/// Concrete overrides are required (not mocktail stubs) because the central
/// PlaybackController subscribes to these streams in its constructor — an
/// unstubbed mocktail getter would throw, and real just_audio streams would
/// leak a periodic position timer into the test binding. Empty streams keep
/// the controller idle until a page change triggers auto-play.
class MockAudioService extends Mock implements AudioService {
  @override
  Future<void> playUrl(String url) async {}

  @override
  Future<bool> tryPlayUrl(String url) async => true;

  @override
  Future<void> stop() async {}

  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<bool> get isPlayingStream => const Stream.empty();
}

const svgData =
    '<svg height="100" width="100"><circle cx="50" cy="50" r="40" /></svg>';

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient();
  }
}

class FakeHttpClient implements HttpClient {
  @override
  Duration? connectionTimeout;

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Future.value(FakeHttpClientRequest());
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.value(FakeHttpClientRequest());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  bool persistentConnection = true;
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;

  @override
  void add(List<int> data) {}
  @override
  Future addStream(Stream<List<int>> stream) => Future.value();
  @override
  Future<HttpClientResponse> close() => Future.value(FakeHttpClientResponse());

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && invocation.memberName == #done) {
      return Future.value(FakeHttpClientResponse());
    }
    return null;
  }
}

class FakeHttpClientResponse implements HttpClientResponse {
  @override
  final HttpHeaders headers = FakeHttpHeaders();

  @override
  int get statusCode => 200;
  @override
  int get contentLength => svgData.length;
  @override
  bool get isRedirect => false;
  @override
  bool get persistentConnection => true;
  @override
  List<RedirectInfo> get redirects => const [];

  @override
  String get reasonPhrase => 'OK';

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(utf8.encode(svgData));
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class FakeHttpHeaders implements HttpHeaders {
  @override
  List<String>? operator [](String name) => null;
  @override
  String? value(String name) => null;

  @override
  bool chunkedTransferEncoding = false;
  @override
  int contentLength = 0;
  @override
  bool persistentConnection = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  final mockLessons = [
    const LessonEntity(
      id: 'lesson_1',
      categoryId: 'cat_1',
      titleOlChiki: 'ᱛᱤ',
      titleLatin: 'Ti',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚ',
          textLatin: 'At',
          audioUrl: 'https://example.com/audio1.mp3',
          data: {'pronunciation': 'at', 'themeColor': '#10B981'},
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱛ',
          textLatin: 'Ot',
          audioUrl: 'https://example.com/audio2.mp3',
          data: {'pronunciation': 'ot', 'themeColor': '#14B8A6'},
        ),
      ],
    ),
  ];

  testWidgets('LessonBlockDetailScreen shows loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learnerLessonsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LessonBlockDetailScreen shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.error('Error loading', StackTrace.empty),
          ),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Could not load lesson details'), findsOneWidget);
  });

  testWidgets('LessonBlockDetailScreen shows not found state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learnerLessonsProvider.overrideWithValue(const AsyncValue.data([])),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Lesson not found'), findsOneWidget);
  });

  testWidgets(
    'LessonBlockDetailScreen renders content details and page swiping works',
    (tester) async {
      final mockAudioService = MockAudioService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              AsyncValue.data(mockLessons),
            ),
            audioServiceProvider.overrideWithValue(mockAudioService),
            reduceVisualEffectsProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_1',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first page renders details
      expect(find.text('At (at)'), findsOneWidget);
      expect(find.text('AT (AT)'), findsOneWidget);
      expect(find.text('Pronunciation'), findsOneWidget);
      expect(find.text('at'), findsOneWidget);

      // Slide/Swipe to the second page
      final pageViewFinder = find.byType(PageView);
      expect(pageViewFinder, findsOneWidget);

      await tester.fling(pageViewFinder, const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      // Verify second page renders details
      expect(find.text('Ot (ot)'), findsOneWidget);
      expect(find.text('OT (OT)'), findsOneWidget);
      expect(find.text('ot'), findsOneWidget);
    },
  );

  testWidgets(
    'LessonBlockDetailScreen resolves and renders different media types correctly',
    (tester) async {
      final mockAudioService = MockAudioService();
      final mediaLessons = [
        const LessonEntity(
          id: 'lesson_2',
          categoryId: 'cat_1',
          titleOlChiki: 'ᱛᱤ',
          titleLatin: 'Ti',
          blocks: [
            LessonBlockEntity(
              type: 'image',
              textLatin: 'Image Block',
              imageUrl:
                  'https://example.com/storage/buckets/images/files/img/view',
            ),
            LessonBlockEntity(
              type: 'text',
              textLatin: 'SVG Block',
              imageUrl:
                  'https://example.com/storage/buckets/images/files/svg/view',
              data: {'mediaType': 'svg'},
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              AsyncValue.data(mediaLessons),
            ),
            audioServiceProvider.overrideWithValue(mockAudioService),
            reduceVisualEffectsProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_2',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify first page renders image visual media details
      expect(find.byType(FullBleedHeroMedia), findsOneWidget);
      expect(find.text('Image Block'), findsNWidgets(2));

      // Swipe to second page (SVG block)
      final pageViewFinder = find.byType(PageView);
      await tester.fling(pageViewFinder, const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      // Verify second page renders SVG visual media details
      expect(find.byType(FullBleedHeroMedia), findsOneWidget);
      expect(find.text('SVG Block'), findsNWidgets(2));
    },
  );
}
