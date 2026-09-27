import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:path_provider/path_provider.dart';

CacheManager? _olitunAudioCacheInstance;

/// Shared audio cache manager for remote letter, word, sentence, and lesson audio.
///
/// Keeps up to 2000 audio files for 90 days on native disk so that:
/// - Audio clips are only fetched from the remote server ONCE.
/// - Once cached, playback starts instantly from the local file system (0ms network latency).
/// - Audio plays reliably even on slow, high-jitter mobile connections or offline.
/// - The global player reads a local `file://` URI, avoiding streaming timeouts and socket drops.
CacheManager get olitunAudioCacheManager {
  return _olitunAudioCacheInstance ??= CacheManager(
    Config(
      'olitunAudio',
      stalePeriod: const Duration(days: 90),
      maxNrOfCacheObjects: 2000,
    ),
  );
}

final audioCacheManagerProvider = Provider<AudioCacheManager>((ref) {
  return DefaultAudioCacheManager();
});

abstract class AudioCacheManager {
  /// Resolves [url] to a local `file:` URI if cached.
  ///
  /// If not yet cached, returns [url] as a standard [Uri] for immediate playback
  /// and automatically caches the file in the background so subsequent plays are instant.
  Future<Uri> getPlayableUri(String url);

  /// Pre-caches a collection of audio URLs in the background.
  ///
  /// Safe to call on screen load (e.g. alphabet screen, vocabulary screen,
  /// quiz screen) to ensure all clips are on disk before the learner taps.
  Future<void> precache(Iterable<String> urls);

  /// Checks if a remote URL is already cached locally on disk.
  Future<bool> isCached(String url);

  /// Clears all cached audio files from disk.
  Future<void> clearCache();
}

class DefaultAudioCacheManager implements AudioCacheManager {
  final BaseCacheManager? _customCacheManager;
  bool? _isAvailable;

  DefaultAudioCacheManager([BaseCacheManager? cacheManager])
    : _customCacheManager = cacheManager;

  Future<bool> _checkAvailable() async {
    if (_isAvailable != null) return _isAvailable!;
    if (kIsWeb) {
      _isAvailable = false;
      return false;
    }
    if (_customCacheManager != null) {
      _isAvailable = true;
      return true;
    }
    try {
      await getTemporaryDirectory();
      _isAvailable = true;
    } catch (_) {
      // In headless unit tests without native platform channels, degrade gracefully
      _isAvailable = false;
    }
    return _isAvailable!;
  }

  BaseCacheManager get _cacheManager =>
      _customCacheManager ?? olitunAudioCacheManager;

  @override
  Future<Uri> getPlayableUri(String url) async {
    if (url.trim().isEmpty) return Uri.parse(url);

    // Already local or asset
    if (url.startsWith('file:') ||
        url.startsWith('/') ||
        url.startsWith('asset:') ||
        url.startsWith('assets/')) {
      return Uri.parse(url);
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return Uri.parse(url);
    }

    if (!await _checkAvailable()) {
      return Uri.parse(url);
    }

    // 1. Check local cache first (instant local file lookup)
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      if (fileInfo != null && await fileInfo.file.exists()) {
        AppLogger.debug('AudioCacheManager: cache HIT for $url');
        return Uri.file(fileInfo.file.path);
      }
    } catch (e) {
      AppLogger.debug('AudioCacheManager: cache check error: $e');
    }

    // 2. Cache miss: trigger background caching so subsequent plays are instant
    unawaited(_cacheSingle(url));

    // 3. Play immediately via remote URI without blocking on initial download
    return Uri.parse(url);
  }

  Future<void> _cacheSingle(String url) async {
    try {
      await _cacheManager.downloadFile(url);
      AppLogger.debug('AudioCacheManager: cached $url in background');
    } catch (e) {
      AppLogger.debug(
        'AudioCacheManager: background caching failed for $url: $e',
      );
    }
  }

  @override
  Future<void> precache(Iterable<String> urls) async {
    if (!await _checkAvailable()) return;

    final distinctUrls = urls
        .where(
          (u) =>
              u.trim().isNotEmpty &&
              (u.startsWith('http://') || u.startsWith('https://')),
        )
        .toSet()
        .toList();

    if (distinctUrls.isEmpty) return;

    // Concurrency limit: process in batches of 3
    const batchSize = 3;
    for (var i = 0; i < distinctUrls.length; i += batchSize) {
      final batch = distinctUrls.skip(i).take(batchSize);
      await Future.wait(
        batch.map((url) async {
          try {
            final fileInfo = await _cacheManager.getFileFromCache(url);
            if (fileInfo != null && await fileInfo.file.exists()) return;
            await _cacheManager.downloadFile(url);
          } catch (e) {
            AppLogger.debug(
              'AudioCacheManager: background precache error for $url: $e',
            );
          }
        }),
      );
    }
  }

  @override
  Future<bool> isCached(String url) async {
    if (!await _checkAvailable()) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return true;
    try {
      final fileInfo = await _cacheManager.getFileFromCache(url);
      return fileInfo != null && await fileInfo.file.exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearCache() async {
    if (!await _checkAvailable()) return;
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      AppLogger.warning('AudioCacheManager: clearCache failed: $e');
    }
  }
}
