import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';
import 'package:itun/shared/models/content/localized_fallbacks.dart';
import 'package:itun/shared/models/content/sentence_model.dart';
import 'package:itun/shared/models/content/word_model.dart';

void main() {
  const approvedHi = LocalizedContent(
    id: 'lc1',
    contentKind: 'word',
    contentId: 'w1',
    languageCode: 'hi',
    meaning: 'नमस्ते',
    hint: 'अभिवादन',
    explanation: 'सामान्य अभिवादन',
    reviewStatus: ReviewStatus.approved,
  );

  const needsReviewHi = LocalizedContent(
    id: 'lc2',
    contentKind: 'word',
    contentId: 'w1',
    languageCode: 'hi',
    meaning: 'कच्चा अनुवाद',
    reviewStatus: ReviewStatus.needsReview,
  );

  group('WordModelLocalizedFallback', () {
    test('resolvedMeaning prefers approved localization over legacy', () {
      final word = WordModel(
        id: 'w1',
        wordOlChiki: 'ᱡᱚᱦᱟᱨ',
        wordLatin: 'johar',
        meaning: 'hello',
      );

      expect(word.resolvedMeaning(approvedHi), 'नमस्ते');
      expect(
        word.resolvedMeaning(needsReviewHi),
        'hello',
        reason: 'unapproved localization must not leak',
      );
      expect(word.resolvedMeaning(null), 'hello');
    });

    test('resolvedHint/Explanation only for approved localization', () {
      final word = WordModel(
        id: 'w1',
        wordOlChiki: 'ᱡᱚᱦᱟᱨ',
        wordLatin: 'johar',
        meaning: 'hello',
      );

      expect(word.resolvedHint(approvedHi), 'अभिवादन');
      expect(word.resolvedExplanation(approvedHi), 'सामान्य अभिवादन');
      expect(word.resolvedHint(needsReviewHi), isNull);
      expect(word.resolvedExplanation(needsReviewHi), isNull);
      expect(word.resolvedHint(null), isNull);
    });

    test('resolvedAudioUrl prefers playable track then legacy audioUrl', () {
      final word = WordModel(
        id: 'w1',
        wordOlChiki: 'ᱡᱚᱦᱟᱨ',
        wordLatin: 'johar',
        meaning: 'hello',
        audioUrl: 'https://cdn.example.com/legacy.mp3',
      );

      final playableTrack = AudioTrack(
        id: 't1',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        audioUrl: 'https://cdn.example.com/track.mp3',
        isHumanRecorded: true,
      );
      // copyWith cannot clear nullable fields (repo-wide `?? this.x`
      // pattern), so build the unplayable variant explicitly.
      final unplayableTrack = AudioTrack(
        id: 't2',
        contentKind: 'word',
        contentId: 'w1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        isHumanRecorded: true,
      );

      expect(
        word.resolvedAudioUrl([playableTrack]),
        'https://cdn.example.com/track.mp3',
      );
      expect(
        word.resolvedAudioUrl([unplayableTrack]),
        'https://cdn.example.com/legacy.mp3',
      );
      expect(word.resolvedAudioUrl(null), 'https://cdn.example.com/legacy.mp3');

      expect(word.playableTargetTrack([playableTrack])?.id, 't1');
      expect(word.playableTargetTrack(null), isNull);
    });
  });

  group('SentenceModelLocalizedFallback', () {
    test('resolvedMeaning prefers approved localization over legacy', () {
      final sentence = SentenceModel(
        id: 's1',
        sentenceOlChiki: 'ᱥᱟᱱ',
        sentenceLatin: 'san',
        meaning: 'hello there',
      );

      expect(sentence.resolvedMeaning(approvedHi), 'नमस्ते');
      expect(sentence.resolvedMeaning(needsReviewHi), 'hello there');
      expect(sentence.resolvedMeaning(null), 'hello there');
    });

    test('resolvedAudioUrl prefers playable track then legacy audioUrl', () {
      final sentence = SentenceModel(
        id: 's1',
        sentenceOlChiki: 'ᱥᱟᱱ',
        sentenceLatin: 'san',
        meaning: 'hello there',
        audioUrl: 'https://cdn.example.com/legacy.mp3',
      );

      final playableTrack = AudioTrack(
        id: 't1',
        contentKind: 'sentence',
        contentId: 's1',
        languageCode: 'sat',
        trackType: TrackType.targetNormal,
        audioUrl: 'https://cdn.example.com/track.mp3',
        reviewStatus: ReviewStatus.approved,
      );

      expect(
        sentence.resolvedAudioUrl([playableTrack]),
        'https://cdn.example.com/track.mp3',
      );
      expect(
        sentence.resolvedAudioUrl(null),
        'https://cdn.example.com/legacy.mp3',
      );
      expect(sentence.playableTargetTrack([playableTrack])?.id, 't1');
    });
  });
}
