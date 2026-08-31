import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/audio/audio_service.dart';
import '../../../../core/audio/playback_controller.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/providers/language_settings_providers.dart';
import '../../data/datasources/audio_track_remote_datasource.dart';
import '../../data/datasources/localized_content_remote_datasource.dart';
import '../../data/repositories/audio_track_repository_impl.dart';
import '../../data/repositories/localized_content_repository_impl.dart';
import '../../domain/entities/audio_track_entity.dart';
import '../../domain/entities/localized_content_entity.dart';
import '../../domain/repositories/audio_track_repository.dart';
import '../../domain/repositories/localized_content_repository.dart';

/// Phase 3 wiring: datasources → repositories → central
/// [PlaybackController] → playback state (spec §11).
///
/// Every learner-facing audio surface routes through
/// [playbackControllerProvider] so the one-global-player rule is
/// enforced app-wide: starting a new clip always interrupts the
/// previous one, with consistent metadata for analytics.

final audioTrackRemoteDataSourceProvider = Provider<AudioTrackRemoteDataSource>(
  (ref) {
    final client = ref.watch(appwriteAuthServiceProvider).client;
    return AudioTrackRemoteDataSourceImpl(Databases(client));
  },
);

final audioTrackRepositoryProvider = Provider<AudioTrackRepository>((ref) {
  final remote = ref.watch(audioTrackRemoteDataSourceProvider);
  final network = ref.watch(networkInfoProvider);
  return AudioTrackRepositoryImpl(
    remoteDataSource: remote,
    networkInfo: network,
  );
});

final localizedContentRemoteDataSourceProvider =
    Provider<LocalizedContentRemoteDataSource>((ref) {
      final client = ref.watch(appwriteAuthServiceProvider).client;
      return LocalizedContentRemoteDataSourceImpl(Databases(client));
    });

final localizedContentRepositoryProvider = Provider<LocalizedContentRepository>(
  (ref) {
    final remote = ref.watch(localizedContentRemoteDataSourceProvider);
    final network = ref.watch(networkInfoProvider);
    return LocalizedContentRepositoryImpl(
      remoteDataSource: remote,
      networkInfo: network,
    );
  },
);

/// The single central playback controller for the whole app.
///
/// Tests override this provider with a controller built on a mocked
/// [AudioService] — the controller itself never touches Appwrite.
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final controller = PlaybackController(
    audioService: ref.watch(audioServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

/// Broadcast playback state for reactive listeners.
///
/// The stream emits the current [PlaybackState] on every change. It is
/// seeded with `controller.state` when first watched because the
/// controller is constructed before the first stream event; consumers
/// that need an initial value immediately should read
/// `ref.watch(playbackControllerProvider).state` as the fallback (see
/// [AudioControlsBar] which instead uses the manual listener pattern to
/// avoid rebuilding on every position tick).
final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final controller = ref.watch(playbackControllerProvider);
  return controller.stateStream;
});

/// Input for [audioBundleProvider]: identity plus the legacy inline
/// fields that act as offline-first fallbacks.
@immutable
class AudioBundleRequest {
  final String contentKind;
  final String contentId;

  /// Legacy inline `audioUrl` from the content document (pre-Phase 2).
  final String? legacyAudioUrl;

  /// Legacy inline English `meaning` from the content document.
  final String legacyMeaning;

