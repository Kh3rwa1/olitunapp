/// Builds bounded notification artwork without changing audio URLs or losing
/// Appwrite project/file-token query parameters.
Uri? notificationArtworkUri(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final isRemote = uri.scheme == 'https' || uri.scheme == 'http';
  final match = RegExp(
    r'/storage/buckets/[^/]+/files/[^/]+/(view|preview)$',
  ).firstMatch(uri.path);
  if (!isRemote || match == null) return uri;

  final matchedSegment = match.group(0)!;
  final previewPath = matchedSegment.endsWith('/view')
      ? '${uri.path.substring(0, uri.path.length - 5)}/preview'
      : uri.path;

  return uri.replace(
    path: previewPath,
    queryParameters: <String, dynamic>{
      ...uri.queryParametersAll,
      'width': '300',
      'height': '300',
      'output': 'webp',
    },
  );
}
