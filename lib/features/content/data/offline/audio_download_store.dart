import 'audio_download_store_io.dart'
    if (dart.library.html) 'audio_download_store_stub.dart'
    as impl;

/// Platform file store for downloaded audio (spec §13 offline downloads).
///
/// Implementations keep all downloaded audio under a single base directory
/// so that "storage used" and "delete everything" stay simple and safe.
/// The web build does not support persistent file downloads; callers must
/// check [AudioDownloadStore.isSupported] before offering download UI.
abstract class AudioDownloadStore {
  const AudioDownloadStore();

  /// False on platforms without a local file system (web).
  bool get isSupported;

  /// Writes [bytes] to [relativePath] (relative to the store base dir).
  Future<void> writeFileBytes(String relativePath, List<int> bytes);

  /// Reads a stored file as bytes. Throws when missing.
  Future<List<int>> readFileBytes(String relativePath);

  /// Writes UTF-8 text (used for the download manifest).
  Future<void> writeFileString(String relativePath, String contents);

  /// Reads UTF-8 text. Throws when missing.
  Future<String> readFileString(String relativePath);

  /// Absolute path for a stored file (used to build `file://` playback URLs).
  Future<String> absolutePath(String relativePath);

  Future<bool> fileExists(String relativePath);

  /// Size of a stored file in bytes; 0 when missing.
  Future<int> fileSize(String relativePath);

  Future<void> deleteFile(String relativePath);
}

/// Platform-resolved store instance (conditional import).
AudioDownloadStore createAudioDownloadStore() =>
    impl.createAudioDownloadStore();
