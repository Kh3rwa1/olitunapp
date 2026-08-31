import 'package:itun/features/content/domain/entities/audio_track_entity.dart';
import 'package:itun/features/content/domain/entities/localized_content_entity.dart';

import 'sentence_model.dart';
import 'word_model.dart';

/// Phase 2 backward-compatibility fallbacks (spec §7/§8).
///
/// Legacy content documents keep their English `meaning` and inline
/// `audioUrl` attributes. New localized overlays live in
/// `localized_contents` and dedicated audio lives in `audio_tracks`.
/// These helpers resolve the best available value without ever
/// crashing on missing localization/audio — the legacy field is the
/// final fallback.
///
/// Fallback chain for text: approved localization for the selected
/// teaching language → legacy English meaning.
/// Fallback chain for audio: playable targetNormal track → legacy
/// inline audioUrl.
extension WordModelLocalizedFallback on WordModel {
  /// Best meaning for the learner's teaching language, falling back
  /// to the legacy English meaning.
  String resolvedMeaning(LocalizedContent? localization) {
    final localized = localization?.meaningOrEmpty;
    if (localized != null && localization!.isApproved) return localized;
    return meaning;
  }

  /// Best hint for the learner's teaching language, if any.
  String? resolvedHint(LocalizedContent? localization) {
    if (localization == null || !localization.isApproved) return null;
    final hint = localization.hint;
    return (hint == null || hint.isEmpty) ? null : hint;
  }

  /// Best explanation for the learner's teaching language, if any.
  String? resolvedExplanation(LocalizedContent? localization) {
    if (localization == null || !localization.isApproved) return null;
    final explanation = localization.explanation;
    return (explanation == null || explanation.isEmpty) ? null : explanation;
  }

  /// Playable Santali audio URL: a playable targetNormal track wins,
  /// otherwise the legacy inline audioUrl (which the Phase 2 backfill
  /// mirrors into audio_tracks, so both usually agree).
  String? resolvedAudioUrl(List<AudioTrack>? tracks) {
    if (tracks != null) {
      for (final track in tracks) {
        if (track.trackType == TrackType.targetNormal &&
            track.isTargetAudio &&
            track.isPlayable) {
          return track.audioUrl;
        }
      }
    }
    return audioUrl;
  }

  /// The legacy targetNormal track equivalent of this word, if a
  /// playable one exists (used to show "audio unavailable" states
  /// when null while a track is expected).
  AudioTrack? playableTargetTrack(List<AudioTrack>? tracks) {
    if (tracks == null) return null;
    for (final track in tracks) {
      if (track.trackType == TrackType.targetNormal && track.isPlayable) {
        return track;
      }
    }
    return null;
  }
}

/// Same fallback rules for sentences.
extension SentenceModelLocalizedFallback on SentenceModel {
  /// Best meaning for the learner's teaching language, falling back
  /// to the legacy English meaning.
  String resolvedMeaning(LocalizedContent? localization) {
    final localized = localization?.meaningOrEmpty;
    if (localized != null && localization!.isApproved) return localized;
    return meaning;
  }

  /// Best hint for the learner's teaching language, if any.
  String? resolvedHint(LocalizedContent? localization) {
    if (localization == null || !localization.isApproved) return null;
    final hint = localization.hint;
    return (hint == null || hint.isEmpty) ? null : hint;
  }

  /// Best explanation for the learner's teaching language, if any.
  String? resolvedExplanation(LocalizedContent? localization) {
    if (localization == null || !localization.isApproved) return null;
    final explanation = localization.explanation;
    return (explanation == null || explanation.isEmpty) ? null : explanation;
  }

  /// Playable Santali audio URL: a playable targetNormal track wins,
  /// otherwise the legacy inline audioUrl.
  String? resolvedAudioUrl(List<AudioTrack>? tracks) {
    if (tracks != null) {
      for (final track in tracks) {
        if (track.trackType == TrackType.targetNormal &&
            track.isTargetAudio &&
            track.isPlayable) {
          return track.audioUrl;
        }
      }
    }
    return audioUrl;
  }

  /// The playable targetNormal track for this sentence, if any.
  AudioTrack? playableTargetTrack(List<AudioTrack>? tracks) {
    if (tracks == null) return null;
    for (final track in tracks) {
      if (track.trackType == TrackType.targetNormal && track.isPlayable) {
        return track;
      }
    }
    return null;
  }
}
