import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';
import 'package:itun/features/content/domain/entities/story_segment_entity.dart';

AudioTrack _narration({
  String url = 'https://cdn.example.com/n.mp3',
  ReviewStatus status = ReviewStatus.approved,
  bool human = true,
}) {
  return AudioTrack(
    id: 't-narr',
    contentKind: 'story',
    contentId: 's1',
    segmentId: 'seg1',
    languageCode: 'sat',
    trackType: TrackType.storyNarration,
    audioUrl: url,
    reviewStatus: status,
    isHumanRecorded: human,
  );
}

AudioTrack _translation(
  String languageCode, {
  String url = 'https://cdn.example.com/t.mp3',
  ReviewStatus status = ReviewStatus.approved,
}) {
  return AudioTrack(
    id: 't-$languageCode',
    contentKind: 'story',
    contentId: 's1',
    segmentId: 'seg1',
    languageCode: languageCode,
    trackType: TrackType.storyTranslation,
    audioUrl: url,
    reviewStatus: status,
  );
}

void main() {
  group('StorySegment', () {
    test('creates with defaults', () {
      const segment = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱥᱟᱱᱴᱟᱞ',
      );

      expect(segment.textLatin, isNull);
      expect(segment.translations, isEmpty);
      expect(segment.audioTracks, isEmpty);
      expect(segment.vocabularyRefs, isEmpty);
      expect(segment.narrationTrack, isNull);
    });

    test('translationFor falls back selected → en → Latin → Ol Chiki', () {
      const segment = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
        textLatin: 'johar',
        translations: {'en': 'hello (en)', 'hi': 'नमस्ते'},
      );

      expect(segment.translationFor('hi'), 'नमस्ते');
      expect(
        segment.translationFor('or'),
        'hello (en)',
        reason: 'falls back to English',
      );
      expect(segment.translationFor('en'), 'hello (en)');

      final latinOnly = segment.copyWith(translations: {});
      expect(
        latinOnly.translationFor('hi'),
        'johar',
        reason: 'falls back to Latin',
      );

      const bare = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
      );
      expect(
        bare.translationFor('hi'),
        'ᱡᱚᱦᱟᱨ',
        reason: 'falls back to Ol Chiki',
      );
    });

    test('narrationTrack returns first playable Santali narration', () {
      final withTrack = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
        audioTracks: [
          // Synthetic Santali narration is forbidden → not playable.
          _narration(status: ReviewStatus.needsReview, human: false),
          _narration(),
          _translation('hi'),
        ],
      );
      expect(withTrack.narrationTrack?.id, 't-narr');

      final unplayable = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
        audioTracks: [
          _narration(status: ReviewStatus.needsReview, human: false),
        ],
      );
      expect(unplayable.narrationTrack, isNull);
    });

    test('translationTrackFor matches language and playability', () {
      final segment = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
        audioTracks: [
          _narration(),
          _translation('hi'),
          _translation('bn', status: ReviewStatus.rejected),
        ],
      );

      expect(segment.translationTrackFor('hi')?.id, 't-hi');
      expect(
        segment.translationTrackFor('bn'),
        isNull,
        reason: 'rejected not playable',
      );
      expect(segment.translationTrackFor('or'), isNull, reason: 'no track');
    });

    test('copyWith preserves unchanged fields', () {
      const original = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 3,
        textOlChiki: 'ᱥᱟᱱ',
        textLatin: 'santaḷ',
        translations: {'en': 'hello'},
        startMs: 1200,
        endMs: 3400,
        imageUrl: 'https://cdn.example.com/img.png',
        vocabularyRefs: ['w1', 'w2'],
      );

      final copy = original.copyWith(order: 4);

      expect(copy.id, 'seg1');
      expect(copy.storyId, 's1');
      expect(copy.textOlChiki, 'ᱥᱟᱱ');
      expect(copy.textLatin, 'santaḷ');
      expect(copy.translations['en'], 'hello');
      expect(copy.startMs, 1200);
      expect(copy.endMs, 3400);
      expect(copy.imageUrl, 'https://cdn.example.com/img.png');
      expect(copy.vocabularyRefs, ['w1', 'w2']);
      expect(copy.order, 4);
    });

    test('equality via props', () {
      const a = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
      );
      const b = StorySegment(
        id: 'seg1',
        storyId: 's1',
        order: 1,
        textOlChiki: 'ᱡᱚᱦᱟᱨ',
      );
      expect(a, b);
      expect(a == b.copyWith(order: 2), isFalse);
    });
  });
}
