import 'dart:convert';

/// Persist only file identity + lesson context. A scoped reference is NOT an
/// authorization grant; the function checks entitlement and association anew.
class PrivateMediaReference {
  const PrivateMediaReference(this.bucketId, this.fileId, this.lessonId);

  static const bucket = String.fromEnvironment(
    'PAID_MEDIA_BUCKET_ID',
    defaultValue: 'paid_media',
  );
  final String bucketId;
  final String fileId;
  final String? lessonId;

  static PrivateMediaReference? parse(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null) return null;
    final rest = RegExp(
      r'/storage/buckets/([a-zA-Z0-9._-]+)/files/([a-zA-Z0-9._-]+)(?:/|$)',
    ).firstMatch(uri.path);
    if (rest != null && rest.group(1) == bucket) {
      return PrivateMediaReference(
        bucket,
        rest.group(2)!,
        uri.queryParameters['lessonId'],
      );
    }
    final custom = RegExp(
      r'^appwrite-(?:storage://|file:)([a-zA-Z0-9._-]+)[/:]([a-zA-Z0-9._-]+)$',
    ).firstMatch(source.split('?').first);
    if (custom != null && custom.group(1) == bucket) {
      return PrivateMediaReference(
        bucket,
        custom.group(2)!,
        uri.queryParameters['lessonId'],
      );
    }
    return null;
  }

  static String scope(String source, String lessonId) {
    final reference = parse(source);
    if (reference == null) return source;
    // Deliberately discard any old bearer token and all caller-supplied query
    // parameters. This URL is never fetched directly by the media players.
    return Uri(
      scheme: 'appwrite-storage',
      host: reference.bucketId,
      path: '/${reference.fileId}',
      queryParameters: {'lessonId': lessonId},
    ).toString();
  }
}

/// Handles nested maps/lists and legacy JSON-encoded block data without
/// replacing media identities in persistent content with expiring credentials.
dynamic scopeLessonMediaValue(dynamic value, String lessonId) {
  if (value is Map) {
    return value.map(
      (key, value) => MapEntry(key, scopeLessonMediaValue(value, lessonId)),
    );
  }
  if (value is List) {
    return value.map((v) => scopeLessonMediaValue(v, lessonId)).toList();
  }
  if (value is String) {
    if (PrivateMediaReference.parse(value) != null) {
      return PrivateMediaReference.scope(value, lessonId);
    }
    final trimmed = value.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        return jsonEncode(scopeLessonMediaValue(jsonDecode(value), lessonId));
      } on FormatException {
        // Ordinary text, not JSON.
      }
    }
  }
  return value;
}

class MediaAccessException implements Exception {
  const MediaAccessException();

  @override
  String toString() => 'Private media unavailable. Reconnect or verify access.';
}

class MediaLease {
  const MediaLease(this.uri, {this.expiresAt, this.mimeType});
  final Uri uri;
  final DateTime? expiresAt;
  final String? mimeType;

  Duration? refreshAfter(DateTime now) {
    final expiry = expiresAt;
    if (expiry == null) return null;
    final remaining = expiry.difference(now) - const Duration(seconds: 30);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

typedef MediaExecute = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> body,
);

/// No token cache, disk writes, URL logging or binary downloads. Each call is
/// reauthorized using the current Appwrite session, including every refresh.
class AuthorizedMediaService {
  AuthorizedMediaService({
    required this.execute,
    required this.endpoint,
    required this.projectId,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final MediaExecute execute;
  final String endpoint;
  final String projectId;
  final DateTime Function() clock;

  Future<MediaLease> resolve(String source) async {
    final reference = PrivateMediaReference.parse(source);
    if (reference == null) return MediaLease(Uri.parse(source));
    final lessonId = reference.lessonId;
    if (lessonId == null || lessonId.isEmpty) {
      throw const MediaAccessException();
    }
    try {
      final body = await execute({
        'action': 'get_media',
        'protocolVersion': 2,
        'lessonId': lessonId,
        'bucketId': reference.bucketId,
        'fileId': reference.fileId,
      }).timeout(const Duration(seconds: 15));
      final url = Uri.parse(body['url'] as String);
      final expected = Uri.parse(
        '${endpoint.replaceFirst(RegExp(r'/$'), '')}/storage/buckets/'
        '${reference.bucketId}/files/${reference.fileId}/view',
      );
      final expires = DateTime.parse(body['expiresAt'] as String).toUtc();
      final remaining = expires.difference(clock().toUtc());
      if (body['ok'] != true ||
          body['protocolVersion'] != 2 ||
          body['transport'] != 'appwrite-file-token' ||
          body['bucketId'] != reference.bucketId ||
          body['fileId'] != reference.fileId ||
          url.scheme != 'https' ||
          url.origin != expected.origin ||
          url.path != expected.path ||
          url.userInfo.isNotEmpty ||
          url.hasFragment ||
          url.queryParameters['project'] != projectId ||
          (url.queryParameters['token']?.isEmpty ?? true) ||
          remaining <= const Duration(seconds: 30) ||
          remaining > const Duration(minutes: 5)) {
        throw const MediaAccessException();
      }
      return MediaLease(
        url,
        expiresAt: expires,
        mimeType: body['mimeType'] as String?,
      );
    } catch (_) {
      // SDK and player errors may carry bearer URLs: keep failures sanitized.
      throw const MediaAccessException();
    }
  }
}
