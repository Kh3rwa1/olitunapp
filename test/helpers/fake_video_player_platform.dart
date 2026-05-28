import 'dart:async';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A deterministic [VideoPlayerPlatform] fake for widget tests.
///
/// Tracks create/dispose counts, per-texture playing/volume/looping state,
/// and can simulate initialization failure via [shouldFail].
///
/// Shared across all video-related widget tests to avoid duplication.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  int nextTextureId = 1;
  int createCount = 0;
  int disposeCount = 0;
  bool shouldFail = false;
  final Map<int, DataSource> dataSources = {};
  final Map<int, bool> playing = {};
  final Map<int, double> volumes = {};
  final Map<int, bool> looping = {};

  @override
  Future<void> init() async {}

  @override
  Future<int> create(DataSource dataSource) async {
    if (shouldFail) {
      throw Exception('Initialization failed');
    }
    createCount++;
    final id = nextTextureId++;
    dataSources[id] = dataSource;
    playing[id] = false;
    volumes[id] = 1.0;
    looping[id] = false;
    return id;
  }

  @override
  Future<void> dispose(int textureId) async {
    disposeCount++;
    dataSources.remove(textureId);
    playing.remove(textureId);
    volumes.remove(textureId);
    looping.remove(textureId);
  }

  @override
  Future<void> setVolume(int textureId, double volume) async {
    volumes[textureId] = volume;
  }

  @override
  Future<void> setLooping(int textureId, bool value) async {
    looping[textureId] = value;
  }

  @override
  Future<void> play(int textureId) async {
    playing[textureId] = true;
  }

  @override
  Future<void> pause(int textureId) async {
    playing[textureId] = false;
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}
  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<Duration> getPosition(int textureId) async {
    return Duration.zero;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    if (shouldFail) {
      return Stream.error(Exception('Initialization failed'));
    }
    return Stream.value(
      VideoEvent(
        eventType: VideoEventType.initialized,
        duration: const Duration(seconds: 45),
        size: const Size(1920, 1080),
      ),
    );
  }

  @override
  Widget buildView(int textureId) {
    return Container(color: Colors.black, key: ValueKey<int>(textureId));
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) {
    return buildView(options.playerId);
  }

  /// Reset mutable state between test runs.
  void reset() {
    nextTextureId = 1;
    createCount = 0;
    disposeCount = 0;
    shouldFail = false;
    dataSources.clear();
    playing.clear();
    volumes.clear();
    looping.clear();
  }
}
