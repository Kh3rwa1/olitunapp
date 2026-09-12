import 'remote_avatar_cache_io.dart'
    if (dart.library.html) 'remote_avatar_cache_stub.dart'
    as impl;

/// Platform file store for remote avatar artwork.
///
/// Synced Lottie files live under `<Application Documents>/olitun_remote_avatars/`
/// keyed by Appwrite file id, plus a `manifest.json` mapping file ids to the
/// remote `$updatedAt` used for change detection. The web build has no local
/// file system: the stub reports unsupported and artwork streams from the
/// public bucket URLs instead.
abstract class RemoteAvatarCache {
  const RemoteAvatarCache();

  /// False on platforms without a local file system (web).
  bool get isSupported;

  Future<void> writeBytes(String relativePath, List<int> bytes);

  Future<List<int>> readBytes(String relativePath);

  Future<bool> exists(String relativePath);

  Future<void> delete(String relativePath);

  /// File ids currently present in the cache directory.
  Future<Set<String>> cachedFileIds();
}

RemoteAvatarCache createRemoteAvatarCache() => impl.createRemoteAvatarCache();
