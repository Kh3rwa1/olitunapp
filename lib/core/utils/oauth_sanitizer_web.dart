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
