import 'package:web/web.dart' as web;

void sanitizeWebHistory() {
  try {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('secret') ||
        uri.queryParameters.containsKey('userId') ||
        uri.queryParameters.containsKey('key') ||
        uri.queryParameters.containsKey('token')) {
      final cleanedUri = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
        fragment: uri.fragment,
      );
      web.window.history.replaceState(
        null,
        web.document.title,
        cleanedUri.toString(),
      );
    }
  } catch (_) {
    // Ignore history replace state exceptions on unsupported browser environments
  }
}

/// Removes a one-time OAuth `error` query parameter (e.g. after a failed
/// OAuth redirect to /welcome) so it is shown once and never bookmarked.
void clearOAuthErrorParam() {
  try {
    final uri = Uri.base;
    if (!uri.queryParameters.containsKey('error')) return;
    final params = Map<String, String>.of(uri.queryParameters)..remove('error');
    final cleanedUri = uri.replace(queryParameters: params);
    web.window.history.replaceState(
      null,
      web.document.title,
      cleanedUri.toString(),
    );
  } catch (_) {
    // Ignore history replace state exceptions on unsupported browser environments
  }
}
