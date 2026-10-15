import 'dart:async';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api/edge_json_client.dart';
import '../../../../core/config/cloudflare_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/profile_avatar.dart';
import 'remote_avatar_cache.dart';
import 'remote_avatar_sources.dart';

/// Syncs the live avatar set (R2 objects under `avatars/`, listed by the
/// Worker's `GET /api/v1/avatars` and served by `/api/v1/assets/*`) into the
/// local disk cache.
///
/// Resolution order (see `availableAvatarsProvider`): the bundled catalog is
/// always shown instantly; synced entries merge in the background (remote
/// wins on id conflicts) whenever this sync succeeds. Any failure keeps the
/// bundled set, and previously cached files keep working offline.
class RemoteAvatarDatasource {
  RemoteAvatarDatasource(this._client, [RemoteAvatarCache? cache])
    : _cache = cache ?? createRemoteAvatarCache();

  static const Duration _timeout = Duration(seconds: 8);

  final http.Client _client;
  final RemoteAvatarCache _cache;

  /// Download URL per remote file id, from the latest listing.
  final Map<String, Uri> _urls = {};

  /// In-memory memo so repeat views within a session never re-download.
  /// Matters most on web, where there is no disk cache and artwork otherwise
  /// streams from the Worker on every picker open.
  final Map<String, List<int>> _memoryBytes = {};

  static const String manifestName = 'manifest.json';

  /// Lists, downloads changed files, prunes removed ones, and returns the
  /// catalog in bucket order. Throws [CacheFailure] / [NetworkFailure] /
  /// [ServerFailure] wrapped for the provider layer.
  Future<Either<Failure, List<ProfileAvatar>>> syncAvatars() async {
    try {
      final listing = await EdgeJsonClient.getList(
        _client,
        Uri.parse(CloudflareConfig.avatarsEndpoint),
        'avatars',
      );
      final entries = <ProfileAvatar>[];
      final seenIds = <String, String>{};

      for (final file in listing) {
        final name = file['name']?.toString() ?? '';
        final fileId = file['id']?.toString() ?? '';
        final path = file['path']?.toString() ?? '';
        if (!name.toLowerCase().endsWith('.json')) continue;
        final id = remoteAvatarIdFromFilename(name);
        if (id.isEmpty || fileId.isEmpty || path.isEmpty) continue;
        if (seenIds.containsKey(fileId)) continue;
        seenIds[fileId] = id;
        final url = Uri.parse(CloudflareConfig.baseUrl).resolve(path);
        _urls[fileId] = url;
        final version = file['version']?.toString() ?? '';

        final localName = '$fileId.json';
        if (_cache.isSupported) {
          final knownVersion = await _manifestValue(fileId);
          if (knownVersion != version || !await _cache.exists(localName)) {
            final bytes = await _download(url);
            _assertValidLottie(bytes, name);
            await _cache.writeBytes(localName, bytes);
            _memoryBytes[fileId] = bytes;
            await _writeManifestValue(fileId, version);
          }
        }
        // On web there is no disk cache: entries resolve while artwork
        // bytes stream on demand through [readArtworkBytes].
        entries.add(
          ProfileAvatar(
            id: id,
            assetFileName: name,
            label: remoteAvatarLabelFromId(id),
            remoteFileId: fileId,
          ),
        );
      }

      await _pruneRemoved(seenIds.keys.toSet());
      return Right(List<ProfileAvatar>.unmodifiable(entries));
    } on EdgeApiException catch (e) {
      AppLogger.warning('Remote avatar sync failed: $e');
      return Left(_classify(e));
    } catch (e) {
      AppLogger.warning('Remote avatar sync failed: $e');
      return Left(CacheFailure(message: e.toString()));
    }
  }

  /// Raw bytes for one synced avatar, used by the artwork provider. Serves
  /// the in-memory memo first, then the disk cache on native platforms;
  /// on web (no file system) streams the file on demand instead.
  Future<Either<Failure, List<int>>> readArtworkBytes(String fileId) async {
    final memo = _memoryBytes[fileId];
    if (memo != null) return Right(memo);
    try {
      final bytes = await _cache.readBytes('$fileId.json');
      _memoryBytes[fileId] = bytes;
      return Right(bytes);
    } catch (_) {
      final url = _urls[fileId];
      if (!_cache.isSupported && url != null) {
        try {
          final bytes = await _download(url);
          _assertValidLottie(bytes, fileId);
          _memoryBytes[fileId] = bytes;
          return Right(bytes);
        } on EdgeApiException catch (e) {
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

  Future<List<int>> _download(Uri url) async {
    final http.Response response;
    try {
      response = await _client.get(url).timeout(_timeout);
    } on TimeoutException {
      throw EdgeApiException('Avatar download timed out: ${url.path}');
    } catch (e) {
      throw EdgeApiException('Avatar download failed: $e');
    }
    if (response.statusCode != 200) {
      throw EdgeApiException(
        'Avatar download failed: ${url.path}',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  Failure _classify(EdgeApiException e) {
    final code = e.statusCode;
    if (code == 401 || code == 403) return AuthFailure(message: e.message);
    if (code == 404) {
      return CacheFailure(message: 'Avatar file not found: ${e.message}');
    }
    if (code == null) return NetworkFailure(message: e.message);
    return ServerFailure(message: e.message);
  }
}
