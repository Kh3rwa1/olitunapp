import 'package:equatable/equatable.dart';

import 'audio_track_entity.dart';

/// One segment of a story: a chunk of Santali text, its Romanization,
/// per-language translations, and the audio tracks that narrate it.
///
/// Segments are what the player steps through — highlighting and
/// bilingual sequencing in later phases operate per segment.
class StorySegment extends Equatable {
  final String id;

  /// The story (content) document this segment belongs to.
  final String storyId;

  /// 1-based ordering within the story.
  final int order;

  /// Santali text in Ol Chiki script.
  final String textOlChiki;

  /// Romanized (Latin) rendering of [textOlChiki].
  final String? textLatin;

  /// Teaching-language translations keyed by language code
  /// (en, hi, bn, or). Translations are reviewed content and default
  /// to English at read time (handled by the repository layer).
  final Map<String, String> translations;

  /// Audio tracks attached to this segment (Santali narration and
  /// teaching-language storyTranslation tracks).
  final List<AudioTrack> audioTracks;

  /// Optional karaoke-style highlighting window, milliseconds from
  /// segment audio start.
  final int? startMs;
  final int? endMs;

  /// Optional illustration for the segment.
  final String? imageUrl;

  /// Word/sentence content IDs referenced by this segment, used to
  /// link vocabulary back to the dictionary.
  final List<String> vocabularyRefs;

  const StorySegment({
    required this.id,
    required this.storyId,
    required this.order,
    required this.textOlChiki,
    this.textLatin,
    this.translations = const {},
    this.audioTracks = const [],
    this.startMs,
    this.endMs,
    this.imageUrl,
    this.vocabularyRefs = const [],
  });

  /// Best translation for [languageCode], falling back to English and
  /// then to the Romanized Santali text — never null when the segment
  /// itself has text.
  String translationFor(String languageCode) {
    return translations[languageCode] ??
        translations['en'] ??
        textLatin ??
        textOlChiki;
  }

  /// The segment's Santali narration track, if any.
  AudioTrack? get narrationTrack {
    for (final track in audioTracks) {
      if (track.trackType == TrackType.storyNarration &&
          track.isPlayable &&
          track.languageCode == 'sat') {
        return track;
      }
    }
    return null;
  }

  /// The segment's teaching-language translation track, if any.
  AudioTrack? translationTrackFor(String languageCode) {
    for (final track in audioTracks) {
      if (track.trackType == TrackType.storyTranslation &&
          track.isPlayable &&
          track.languageCode == languageCode) {
        return track;
      }
    }
    return null;
  }

  StorySegment copyWith({
    String? id,
    String? storyId,
    int? order,
    String? textOlChiki,
    String? textLatin,
    Map<String, String>? translations,
    List<AudioTrack>? audioTracks,
    int? startMs,
    int? endMs,
    String? imageUrl,
    List<String>? vocabularyRefs,
  }) {
    return StorySegment(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      order: order ?? this.order,
      textOlChiki: textOlChiki ?? this.textOlChiki,
      textLatin: textLatin ?? this.textLatin,
      translations: translations ?? this.translations,
      audioTracks: audioTracks ?? this.audioTracks,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      imageUrl: imageUrl ?? this.imageUrl,
      vocabularyRefs: vocabularyRefs ?? this.vocabularyRefs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    storyId,
    order,
    textOlChiki,
    textLatin,
    translations,
    audioTracks,
    startMs,
    endMs,
    imageUrl,
    vocabularyRefs,
  ];
}
