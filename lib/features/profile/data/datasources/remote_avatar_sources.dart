/// Naming conventions for the remote avatar bucket.
///
/// Admins upload `.json` Lottie files to the `profile_avatars` Appwrite
/// Storage bucket; each file becomes one avatar choice with no app release.
/// See `RemoteAvatarDatasource` for syncing and `availableAvatarsProvider`
/// for the remote-first resolution order.
library;

/// Appwrite Storage bucket holding the live avatar set (public read,
///
/// admin write).
const String remoteAvatarBucketId = 'profile_avatars';

/// Derives a stable, persistable avatar id from a bucket file name:
/// lowercased, `avatar_` prefix and `.json` suffix stripped, runs of other
/// characters collapsed to a single underscore. Returns an empty string
/// when nothing usable remains (caller skips such files).
String remoteAvatarIdFromFilename(String filename) {
  var stem = filename.toLowerCase();
  if (stem.endsWith('.json')) {
    stem = stem.substring(0, stem.length - '.json'.length);
  }
  if (stem.startsWith('avatar_')) {
    stem = stem.substring('avatar_'.length);
  }
  final sanitized = stem
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp('^_+|_+\$'), '');
  return sanitized;
}

/// Human label for the picker grid: `paw_prints` becomes `Paw prints`.
String remoteAvatarLabelFromId(String id) {
  final words = id.split('_').where((word) => word.isNotEmpty).toList();
  if (words.isEmpty) return id;
  final [first, ...rest] = words;
  final head = first[0].toUpperCase() + first.substring(1);
  return ([head, ...rest]).join(' ');
}
