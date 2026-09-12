import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/profile_avatar.dart';
import 'remote_avatar_cache.dart';
import 'remote_avatar_sources.dart';

/// Syncs the live avatar set from the `profile_avatars` Appwrite Storage
/// bucket into the local disk cache.
///
/// Resolution order (see `availableAvatarsProvider`): remote entries win
/// whenever this sync succeeds; any failure falls back to the bundled
/// catalog, and previously cached files keep working offline.
class RemoteAvatarDatasource {
  RemoteAvatarDatasource(this._storage, [RemoteAvatarCache? cache])
    : _cache = cache ?? createRemoteAvatarCache();

  final Storage _storage;
  final RemoteAvatarCache _cache;

  static const String manifestName = 'manifest.json';

  /// Lists, downloads changed files, prunes removed ones, and returns the
  /// catalog in bucket order. Throws [CacheFailure] / [NetworkFailure] /
  /// [ServerFailure] wrapped for the provider layer.
  Future<Either<Failure, List<ProfileAvatar>>> syncAvatars() async {
    try {
      final listing = await _storage.listFiles(bucketId: remoteAvatarBucketId);
      final entries = <ProfileAvatar>[];
      final seenIds = <String, String>{};

      for (final file in listing.files) {
        if (!file.name.toLowerCase().endsWith('.json')) continue;
        final id = remoteAvatarIdFromFilename(file.name);
        if (id.isEmpty || seenIds.containsKey(file.$id)) continue;
        seenIds[file.$id] = id;

        final localName = '${file.$id}.json';
        if (_cache.isSupported) {
          final knownUpdatedAt = await _manifestValue(file.$id);
          if (knownUpdatedAt != file.$updatedAt ||
              !await _cache.exists(localName)) {
            final bytes = await _storage.getFileDownload(
              bucketId: remoteAvatarBucketId,
              fileId: file.$id,
            );
            _assertValidLottie(bytes, file.name);
            await _cache.writeBytes(localName, bytes);
            await _writeManifestValue(file.$id, file.$updatedAt);
          }
        }
        // On web there is no disk cache: entries resolve while artwork
        // bytes stream on demand through [readArtworkBytes].
        entries.add(
          ProfileAvatar(
            id: id,
            assetFileName: file.name,
            label: remoteAvatarLabelFromId(id),
            remoteFileId: file.$id,
          ),
        );
      }

      await _pruneRemoved(seenIds.keys.toSet());
      return Right(List<ProfileAvatar>.unmodifiable(entries));
    } on AppwriteException catch (e) {
      AppLogger.warning('Remote avatar sync failed: $e');
      return Left(_classify(e));
    } catch (e) {
      AppLogger.warning('Remote avatar sync failed: $e');
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// Raw bytes for one synced avatar, used by the artwork provider. Serves
  /// the disk cache on native platforms; on web (no file system) streams
  /// the file on demand instead.
  Future<Either<Failure, List<int>>> readArtworkBytes(String fileId) async {
    try {
      return Right(await _cache.readBytes('$fileId.json'));
    } catch (_) {
      if (!_cache.isSupported) {
        try {
          final bytes = await _storage.getFileDownload(
            bucketId: remoteAvatarBucketId,
            fileId: fileId,
          );
          _assertValidLottie(bytes, fileId);
          return Right(bytes);
        } on AppwriteException catch (e) {
          return Left(_classify(e));
        } catch (e) {
          return Left(CacheFailure(message: e.toString()));
        }
      }
      return Left(CacheFailure(message: 'Avatar not cached: $fileId'));
    }
  }

  Future<void> _pruneRemoved(Set<String> liveIds) async {
    if (!_cache.isSupported) return;
    final manifest = await _readManifest();
    for (final cachedId in manifest.keys.toList()) {
      if (!liveIds.contains(cachedId)) {
        await _cache.delete('$cachedId.json');
        manifest.remove(cachedId);
      }
    }
    await _writeManifest(manifest);
  }

  Future<Map<String, String>> _readManifest() async {
    try {
      if (!await _cache.exists(manifestName)) return {};
      final raw = await _cache.readBytes(manifestName);
      final decoded = jsonDecode(String.fromCharCodes(raw));
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<String?> _manifestValue(String fileId) async {
    return (await _readManifest())[fileId];
  }

  Future<void> _writeManifestValue(String fileId, String updatedAt) async {
    final manifest = await _readManifest();
    manifest[fileId] = updatedAt;
    await _writeManifest(manifest);
  }

  Future<void> _writeManifest(Map<String, String> manifest) async {
    await _cache.writeBytes(manifestName, utf8.encode(jsonEncode(manifest)));
  }

  void _assertValidLottie(List<int> bytes, String name) {
    final decoded = jsonDecode(String.fromCharCodes(bytes));
    if (decoded is! Map<String, dynamic> ||
        decoded['v'] == null ||
        decoded['fr'] == null ||
        decoded['layers'] is! List ||
        (decoded['layers'] as List).isEmpty) {
      throw FormatException('Not a usable Lottie file: $name');
    }
  }

  Failure _classify(AppwriteException e) {
    final message = e.message ?? e.toString();
    if (e.code == 401 || e.code == 403) {
      return AuthFailure(message: message);
    }
    if (e.code == 404) {
      return CacheFailure(message: 'Avatar bucket not found: $message');
    }
    if (e.type == 'network_error' || message.contains('SocketException')) {
      return NetworkFailure(message: message);
    }
    return ServerFailure(message: message);
  }
}
