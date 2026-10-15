import 'dart:convert';
import 'dart:io' show File;
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/edge_auth.dart';
import '../config/cloudflare_config.dart';

/// Public URL of an R2 object served by the Worker
/// (`GET /api/v1/assets/<bucket>/<fileId>`).
///
/// Never use this for `paid_media`: private media is only reachable through
/// the signed URLs issued by `/api/v1/lessons/authorize`.
String workerAssetUrl(String bucketId, String fileId) =>
    '${CloudflareConfig.assetsEndpoint}/${Uri.encodeComponent(bucketId)}/'
    '${Uri.encodeComponent(fileId)}';

/// Content types the Worker accepts, by file extension.
const Map<String, String> mediaContentTypes = {
  'mp3': 'audio/mpeg',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'aac': 'audio/aac',
  'm4a': 'audio/mp4',
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'svg': 'image/svg+xml',
  'json': 'application/json',
  'mp4': 'video/mp4',
  'webm': 'video/webm',
  'mov': 'video/quicktime',
  'm4v': 'video/x-m4v',
};

/// Error from the Worker media API, carrying the HTTP status and the
/// Worker's machine-readable `error` code when present.
class WorkerMediaException implements Exception {
  const WorkerMediaException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'WorkerMediaException($statusCode, $code): $message';
}

/// Upload payload with a known length (the Worker requires Content-Length).
class UploadBody {
  const UploadBody(this.stream, this.length);

  final Stream<List<int>> stream;
  final int length;
}

/// In-memory bytes when present (web, small picks), else the native file
/// streamed from disk so large videos are not loaded into memory.
Future<UploadBody> openUploadBody(PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes != null) return UploadBody(Stream.value(bytes), bytes.length);
  final path = file.path;
  if (path == null) {
    throw const WorkerMediaException(
      'File data is missing. Ensure bytes or path is available.',
    );
  }
  final disk = File(path);
  return UploadBody(disk.openRead(), await disk.length());
}

class WorkerUploadResult {
  const WorkerUploadResult({
    required this.bucketId,
    required this.fileId,
    required this.url,
  });

  final String bucketId;
  final String fileId;

  /// Public asset URL, or null for private buckets (paid_media).
  final String? url;
}

/// Admin media storage on the Cloudflare Worker (R2), replacing Appwrite
/// Storage. Every call carries the admin's Appwrite JWT via [EdgeAuth].
class WorkerMediaApi {
  WorkerMediaApi({http.Client? httpClient, EdgeAuth? edgeAuth, Random? random})
    : _http = httpClient ?? http.Client(),
      _edgeAuth = edgeAuth ?? EdgeAuth.instance,
      _random = random ?? Random.secure();

  static const String privateBucket = 'paid_media';
  static const Duration _uploadTimeout = Duration(minutes: 10);
  static const Duration _requestTimeout = Duration(seconds: 20);

  final http.Client _http;
  final EdgeAuth _edgeAuth;
  final Random _random;

  /// A new 20-char id (`[0-9a-f]`), the same shape Appwrite's `ID.unique()`
  /// produced, so ids stay valid in both systems.
  String newFileId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final buffer = StringBuffer(ts);
    while (buffer.length < 20) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }
    return buffer.toString().substring(0, 20);
  }

  Uri _objectUri(String bucketId, String fileId) => Uri.parse(
    '${CloudflareConfig.adminMediaEndpoint}/${Uri.encodeComponent(bucketId)}/'
    '${Uri.encodeComponent(fileId)}',
  );

  /// Uploads [file] (bytes, or a native path) to `<bucketId>/<fileId>`.
  Future<WorkerUploadResult> uploadFile({
    required PlatformFile file,
    required String bucketId,
    required String contentType,
    String? fileId,
    String? filename,
  }) async {
    final id = fileId ?? newFileId();
    final request = http.StreamedRequest('PUT', _objectUri(bucketId, id));
    final body = await openUploadBody(file);
    request.headers.addAll({
      ...await _edgeAuth.headers(),
      'Content-Type': contentType,
      'Accept': 'application/json',
      'X-File-Name': filename ?? file.name,
    });
    request.contentLength = body.length;
    body.stream.listen(
      request.sink.add,
      onError: request.sink.addError,
      onDone: request.sink.close,
      cancelOnError: true,
    );

    final response = await http.Response.fromStream(
      await _http.send(request).timeout(_uploadTimeout),
    );
    final json = _decode(response, 'Upload');
    final returnedId = json['fileId']?.toString() ?? id;
    return WorkerUploadResult(
      bucketId: bucketId,
      fileId: returnedId,
      url: bucketId == privateBucket
          ? null
          : workerAssetUrl(bucketId, returnedId),
    );
  }

  /// Deletes `<bucketId>/<fileId>`. Returns whether an object was removed.
  Future<bool> delete(String bucketId, String fileId) async {
    final response = await _http
        .delete(_objectUri(bucketId, fileId), headers: await _jsonHeaders())
        .timeout(_requestTimeout);
    return _decode(response, 'Delete')['deleted'] == true;
  }

  /// Whether any D1 content row mentions [fileId]. Throws when the Worker
  /// cannot answer, so callers can refuse to delete (fail-safe).
  Future<bool> isReferenced(String fileId) async {
    final uri = Uri.parse(
      '${CloudflareConfig.adminMediaEndpoint}/references',
    ).replace(queryParameters: {'fileId': fileId});
    final response = await _http
        .get(uri, headers: await _jsonHeaders())
        .timeout(_requestTimeout);
    final json = _decode(response, 'Reference check');
    final referenced = json['referenced'];
    if (referenced is! bool) {
      throw const WorkerMediaException('Malformed reference check response');
    }
    return referenced;
  }

  Future<Map<String, String>> _jsonHeaders() async => {
    'Accept': 'application/json',
    ...await _edgeAuth.headers(),
  };

  Map<String, dynamic> _decode(http.Response response, String action) {
    Map<String, dynamic> json = const {};
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } on FormatException {
      // Non-JSON error body; reported below via the status code.
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        json['ok'] != true) {
      throw WorkerMediaException(
        '$action failed: ${json['message'] ?? 'HTTP ${response.statusCode}'}',
        statusCode: response.statusCode,
        code: json['error']?.toString(),
      );
    }
    return json;
  }
}

final workerMediaApiProvider = Provider<WorkerMediaApi>(
  (ref) => WorkerMediaApi(),
);
