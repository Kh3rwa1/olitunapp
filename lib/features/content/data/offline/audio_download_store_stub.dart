import 'audio_download_store.dart';

/// Web stub — persistent per-file downloads are not supported on the web
/// platform (audio streams on demand and browser storage management is a
/// browser concern). [isSupported] is false so feature UI can hide the
/// download affordances instead of failing at runtime.
class StubAudioDownloadStore extends AudioDownloadStore {
  @override
  bool get isSupported => false;

  @override
  Future<void> writeFileBytes(String relativePath, List<int> bytes) async {
    throw UnsupportedError('Audio downloads are not supported on the web.');
  }

  @override
  Future<List<int>> readFileBytes(String relativePath) async {
    throw UnsupportedError('Audio downloads are not supported on the web.');
  }

  @override
  Future<void> writeFileString(String relativePath, String contents) async {
    throw UnsupportedError('Audio downloads are not supported on the web.');
  }

  @override
  Future<String> readFileString(String relativePath) async {
    throw UnsupportedError('Audio downloads are not supported on the web.');
  }

  @override
  Future<String> absolutePath(String relativePath) async {
    throw UnsupportedError('Audio downloads are not supported on the web.');
  }

  @override
  Future<bool> fileExists(String relativePath) async => false;

  @override
  Future<int> fileSize(String relativePath) async => 0;

  @override
  Future<void> deleteFile(String relativePath) async {}
}

AudioDownloadStore createAudioDownloadStore() => StubAudioDownloadStore();
