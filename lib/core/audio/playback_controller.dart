import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;

import 'audio_service.dart';

/// Identity of one audio clip requested from the central controller.
///
/// [next] links clips into a sequence (bilingual mode: target audio, then
/// the teaching-language explanation). Chains are built head-first via
/// [PlaybackRequest.chain].
@immutable
class PlaybackRequest {
  /// Stable id of this clip — usually the audio URL itself.
  final String id;

  /// contentKind of the underlying item ('word', 'sentence', 'lesson'...).
  final String contentKind;

  /// contentId of the underlying item.
  final String contentId;

  /// Pedagogical role of this clip, e.g. 'targetNormal', 'explanation'.
  final String trackType;

  /// Language of this clip ('sat' for target audio, else a teaching code).
  final String languageCode;

  /// The clip that should follow this one, or null for the last clip.
  final PlaybackRequest? next;

  const PlaybackRequest({
    required this.id,
    required this.contentKind,
    required this.contentId,
    required this.trackType,
    required this.languageCode,
    this.next,
  });

  PlaybackRequest withNext(PlaybackRequest? next) => PlaybackRequest(
    id: id,
    contentKind: contentKind,
    contentId: contentId,
    trackType: trackType,
    languageCode: languageCode,
    next: next,
  );

  /// Builds a linked chain from [requests]; returns the head.
  /// Returns null for an empty list.
  static PlaybackRequest? chain(List<PlaybackRequest> requests) {
    if (requests.isEmpty) return null;
    for (var i = requests.length - 2; i >= 0; i--) {
      requests[i] = requests[i].withNext(requests[i + 1]);
    }
    return requests.first;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackRequest &&
          other.id == id &&
          other.contentKind == contentKind &&
          other.contentId == contentId &&
          other.trackType == trackType &&
          other.languageCode == languageCode;

  @override
  int get hashCode =>
      Object.hash(id, contentKind, contentId, trackType, languageCode);
}

/// Immutable snapshot of the central audio player state (spec §11).
@immutable
class PlaybackState {
  /// The clip currently loaded, if any.
  final PlaybackRequest? current;

  /// Head of the current request chain (bilingual: target + explanation).
  final PlaybackRequest? rootRequest;

  final bool isPlaying;
  final bool isLoading;

  /// Non-null when playback failed — surfaced to the learner, never thrown.
  final String? error;

  final Duration position;
  final Duration duration;
  final double speed;

  const PlaybackState({
    this.current,
    this.rootRequest,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
  });

  /// No clip loaded at all.
  bool get isIdle => current == null;

  /// Whether [contentKind]:[contentId] is the item currently loaded.
  bool isFor(String contentKind, String contentId) =>
      current?.contentKind == contentKind && current?.contentId == contentId;

  PlaybackState copyWith({
    Object? current = _sentinel,
    Object? rootRequest = _sentinel,
    bool? isPlaying,
    bool? isLoading,
    Object? error = _sentinel,
    Duration? position,
    Duration? duration,
    double? speed,
  }) {
    return PlaybackState(
      current: identical(current, _sentinel)
          ? this.current
          : current as PlaybackRequest?,
      rootRequest: identical(rootRequest, _sentinel)
          ? this.rootRequest
          : rootRequest as PlaybackRequest?,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      speed: speed ?? this.speed,
    );
  }

  static const _sentinel = Object();
}

/// Central audio playback controller (spec §11).
///
/// Exactly one instance exists in the app (see `playbackControllerProvider`
/// in `lib/features/content/presentation/providers/audio_playback_providers.dart`).
/// Every learner-facing audio surface routes through [play]/[pause]/[resume]/
/// [stop]/[replay]/[seek]/[setSpeed] so that:
///  - starting a new clip always stops the previous one (one global player),
///  - loading/error states are visible instead of silently swallowed,
///  - progress/duration/speed stay consistent across screens.
///
/// Bilingual sequencing via [PlaybackRequest.next]: when a clip finishes
/// naturally, the controller advances to the next clip after
/// [interClipPause]. An unplayable clip in the chain is skipped gracefully
/// (spec: no crash when a translation track is unavailable).
///
/// This class lives in core and depends only on [AudioService] so tests can
/// mock audio without any Appwrite/network wiring.
class PlaybackController {
  final AudioService _audio;