  const AudioBundleRequest({
    required this.contentKind,
    required this.contentId,
    this.legacyAudioUrl,
    this.legacyMeaning = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioBundleRequest &&
          other.contentKind == contentKind &&
          other.contentId == contentId &&
          other.legacyAudioUrl == legacyAudioUrl &&
          other.legacyMeaning == legacyMeaning;

  @override
  int get hashCode =>
      Object.hash(contentKind, contentId, legacyAudioUrl, legacyMeaning);
}

/// Resolved audio + teaching-language metadata for one content item
/// (spec §7/§8): Phase 2 `audio_tracks` / `localized_contents` data
/// combined with the legacy inline fields as final fallback.
///
/// The bundle never throws and never holds failure state — anything
/// that could not be fetched simply resolves to "unavailable", which
/// the UI surfaces instead of blocking the learner.
@immutable
class AudioBundle {
  final String contentKind;
  final String contentId;

  /// Legacy inline audioUrl from the content document.
  final String? legacyAudioUrl;

  /// Legacy English meaning from the content document.
  final String legacyMeaning;

  /// Teaching language this bundle was resolved for.
  final String teachingLanguage;

  /// Approved localization for [teachingLanguage], or null when none
  /// is approved yet (legacy fields are then used).
  final LocalizedContent? localization;

  /// Every track row for this item (playable or not), so the UI can
  /// distinguish "no audio yet" from "audio pending review".
  final List<AudioTrack> tracks;

  const AudioBundle({
    required this.contentKind,
    required this.contentId,
    this.legacyAudioUrl,
    this.legacyMeaning = '',
    required this.teachingLanguage,
    this.localization,
    this.tracks = const [],
  });

  AudioTrack? _firstPlayable(TrackType type, {String? languageCode}) {
    for (final track in tracks) {
      if (track.trackType == type &&
          track.isPlayable &&
          (languageCode == null || track.languageCode == languageCode)) {
        return track;
      }
    }
    return null;
  }

  /// Playable native Santali clip at normal speed, if any.
  AudioTrack? get normalTrack => _firstPlayable(TrackType.targetNormal);

  /// Playable slowed-down Santali clip, if any.
  AudioTrack? get slowTrack => _firstPlayable(TrackType.targetSlow);

  /// Playable teaching-language explanation clip, if any.
  AudioTrack? get explanationTrack =>
      _firstPlayable(TrackType.explanation, languageCode: teachingLanguage);

  /// Playable teaching-language translation clip, if any.
  AudioTrack? get translationTrack =>
      _firstPlayable(TrackType.translation, languageCode: teachingLanguage);

  static String? _nonEmpty(String? url) =>
      (url == null || url.isEmpty) ? null : url;

  /// Best Santali audio URL: playable targetNormal track first, then
  /// the legacy inline audioUrl (which Phase 2 backfill mirrors into
  /// audio_tracks, so both usually agree).
  String? get santaliAudioUrl =>
      _nonEmpty(normalTrack?.audioUrl) ?? _nonEmpty(legacyAudioUrl);

  /// Slowed-down Santali audio URL, if playable. Never falls back to
  /// the normal clip — slow audio is an explicit pedagogical mode.
  String? get slowAudioUrl => _nonEmpty(slowTrack?.audioUrl);

  /// Teaching-language explanation audio URL, if playable.
  String? get explanationAudioUrl => _nonEmpty(explanationTrack?.audioUrl);

  /// Teaching-language translation audio URL, if playable.
  String? get translationAudioUrl => _nonEmpty(translationTrack?.audioUrl);

  /// True when a Santali track exists but is not playable yet (e.g.
  /// synthetic upload still pending review) — the UI shows an
  /// "audio unavailable" state instead of a dead button.
  bool get hasPendingSantaliAudio =>
      santaliAudioUrl == null &&
      tracks.any(
        (t) => t.trackType == TrackType.targetNormal && t.isTargetAudio,
      );

  /// Best teaching-language meaning: approved localization first,
  /// then the legacy English meaning.
  String get meaning {
    if (localization != null && localization!.isApproved) {
      final localized = localization!.meaningOrEmpty;
      if (localized != null) return localized;
    }
    return legacyMeaning;
  }

  /// Builds the playback chain for the main "listen" tap under
  /// [mode]:
  /// - targetOnly → just the Santali clip
  /// - bilingual → Santali clip, then teaching-language explanation
  ///   (or translation when no explanation audio exists)
  /// - translationOnDemand → just the Santali clip; the Meaning button
  ///   plays the teaching audio via [meaningPlaybackRequest]
  ///
  /// Returns null when there is nothing playable — the caller shows
  /// the unavailable state instead of playing silence. The Santali
  /// clip anchors the chain: without it the main listen button stays
  /// unavailable even when teaching-language audio exists (the
  /// teaching clip alone is never a substitute for the target clip).
  PlaybackRequest? playbackChain(LessonAudioMode mode) {
    final target = santaliAudioUrl;
    if (target == null) return null;
    final requests = <PlaybackRequest>[
      PlaybackRequest(
        id: target,
        contentKind: contentKind,
        contentId: contentId,
        trackType: TrackType.targetNormal.name,
        languageCode: 'sat',
      ),
    ];
    if (mode == LessonAudioMode.bilingual) {
      final request = _teachingPlaybackRequest(preferExplanation: true);
      if (request != null) requests.add(request);
    }
    return PlaybackRequest.chain(requests);
  }

  /// The on-demand teaching-language clip for the Meaning button
  /// (translation preferred, explanation as fallback).
  PlaybackRequest? meaningPlaybackRequest() =>
      _teachingPlaybackRequest(preferExplanation: false);

  PlaybackRequest? _teachingPlaybackRequest({required bool preferExplanation}) {
    final explanation = explanationTrack;
    final translation = translationTrack;
    final AudioTrack? track;
    if (preferExplanation) {
      track = explanation ?? translation;
    } else {
      track = translation ?? explanation;
    }
    if (track == null) return null;
    return PlaybackRequest(
      id: track.audioUrl!,
      contentKind: contentKind,
      contentId: contentId,
      trackType: track.trackType.name,
      languageCode: track.languageCode,
    );
  }
}

/// Resolves the [AudioBundle] for one item. Failure-swallowing by
/// design: unreachable audio/localization simply resolves to the
/// legacy inline fallbacks so the learner is never blocked.
final audioBundleProvider = FutureProvider.autoDispose
    .family<AudioBundle, AudioBundleRequest>((ref, request) async {
      final teachingLanguage = ref.watch(effectiveTeachingLanguageProvider);

      final trackRepository = ref.watch(audioTrackRepositoryProvider);
      final localizationRepository = ref.watch(
        localizedContentRepositoryProvider,
      );

      final tracksResult = await trackRepository.getAllTracks(
        contentKind: request.contentKind,
        contentId: request.contentId,
      );
      final tracks = tracksResult.fold(
        (failure) => const <AudioTrack>[],
        (tracks) => tracks,
      );

      final localizationResult = await localizationRepository.getLocalization(
        contentKind: request.contentKind,
        contentId: request.contentId,
        languageCode: teachingLanguage,
      );
      final localization = localizationResult.fold(
        (failure) => null,
        (localization) => localization,
      );

      return AudioBundle(
        contentKind: request.contentKind,
        contentId: request.contentId,
        legacyAudioUrl: request.legacyAudioUrl,
        legacyMeaning: request.legacyMeaning,
        teachingLanguage: teachingLanguage,
        localization: localization,
        tracks: tracks,
      );
    });
