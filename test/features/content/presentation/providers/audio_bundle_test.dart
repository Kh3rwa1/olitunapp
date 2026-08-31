import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';

/// Builds a track row the way the admin CMS would store it.
AudioTrack track(
  String id,
  TrackType type,
  String languageCode, {
  String? url = 'https://example.com/audio.mp3',
  bool isHumanRecorded = true,
  ReviewStatus reviewStatus = ReviewStatus.approved,
  String contentKind = 'word',
  String contentId = 'w1',
}) {
  return AudioTrack(
    id: id,
    contentKind: contentKind,
    contentId: contentId,
    languageCode: languageCode,
    trackType: type,
    audioUrl: url,
    isHumanRecorded: isHumanRecorded,
    reviewStatus: reviewStatus,
  );
}

void main() {
  group('AudioBundle santali audio resolution', () {
    test('prefers the playable targetNormal track over the legacy URL', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        legacyAudioUrl: 'https://legacy.mp3',
        teachingLanguage: 'en',
        tracks: [
          track('t1', TrackType.targetNormal, 'sat', url: 'https://new.mp3'),
        ],
      );

      expect(bundle.santaliAudioUrl, 'https://new.mp3');
    });

    test('falls back to the legacy inline audioUrl', () {
      const bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        legacyAudioUrl: 'https://legacy.mp3',
        teachingLanguage: 'en',
      );

      expect(bundle.santaliAudioUrl, 'https://legacy.mp3');
    });

    test('unapproved synthetic Santali track is not playable', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track(
            't1',
            TrackType.targetNormal,
            'sat',
            isHumanRecorded: false,
            reviewStatus: ReviewStatus.needsReview,
          ),
        ],
      );

      expect(bundle.santaliAudioUrl, isNull);
      expect(bundle.hasPendingSantaliAudio, isTrue);
    });

    test('slow audio never falls back to the normal clip', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track('t1', TrackType.targetNormal, 'sat', url: 'https://new.mp3'),
        ],
      );

      expect(bundle.santaliAudioUrl, 'https://new.mp3');
      expect(bundle.slowAudioUrl, isNull);
    });

    test('teaching clips only match the teaching language', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'hi',
        tracks: [
          track('t1', TrackType.explanation, 'en', isHumanRecorded: false),
          track('t2', TrackType.explanation, 'hi', isHumanRecorded: false),
        ],
      );

      expect(bundle.explanationAudioUrl, isNotNull);
      expect(bundle.explanationTrack!.languageCode, 'hi');
    });
  });

  group('AudioBundle meaning resolution', () {
    test('approved localization wins over the legacy meaning', () {
      const bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        legacyMeaning: 'legacy meaning',
        teachingLanguage: 'en',
        localization: LocalizedContent(
          id: 'l1',
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'en',
          meaning: 'approved meaning',
          reviewStatus: ReviewStatus.approved,
        ),
      );

      expect(bundle.meaning, 'approved meaning');
    });

    test('unapproved localization falls back to the legacy meaning', () {
      const bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        legacyMeaning: 'legacy meaning',
        teachingLanguage: 'en',
        localization: LocalizedContent(
          id: 'l1',
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'en',
          meaning: 'draft meaning',
        ),
      );

      expect(bundle.meaning, 'legacy meaning');
    });

    test('approved localization with empty meaning falls back', () {
      const bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        legacyMeaning: 'legacy meaning',
        teachingLanguage: 'en',
        localization: LocalizedContent(
          id: 'l1',
          contentKind: 'word',
          contentId: 'w1',
          languageCode: 'en',
          meaning: '',
          reviewStatus: ReviewStatus.approved,
        ),
      );

      expect(bundle.meaning, 'legacy meaning');
    });

    test('no localization at all uses the legacy meaning', () {
      const bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        legacyMeaning: 'legacy meaning',
        teachingLanguage: 'en',
      );

      expect(bundle.meaning, 'legacy meaning');
    });
  });

  group('AudioBundle playbackChain', () {
    test('targetOnly and translationOnDemand play just the Santali clip', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track('t1', TrackType.targetNormal, 'sat', url: 'https://sat.mp3'),
          track(
            't2',
            TrackType.explanation,
            'en',
            isHumanRecorded: false,
            url: 'https://en.mp3',
          ),
        ],
      );

      for (final mode in [
        LessonAudioMode.targetOnly,
        LessonAudioMode.translationOnDemand,
      ]) {
        final chain = bundle.playbackChain(mode)!;
        expect(chain.id, 'https://sat.mp3');
        expect(chain.trackType, TrackType.targetNormal.name);
        expect(chain.languageCode, 'sat');
        expect(chain.next, isNull);
      }
    });

    test('bilingual chains Santali then the explanation clip', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track('t1', TrackType.targetNormal, 'sat', url: 'https://sat.mp3'),
          track(
            't2',
            TrackType.explanation,
            'en',
            isHumanRecorded: false,
            url: 'https://en-expl.mp3',
          ),
        ],
      );

      final chain = bundle.playbackChain(LessonAudioMode.bilingual)!;

      expect(chain.id, 'https://sat.mp3');
      expect(chain.next!.id, 'https://en-expl.mp3');
      expect(chain.next!.trackType, TrackType.explanation.name);
      expect(chain.next!.languageCode, 'en');
      expect(chain.next!.next, isNull);
    });

    test('bilingual falls back to translation when no explanation exists', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track('t1', TrackType.targetNormal, 'sat', url: 'https://sat.mp3'),
          track(
            't2',
            TrackType.translation,
            'en',
            isHumanRecorded: false,
            url: 'https://en-trans.mp3',
          ),
        ],
      );

      final chain = bundle.playbackChain(LessonAudioMode.bilingual)!;

      expect(chain.next!.id, 'https://en-trans.mp3');
      expect(chain.next!.trackType, TrackType.translation.name);
    });

    test('returns null when nothing is playable', () {
      const bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
      );

      expect(bundle.playbackChain(LessonAudioMode.bilingual), isNull);
      expect(bundle.playbackChain(LessonAudioMode.targetOnly), isNull);
    });

    test('missing Santali clip yields null even with teaching audio', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track(
            't2',
            TrackType.explanation,
            'en',
            isHumanRecorded: false,
            url: 'https://en.mp3',
          ),
        ],
      );

      expect(bundle.playbackChain(LessonAudioMode.bilingual), isNull);
    });
  });

  group('AudioBundle meaningPlaybackRequest', () {
    test('prefers translation and falls back to explanation', () {
      final withBoth = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track(
            't1',
            TrackType.translation,
            'en',
            isHumanRecorded: false,
            url: 'https://trans.mp3',
          ),
          track(
            't2',
            TrackType.explanation,
            'en',
            isHumanRecorded: false,
            url: 'https://expl.mp3',
          ),
        ],
      );
      expect(withBoth.meaningPlaybackRequest()!.id, 'https://trans.mp3');

      final withExplanationOnly = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [
          track(
            't2',
            TrackType.explanation,
            'en',
            isHumanRecorded: false,
            url: 'https://expl.mp3',
          ),
        ],
      );
      expect(
        withExplanationOnly.meaningPlaybackRequest()!.id,
        'https://expl.mp3',
      );
    });

    test('returns null when no teaching audio exists', () {
      final bundle = AudioBundle(
        contentKind: 'word',
        contentId: 'w1',
        teachingLanguage: 'en',
        tracks: [track('t1', TrackType.targetNormal, 'sat')],
      );

      expect(bundle.meaningPlaybackRequest(), isNull);
    });
  });

  group('AudioBundleRequest equality', () {
    test('covers kind, id and legacy fallbacks', () {
      const a = AudioBundleRequest(
        contentKind: 'word',
        contentId: 'w1',
        legacyAudioUrl: 'https://legacy.mp3',
        legacyMeaning: 'm',
      );
      const same = AudioBundleRequest(
        contentKind: 'word',
        contentId: 'w1',
        legacyAudioUrl: 'https://legacy.mp3',
        legacyMeaning: 'm',
      );
      const other = AudioBundleRequest(contentKind: 'word', contentId: 'w2');

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(other));
    });
  });

  group('PlaybackRequest identity used by the bundle', () {
    test('chain metadata carries content identity for analytics', () {
      final bundle = AudioBundle(
        contentKind: 'sentence',
        contentId: 's9',
        teachingLanguage: 'hi',
        tracks: [
          track(
            't1',
            TrackType.targetNormal,
            'sat',
            url: 'https://sat.mp3',
            contentKind: 'sentence',
            contentId: 's9',
          ),
        ],
      );

      final chain = bundle.playbackChain(LessonAudioMode.targetOnly)!;

      expect(chain.contentKind, 'sentence');
      expect(chain.contentId, 's9');
      expect(chain.trackType, TrackType.targetNormal.name);
      expect(chain.languageCode, 'sat');
    });
  });
}
