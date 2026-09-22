import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/core/languages/providers/target_language_provider.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/category_lessons_screen.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/shared/providers/purchases_provider.dart';

class MockCategoryNotifier extends CategoryNotifier {
  final List<CategoryEntity> _initial;
  MockCategoryNotifier(this._initial);

  @override
  AsyncValue<List<CategoryEntity>> build() => AsyncValue.data(_initial);
  @override
  Future<void> loadCategories() async {}
}

class MockPlaybackController extends Mock implements PlaybackController {}

class MockAudioService extends Mock implements AudioService {
  @override
  Future<void> playUrl(String url) async {}
  @override
  Future<bool> tryPlayUrl(
    String url, {
    String title = 'Pronunciation',
    String album = 'Olitun',
    Uri? artUri,
  }) async => true;
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
  @override
  Stream<void> get webPlaybackEndedStream => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const mockAlphabetCategory = CategoryEntity(
    id: 'cat_alphabets',
    titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
    titleLatin: 'Alphabets',
    totalLessons: 1,
  );

  final mockLessons = [
    const LessonEntity(
      id: 'lesson_vowels_1',
      categoryId: 'cat_alphabets',
      titleOlChiki: 'ᱚ',
      titleLatin: 'Vowels I',
    ),
  ];

  group('CategoryLessonsScreen Language Adaptability', () {
    testWidgets(
      'shows Santali Ol Chiki by default when target language is sat',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              categoryNotifierProvider.overrideWith(
                () => MockCategoryNotifier([mockAlphabetCategory]),
              ),
              lessonsByCategoryProvider(
                'cat_alphabets',
              ).overrideWith((ref) => AsyncValue.data(mockLessons)),
              purchasedCategoriesProvider.overrideWith(
                (ref) => {'cat_alphabets'},
              ),
              effectiveScriptModeProvider.overrideWith((ref) => 'both'),
              targetLanguageCodeProvider.overrideWith(
                (ref) => TargetLanguageNotifier(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CategoryLessonsScreen(categoryId: 'cat_alphabets'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ol Chiki'), findsOneWidget);
        expect(find.text('ᱚᱞ ᱪᱤᱠᱤ'), findsWidgets);
        // No preview banner for active Santali language
        expect(
          find.textContaining('course packs are in preview'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'dynamically shows Warang Citi & preview banner when target language is Ho',
      (tester) async {
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              categoryNotifierProvider.overrideWith(
                () => MockCategoryNotifier([mockAlphabetCategory]),
              ),
              lessonsByCategoryProvider(
                'cat_alphabets',
              ).overrideWith((ref) => AsyncValue.data(mockLessons)),
              purchasedCategoriesProvider.overrideWith(
                (ref) => {'cat_alphabets'},
              ),
              effectiveScriptModeProvider.overrideWith((ref) => 'both'),
              targetLanguageCodeProvider.overrideWith(
                (ref) => TargetLanguageNotifier('hoc'),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: CategoryLessonsScreen(categoryId: 'cat_alphabets'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Browse all card adapts to Warang Citi
        expect(find.text('Warang Citi'), findsOneWidget);
        expect(find.text('𑢹𑣗𑢡𑣊 𑢔𑣂𑢻𑣂'), findsOneWidget);

        // Subtitle in hero header adapts to Ho native name
        expect(find.text('𑢹𑣉 ᱡᱟᱜᱟᱨ'), findsOneWidget);

        // Preview banner is shown for Ho
        expect(
          find.text(
            'Ho (Warang Citi) course packs are in preview. Foundational learning content is active.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('LessonBlockDetailScreen Language Playback & Reactivity', () {
    testWidgets('plays audio with active target language code', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final mockPlayback = MockPlaybackController();
      when(
        () => mockPlayback.playSingle(
          id: any(named: 'id'),
          contentKind: any(named: 'contentKind'),
          contentId: any(named: 'contentId'),
          trackType: any(named: 'trackType'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async {});

      const lesson = LessonEntity(
        id: 'lesson_test_1',
        categoryId: 'cat_alphabets',
        titleOlChiki: 'ᱚ',
        titleLatin: 'Test Lesson',
        blocks: [
          LessonBlockEntity(
            type: 'text',
            textOlChiki: 'ᱚ',
            textLatin: 'A',
            audioUrl: 'https://example.com/audio_a.mp3',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            playbackControllerProvider.overrideWithValue(mockPlayback),
            learnerLessonsProvider.overrideWith(
              (ref) => const AsyncValue.data([lesson]),
            ),
            learnerLessonDetailProvider(
              'lesson_test_1',
            ).overrideWith((ref) => Future.value(lesson)),
            targetLanguageCodeProvider.overrideWith(
              (ref) => TargetLanguageNotifier('hoc'),
            ),
            effectiveTeachingLanguageProvider.overrideWith((ref) => 'en'),
            effectiveScriptModeProvider.overrideWith((ref) => 'both'),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_test_1',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap LISTEN button
      expect(find.text('LISTEN'), findsOneWidget);
      await tester.tap(find.text('LISTEN'));
      await tester.pump();

      // Verify playSingle was invoked with active languageCode: 'hoc'
      verify(
        () => mockPlayback.playSingle(
          id: 'https://example.com/audio_a.mp3',
          contentKind: 'lesson',
          contentId: any(named: 'contentId'),
          trackType: 'targetNormal',
          languageCode: 'hoc',
        ),
      ).called(1);

      await tester.pump(const Duration(seconds: 2));
    });
  });
}
