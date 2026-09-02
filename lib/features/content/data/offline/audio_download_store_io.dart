import 'dart:io';

import 'package:itun/core/logging/app_logger.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_download_store.dart';

/// Native (IO) implementation of [AudioDownloadStore].
///
/// All downloaded audio lives under
/// `<Application Documents>/olitun_audio_downloads/` so the folder can be
/// measured or wiped in one place (spec §13: storage usage + cache
/// management), and it survives app restarts without being backed up to
/// cloud storage bloat (`doNotBackup` semantics are platform-specific and
/// out of scope; documents dir is the app's private sandbox).
class IoAudioDownloadStore extends AudioDownloadStore {
  static const String baseDirName = 'olitun_audio_downloads';

  @override
  bool get isSupported => true;

  Future<Directory> _baseDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$baseDirName');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Future<void> writeFileBytes(String relativePath, List<int> bytes) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<List<int>> readFileBytes(String relativePath) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    return file.readAsBytes();
  }

  @override
  Future<void> writeFileString(String relativePath, String contents) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsString(contents, flush: true);
  }

  @override
  Future<String> readFileString(String relativePath) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    return file.readAsString();
  }

  @override
  Future<String> absolutePath(String relativePath) async {
    return '${(await _baseDir()).path}/$relativePath';
  }

  @override
  Future<bool> fileExists(String relativePath) async {
    return File('${(await _baseDir()).path}/$relativePath').existsSync();
  }

  @override
  Future<int> fileSize(String relativePath) async {
    try {
      final file = File('${(await _baseDir()).path}/$relativePath');
      if (!file.existsSync()) return 0;
      return await file.length();
    } catch (e) {
      AppLogger.warning(
        'IoAudioDownloadStore: fileSize($relativePath) failed: $e',
        name: 'IoAudioDownloadStore',
      );
      return 0;
    }
  }

  @override
  Future<void> deleteFile(String relativePath) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

AudioDownloadStore createAudioDownloadStore() => IoAudioDownloadStore();
