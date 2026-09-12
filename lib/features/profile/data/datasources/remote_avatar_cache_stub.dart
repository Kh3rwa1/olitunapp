import 'remote_avatar_cache.dart';

/// Web stub — avatar files stream from the public bucket URLs and are kept
/// in memory only. [isSupported] is false so sync logic skips disk I/O.
class StubRemoteAvatarCache extends RemoteAvatarCache {
  @override
  bool get isSupported => false;

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) {
    throw UnsupportedError('Avatar disk cache is not supported on the web.');
  }

  @override
  Future<List<int>> readBytes(String relativePath) {
    throw UnsupportedError('Avatar disk cache is not supported on the web.');
  }

  @override
  Future<bool> exists(String relativePath) async => false;

  @override
  Future<void> delete(String relativePath) async {}

  @override
  Future<Set<String>> cachedFileIds() async => const {};
}

RemoteAvatarCache createRemoteAvatarCache() => StubRemoteAvatarCache();
