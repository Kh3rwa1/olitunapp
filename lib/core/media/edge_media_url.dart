import '../config/cloudflare_config.dart';

/// Buckets served only through signed, entitlement-checked routes.
const Set<String> _privateBuckets = {'paid_media', 'backups'};

final RegExp _appwriteFile = RegExp(
  r'/storage/buckets/([A-Za-z0-9._-]+)/files/([A-Za-z0-9._-]+)(?:/|$)',
);

/// Maps a legacy Appwrite Storage URL to the same object on the Worker's R2
/// assets route (`/api/v1/assets/<bucket>/<fileId>`), which carries the same
/// keys. Appwrite Storage answers 402 while the organisation is read-only, so
/// every public audio, image and video URL goes through the edge instead.
/// Anything that is not a public Appwrite file URL is returned unchanged.
String toEdgeMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return url;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return url;
  final match = _appwriteFile.firstMatch(uri.path);
  if (match == null) return url;
  final bucket = match.group(1)!;
  if (_privateBuckets.contains(bucket)) return url;
  final base = CloudflareConfig.baseUrl.trim();
  if (base.isEmpty) return url;
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$root/api/v1/assets/$bucket/${match.group(2)}';
}
