/// Builds bounded notification artwork without changing audio URLs or losing
/// Appwrite project/file-token query parameters.
Uri? notificationArtworkUri(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final isRemote = uri.scheme == 'https' || uri.scheme == 'http';
  final isFileView = RegExp(
    r'/storage/buckets/[^/]+/files/[^/]+/view$',
  ).hasMatch(uri.path);
  if (!isRemote || !isFileView) return uri;

  return uri.replace(
    path: '${uri.path.substring(0, uri.path.length - 5)}/preview',
    queryParameters: <String, dynamic>{
      ...uri.queryParametersAll,
      'width': '300',
      'height': '300',
      'output': 'webp',
    },
  );
}
