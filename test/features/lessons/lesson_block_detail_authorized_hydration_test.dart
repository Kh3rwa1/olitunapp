import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/shared/providers/providers.dart';

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
}

void main() {
  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('metadata-only catalog hydrates authorized authored blocks', (
    tester,
  ) async {
    const metadataLesson = LessonEntity(
      id: 'lesson_vocab_metadata',
      categoryId: 'cat_vocab',
      titleOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
      titleLatin: 'Vocabulary',
    );
    const hydratedLesson = LessonEntity(
      id: 'lesson_vocab_metadata',
      categoryId: 'cat_vocab',
      titleOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
      titleLatin: 'Vocabulary',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱡᱚᱦᱟᱨ',
          textLatin: 'Johar',
        ),
        LessonBlockEntity(type: 'text', textOlChiki: 'ᱫᱟᱜ', textLatin: 'Water'),
      ],
    );
    final mockAudioService = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data([metadataLesson]),
          ),
          lessonsByCategoryProvider(
            'cat_vocab',
          ).overrideWithValue(const AsyncValue.data([metadataLesson])),
          learnerLessonDetailProvider(
            metadataLesson.id,
          ).overrideWith((ref) => hydratedLesson),
          audioServiceProvider.overrideWithValue(mockAudioService),
          reduceVisualEffectsProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_vocab_metadata',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Johar'), findsWidgets);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    final delegate = pageView.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, 3);
  });
}
