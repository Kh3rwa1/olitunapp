import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/audio/audio_service.dart';
import '../../../lib/features/content/presentation/providers/audio_playback_providers.dart';
import '../../../lib/features/lessons/domain/entities/lesson_entity.dart';
import '../../../lib/features/lessons/presentation/lesson_block_detail_screen.dart';
import '../../../lib/features/lessons/presentation/providers/lesson_progression_provider.dart';
import '../../../lib/features/settings/presentation/providers/settings_notifier.dart';
import '../../../lib/shared/providers/providers.dart';

void main() {
  const metadataLesson = LessonEntity(
    id: 'lesson_vocab_metadata',
    categoryId: 'cat_vocab',
    titleOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
    titleLatin: 'Vocabulary',
    level: 'beginner',
    description: 'Vocabulary basics',
    order: 0,
    estimatedMinutes: 10,
    isActive: true,
    isPreview: true,
    isLocked: false,
    blocks: [],
  );

  const hydratedLesson = LessonEntity(
    id: 'lesson_vocab_metadata',
    categoryId: 'cat_vocab',
    titleOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
    titleLatin: 'Vocabulary',
    level: 'beginner',
    description: 'Vocabulary basics',
    order: 0,
    estimatedMinutes: 10,
    isActive: true,
    isPreview: true,
    isLocked: false,
    blocks: [
      LessonBlockEntity(
        type: 'text',
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
        textLatin: 'Johar',
      ),
      LessonBlockEntity(
        type: 'text',
        textOlChiki: 'ᱫᱟᱜ',
        textLatin: 'Water',
      ),
    ],
  );

  testWidgets(
    'metadata-only catalog hydrates authorized authored blocks',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            learnerLessonsProvider.overrideWith((ref) => [metadataLesson]),
            lessonsByCategoryProvider(
              metadataLesson.categoryId,
            ).overrideWith((ref) => [metadataLesson]),
            learnerLessonDetailProvider(
              metadataLesson.id,
            ).overrideWith((ref) => hydratedLesson),
            settingsProvider.overrideWith((ref) => _TestSettingsNotifier()),
            lessonProgressProvider.overrideWith(
              (ref) => const AsyncValue.data(<String, double>{}),
            ),
            audioServiceProvider.overrideWithValue(_NoopAudioService()),
          ],
          child: const MaterialApp(
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_vocab_metadata',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Johar'), findsOneWidget);
      final pageView = tester.widget<PageView>(find.byType(PageView));
      final delegate = pageView.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 3);
    },
  );
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier() {
    state = state.copyWith(
      preferredLanguages: const ['en'],
      userScript: 'olChiki',
      preferredScripts: const ['ol_chiki'],
    );
  }
}

class _NoopAudioService implements AudioService {
  @override
  Stream<AudioPlaybackState> get playbackStateStream =>
      const Stream<AudioPlaybackState>.empty();

  @override
  Future<void> dispose() async {}

  @override
  Future<Uri> getTrackUri({
    required String contentKind,
    required String contentId,
    required AudioTrackVariant track,
    String? languageCode,
  }) async => Uri.parse('https://example.com/$contentId.mp3');

  @override
  Future<void> pause() async {}

  @override
  Future<void> playSingle({
    required String contentKind,
    required String contentId,
    required AudioTrackVariant track,
    String? languageCode,
  }) async {}

  @override
  Future<void> playSequence({
    required String contentKind,
    required String contentId,
    required List<AudioTrackVariant> tracks,
    String? languageCode,
    Duration gap = const Duration(milliseconds: 250),
    AudioPlayMode mode = AudioPlayMode.sequence,
  }) async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> stop() async {}
}
