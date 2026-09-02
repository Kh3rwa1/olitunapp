import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/features/content/presentation/widgets/premium_bakhed_body.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _FakeDbService extends Mock implements AppwriteDbService {}

// Exercises the lyrics/vocabulary/cultural-notes panel builders declared in
// the premium_bakhed_body_content.dart part of premium_bakhed_body.dart.
void main() {
  late _MockAudioService audio;
  late _FakeDbService db;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    audio = _MockAudioService();
    db = _FakeDbService();
    when(
      () => db.getFileViewUrl(any(), any()),
    ).thenReturn('https://cdn.test/file.mp3');
  });

  final item = ContentItem(
    id: 'bakhed-1',
    kind: ContentKind.rhyme,
    categoryId: 'cat_rhymes',
    title: 'Rain Song',
    blocks: const [],
    updatedAt: DateTime(2026, 5, 25),
  );

  Future<void> pumpBody(
    WidgetTester tester, {
    required BakhedLearningContent content,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // PremiumBakhedBody's fixed column needs a tall portrait surface.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          playbackControllerProvider.overrideWithValue(
            PlaybackController(audioService: audio),
          ),
          appwriteDbServiceProvider.overrideWithValue(db),
          bakhedLearningContentProvider(
            'bakhed-1',
          ).overrideWith((ref) async => content),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PremiumBakhedBody(item: item, accentColor: Colors.teal),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('vocabulary panel renders items and plays word audio', (
    tester,
  ) async {
    await pumpBody(
      tester,
      content: const BakhedLearningContent(
        vocabulary: [
          BakhedVocabularyItem(
            id: 'v1',
            olChiki: 'ᱫᱟᱜ',
            latin: 'daa',
            meaning: 'water',
            audioFileId: 'file-1',
            sortOrder: 0,
          ),
        ],
      ),
    );

    await tester.tap(find.text('Vocabulary'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ᱫᱟᱜ'), findsOneWidget);
    expect(find.text('daa'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump(const Duration(milliseconds: 100));

    expect(db.getFileViewUrl('audio', 'file-1'), 'https://cdn.test/file.mp3');
  });

  testWidgets('empty vocabulary shows the placeholder message', (tester) async {
    await pumpBody(tester, content: const BakhedLearningContent());

    await tester.tap(find.text('Vocabulary'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No vocabulary items defined.'), findsOneWidget);
  });

  testWidgets('cultural notes panel shows published notes with sources', (
    tester,
  ) async {
    await pumpBody(
      tester,
      content: const BakhedLearningContent(
        culturalNotes: [
          BakhedCulturalNote(
            noteId: 'n1',
            title: 'Harvest call',
            body: 'Sung before the harvest festival',
            source: 'Field recording 2025',
            isPublished: true,
          ),
        ],
      ),
    );

    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Harvest call'), findsOneWidget);
    expect(find.textContaining('harvest festival'), findsOneWidget);
    expect(find.textContaining('Field recording 2025'), findsOneWidget);
  });

  testWidgets('unpublished notes fall back to the preparing message', (
    tester,
  ) async {
    await pumpBody(
      tester,
      content: const BakhedLearningContent(
        culturalNotes: [
          BakhedCulturalNote(
            noteId: 'n2',
            title: 'Draft note',
            body: 'Not approved yet',
            source: '',
          ),
        ],
      ),
    );

    await tester.tap(find.text('Notes'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cultural notes are being prepared.'), findsOneWidget);
    expect(find.text('Draft note'), findsNothing);
  });
}