  /// Pause between target audio and its explanation in bilingual mode.
  final Duration interClipPause;

  /// Monotonic token: any request holding an older token is abandoned.
  int _requestSerial = 0;

  PlaybackState _state = const PlaybackState();
  final List<void Function(PlaybackState)> _listeners = [];

  final StreamController<PlaybackState> _stateStreamController =
      StreamController<PlaybackState>.broadcast();

  StreamSubscription<ProcessingState>? _processingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  /// Speed is applied to every new clip so it survives clip transitions.
  double _speedSetting = 1.0;

  PlaybackController({
    required AudioService audioService,
    this.interClipPause = const Duration(milliseconds: 700),
  }) : _audio = audioService {
    _processingSub = _audio.processingStateStream.listen(
      _onProcessingState,
      onError: (Object e) =>
          AppLogger.warning('PlaybackController processing stream error: $e'),
    );
    _positionSub = _audio.positionStream.listen(
      (pos) => _update(_state.copyWith(position: pos)),
      onError: (Object e) =>
          AppLogger.warning('PlaybackController position stream error: $e'),
    );
    _durationSub = _audio.durationStream.listen(
      (dur) => _update(dur == null ? _state : _state.copyWith(duration: dur)),
      onError: (Object e) =>
          AppLogger.warning('PlaybackController duration stream error: $e'),
    );
  }

  PlaybackState get state => _state;

  /// Broadcast stream of state snapshots for Riverpod/StreamBuilder wiring.
  /// New listeners only see future updates; read [state] for the current
  /// snapshot (the provider layer seeds the initial value from it).
  Stream<PlaybackState> get stateStream => _stateStreamController.stream;

  void addListener(void Function(PlaybackState) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(PlaybackState) listener) {
    _listeners.remove(listener);
  }

  void _update(PlaybackState next) {
    _state = next;
    if (!_stateStreamController.isClosed) {
      _stateStreamController.add(_state);
    }
    for (final listener in List.of(_listeners)) {
      try {
        listener(_state);
      } catch (e) {
        AppLogger.warning('PlaybackController listener error: $e');
      }
    }
  }

  // ── Public API ─────────────────────────────────────────────────────

  /// Plays [request] (and any linked follow-up clips). Stops anything
  /// already playing first. Never throws: an unplayable first clip yields
  /// an error state.
  Future<void> play(PlaybackRequest request) async {
    final serial = ++_requestSerial;
    _update(
      _state.copyWith(
        current: request,
        rootRequest: request,
        isPlaying: false,
        isLoading: true,
        error: null,
        position: Duration.zero,
        duration: Duration.zero,
      ),
    );

    // One global player: starting new audio stops the previous clip.
    await _audio.stop();
    if (serial != _requestSerial) return; // superseded by a newer request

    await _playClip(request, serial, root: request);
  }

  /// Convenience: play a single clip with no follow-up.
  Future<void> playSingle({
    required String id,
    required String contentKind,
    required String contentId,
    required String trackType,
    required String languageCode,
  }) {
    return play(
      PlaybackRequest(
        id: id,
        contentKind: contentKind,
        contentId: contentId,
        trackType: trackType,
        languageCode: languageCode,
      ),
    );
  }

  /// Pauses the loaded clip without unloading it.
  Future<void> pause() async {
    await _audio.pause();
    _update(_state.copyWith(isPlaying: false));
  }

  /// Resumes the loaded clip. Does nothing when nothing is loaded.
  Future<void> resume() async {
    if (_state.current == null) return;
    await _audio.resume();
    _update(_state.copyWith(isPlaying: true));
  }

