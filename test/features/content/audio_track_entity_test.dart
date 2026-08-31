import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';

void main() {
  group('TrackType', () {
    test('tryFromName parses all ten track types', () {
      expect(TrackType.tryFromName('targetNormal'), TrackType.targetNormal);
      expect(TrackType.tryFromName('targetSlow'), TrackType.targetSlow);
      expect(TrackType.tryFromName('targetSyllable'), TrackType.targetSyllable);
      expect(TrackType.tryFromName('explanation'), TrackType.explanation);
      expect(TrackType.tryFromName('translation'), TrackType.translation);
      expect(TrackType.tryFromName('instruction'), TrackType.instruction);
      expect(TrackType.tryFromName('storyNarration'), TrackType.storyNarration);
      expect(
        TrackType.tryFromName('storyTranslation'),
        TrackType.storyTranslation,
      );
      expect(
        TrackType.tryFromName('exampleSentence'),
        TrackType.exampleSentence,
      );
      expect(TrackType.tryFromName('feedback'), TrackType.feedback);
    });

    test('tryFromName returns null for unknown or null (legacy safe)', () {
      expect(TrackType.tryFromName('bogus'), isNull);
      expect(TrackType.tryFromName(null), isNull);
      expect(TrackType.tryFromName(''), isNull);
    });
  });

  group('GenerationStatus', () {
    test('fromName parses all statuses and defaults to notRequested', () {
      expect(
        GenerationStatus.fromName('notRequested'),
        GenerationStatus.notRequested,
      );
      expect(GenerationStatus.fromName('queued'), GenerationStatus.queued);
      expect(
        GenerationStatus.fromName('processing'),
        GenerationStatus.processing,
      );
      expect(
        GenerationStatus.fromName('completed'),
        GenerationStatus.completed,
      );
      expect(GenerationStatus.fromName('failed'), GenerationStatus.failed);
      expect(GenerationStatus.fromName('weird'), GenerationStatus.notRequested);
      expect(GenerationStatus.fromName(null), GenerationStatus.notRequested);
    });
  });

  group('AudioTrack', () {
    test('creates with defaults', () {
      const track = AudioTrack(
        id: 't1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
      );

      expect(track.segmentId, isNull);
      expect(track.audioUrl, isNull);
      expect(track.isHumanRecorded, isFalse);
      expect(track.generationStatus, GenerationStatus.notRequested);
      expect(track.reviewStatus, ReviewStatus.draft);
      expect(track.isPlayable, isFalse);
    });

    test('isPlayable requires audio plus approval or human recording', () {
      const noAudio = AudioTrack(
        id: 't1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        isHumanRecorded: true,
      );
      expect(noAudio.isPlayable, isFalse, reason: 'no audioUrl');

      const unapprovedSynthetic = AudioTrack(
        id: 't2',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        trackType: TrackType.translation,
        audioUrl: 'https://cdn.example.com/t2.mp3',
      );
      expect(unapprovedSynthetic.isPlayable, isFalse, reason: 'not approved');

      const humanUpload = AudioTrack(
        id: 't3',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        audioUrl: 'https://cdn.example.com/t3.mp3',
        isHumanRecorded: true,
      );
      expect(humanUpload.isPlayable, isTrue, reason: 'human recorded');

      const approvedSynthetic = AudioTrack(
        id: 't4',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'hi',
        trackType: TrackType.translation,
        audioUrl: 'https://cdn.example.com/t4.mp3',
        reviewStatus: ReviewStatus.approved,
      );
      expect(approvedSynthetic.isPlayable, isTrue, reason: 'approved');
    });

    test('isTargetAudio covers Santali track types only', () {
      for (final type in TrackType.values) {
        final track = AudioTrack(
          id: 't',
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'sat',
          trackType: type,
        );
        final expected =
            type == TrackType.targetNormal ||
            type == TrackType.targetSlow ||
            type == TrackType.targetSyllable ||
            type == TrackType.storyNarration;
        expect(track.isTargetAudio, expected, reason: type.name);
      }
    });

    test('idempotencyKey covers the composite key from the spec', () {
      const withAll = AudioTrack(
        id: 't1',
        contentKind: 'story',
        contentId: 's1',
        segmentId: 'seg2',
        languageCode: 'hi',
        trackType: TrackType.storyTranslation,
        contentHash: 'abc123',
      );
      expect(
        withAll.idempotencyKey,
        'story:s1:seg2:hi:storyTranslation:abc123',
      );

      const minimal = AudioTrack(
        id: 't2',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
      );
      expect(minimal.idempotencyKey, 'word:w1:-:sat:targetNormal:-');

      // Different hash → different key (re-generation detects change).
      final changed = minimal.copyWith(contentHash: 'zzz');
      expect(changed.idempotencyKey, 'word:w1:-:sat:targetNormal:zzz');
      expect(changed.idempotencyKey == minimal.idempotencyKey, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      const original = AudioTrack(
        id: 't1',
        contentKind: 'word',
        contentId: 'w1',
        segmentId: 'seg1',
        languageCode: 'sat',
        trackType: TrackType.storyNarration,
        audioUrl: 'https://cdn.example.com/a.mp3',
        isHumanRecorded: true,
        generationStatus: GenerationStatus.completed,
        contentHash: 'h1',
      );

      final copy = original.copyWith(
        generationStatus: GenerationStatus.failed,
        errorMessage: 'provider timeout',
      );

      expect(copy.id, 't1');
      expect(copy.segmentId, 'seg1');
      expect(copy.audioUrl, 'https://cdn.example.com/a.mp3');
      expect(copy.isHumanRecorded, isTrue);
      expect(copy.contentHash, 'h1');
      expect(copy.generationStatus, GenerationStatus.failed);
      expect(copy.errorMessage, 'provider timeout');
    });

    test('equality via props', () {
      const a = AudioTrack(
        id: 't1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        audioUrl: 'u',
      );
      const b = AudioTrack(
        id: 't1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        audioUrl: 'u',
      );
      expect(a, b);
      expect(a == b.copyWith(audioUrl: 'v'), isFalse);
    });
  });
}
