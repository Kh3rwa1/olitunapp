/// Web: no Appwrite session cookie is readable from Dart.
Future<String?> readLegacyAppwriteSession({
  required String endpoint,
  required String projectId,
}) async => null;

Future<void> clearLegacyAppwriteSession({required String endpoint}) async {}
