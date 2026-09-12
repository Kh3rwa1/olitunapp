import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'remote_avatar_cache.dart';

/// Native (IO) implementation of [RemoteAvatarCache].
class IoRemoteAvatarCache extends RemoteAvatarCache {
  static const String baseDirName = 'olitun_remote_avatars';
  static const String manifestName = 'manifest.json';

  Future<Directory> _baseDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$baseDirName');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  bool get isSupported => true;

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<List<int>> readBytes(String relativePath) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    return file.readAsBytes();
  }

  @override
  Future<bool> exists(String relativePath) async {
    return File('${(await _baseDir()).path}/$relativePath').existsSync();
  }

  @override
  Future<void> delete(String relativePath) async {
    final file = File('${(await _baseDir()).path}/$relativePath');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<Set<String>> cachedFileIds() async {
    final dir = await _baseDir();
    final ids = <String>{};
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        final name = entity.uri.pathSegments.last;
        if (name != manifestName) {
          ids.add(name.substring(0, name.length - '.json'.length));
        }
      }
    }
    return ids;
  }
}

RemoteAvatarCache createRemoteAvatarCache() => IoRemoteAvatarCache();
