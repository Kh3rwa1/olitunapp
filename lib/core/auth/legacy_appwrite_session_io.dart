import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';

// The Appwrite Flutter SDK keeps its session as the `a_session_<project>`
// cookie in a PersistCookieJar under <documents>/cookies. Opening a jar on
// the same folder (same default options) reads that cookie without starting
// the SDK client, so a device signed in before the move to Worker sign-in
// can hand its session to the Worker once and keep its account.

Future<PersistCookieJar?> _jar() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/cookies');
  if (!await dir.exists()) return null;
  return PersistCookieJar(storage: FileStorage(dir.path));
}

/// The saved Appwrite session secret for [endpoint], or null when none.
Future<String?> readLegacyAppwriteSession({
  required String endpoint,
  required String projectId,
}) async {
  final uri = Uri.tryParse(endpoint);
  if (uri == null || !uri.hasAuthority) return null;
  final jar = await _jar();
  if (jar == null) return null;
  final cookies = await jar.loadForRequest(uri);
  final name = 'a_session_$projectId';
  for (final wanted in [name, '${name}_legacy']) {
    for (final cookie in cookies) {
      if (cookie.name == wanted && cookie.value.isNotEmpty) return cookie.value;
    }
  }
  return null;
}

/// Forgets the Appwrite cookies after a migration (or a rejected session).
Future<void> clearLegacyAppwriteSession({required String endpoint}) async {
  final uri = Uri.tryParse(endpoint);
  if (uri == null || !uri.hasAuthority) return;
  final jar = await _jar();
  await jar?.delete(uri, true);
}
