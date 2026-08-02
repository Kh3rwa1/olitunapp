// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

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
      html.window.history.replaceState(null, html.document.title, cleanedUri.toString());
    }
  } catch (_) {
    // Ignore history replace state exceptions on unsupported browser environments
  }
}