  /// Toggles pause/resume for the loaded clip.
  Future<void> togglePlayPause() async {
    if (_state.current == null) return;
    if (_state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Stops playback and clears the loaded clip.
  Future<void> stop() async {
    _requestSerial++;
    await _audio.stop();
    _update(PlaybackState(speed: _speedSetting));
  }

  /// Replays the current chain from its head so the learner hears the
  /// same sequence again (bilingual mode repeats target + explanation).
  Future<void> replay() async {
    final head = _state.rootRequest ?? _state.current;
    if (head == null) return;
    await play(head);
  }

  /// Seeks within the loaded clip; clamps to [0, duration].
  Future<void> seek(Duration position) async {
    final clamped = position < Duration.zero
        ? Duration.zero
        : (_state.duration > Duration.zero && position > _state.duration)
        ? _state.duration
        : position;
    await _audio.seek(clamped);
    _update(_state.copyWith(position: clamped));
  }

  /// Sets playback speed (applies now and to subsequent clips).
  /// Clamped to [0.5, 2.0].
  Future<void> setSpeed(double speed) async {
    final clamped = speed < 0.5
        ? 0.5
        : speed > 2.0
        ? 2.0
        : speed;
    _speedSetting = clamped;
    await _audio.setSpeed(clamped);
    _update(_state.copyWith(speed: clamped));
  }

  /// Screen-reader-friendly label for the main play/pause control.
  String get playPauseSemanticsLabel {
    if (_state.isIdle) return 'Play audio';
    if (_state.isPlaying) return 'Pause audio';
    return 'Resume audio';
  }

  /// Screen-reader-friendly label for the replay control.
  String get replaySemanticsLabel => 'Replay audio from the beginning';

  /// Cancels stream subscriptions and drops listeners. The shared
  /// [AudioService] is NOT disposed here — it is app-scoped and owned by
  /// `audioServiceProvider`.
  void dispose() {
    _requestSerial++;
    _processingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _listeners.clear();
    _stateStreamController.close();
  }

  // ── Internals ──────────────────────────────────────────────────────

  Future<void> _playClip(
    PlaybackRequest clip,
    int serial, {
    required PlaybackRequest root,
  }) async {
    if (serial != _requestSerial) return;

    final url = clip.id;
    if (url.isEmpty) {
      // Missing track: skip (advance) without crashing (spec §11).
      await _advanceOrFinish(
        clip,
        serial,
        root: root,
        error: 'Audio unavailable',
      );
      return;
    }

    _update(
      _state.copyWith(
        current: clip,
        rootRequest: root,
        isPlaying: false,
        isLoading: true,
        error: null,
        position: Duration.zero,
        duration: Duration.zero,
      ),
    );

    final started = await _audio.tryPlayUrl(url);
    if (serial != _requestSerial) return; // superseded

    if (!started) {
      await _advanceOrFinish(
        clip,
        serial,
        root: root,
        error: 'Could not play audio',
      );
      return;
    }

    if (_speedSetting != 1.0) {
      await _audio.setSpeed(_speedSetting);
    }
    _update(_state.copyWith(isLoading: false, isPlaying: true, error: null));
    // Natural completion advances the chain from _onProcessingState.
  }

  void _onProcessingState(ProcessingState processingState) {
    if (processingState != ProcessingState.completed) return;
    final current = _state.current;
    if (current == null) {
      _update(_state.copyWith(isPlaying: false, position: Duration.zero));
      return;
    }
    final root = _state.rootRequest ?? current;
    _advanceOrFinish(current, _requestSerial, root: root);
  }

  /// After a clip finished (or failed): play [clip.next] after the
  /// inter-clip pause, or settle into a finished state when the chain is
  /// done. An unplayable follow-up clip is skipped gracefully.
  Future<void> _advanceOrFinish(
    PlaybackRequest clip,
    int serial, {
    required PlaybackRequest root,
    String? error,
  }) async {
    if (serial != _requestSerial) return;
    _update(_state.copyWith(isPlaying: false, isLoading: false, error: error));

    final next = clip.next;
    if (next == null) return; // chain complete

    // Short breath between the Santali clip and its explanation so the
    // two do not run together (bilingual = target, pause, meaning).
    if (interClipPause > Duration.zero) {
      await Future<void>.delayed(interClipPause);
      if (serial != _requestSerial) return;
    }
    await _playClip(next, serial, root: root);
  }
}
