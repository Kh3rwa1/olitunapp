import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

final Set<String> _registeredSvgViews = {};

void registerHtmlView(String viewId, String url) {
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int viewId) => web.HTMLIFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%',
  );
}

void registerSvgHtmlView(String viewId, String svgText) {
  if (_registeredSvgViews.contains(viewId)) return;
  _registeredSvgViews.add(viewId);

  // Capture svgText by value in a final variable for the closure.
  final svgContent = svgText;

  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) {
    final div = web.HTMLDivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.display = 'flex'
      ..style.justifyContent = 'center'
      ..style.alignItems = 'center';

    try {
      // Try modern setHTMLUnsafe first
      (div as dynamic).setHTMLUnsafe(svgContent.toJS);
    } catch (e) {
      try {
        final parser = web.DOMParser();
        final doc = parser.parseFromString(
          svgContent.toJS,
          'image/svg+xml'.toJS as dynamic,
        );
        final svgNode = doc.documentElement;
        if (svgNode != null) {
          div.append(svgNode);
        }
      } catch (_) {
        // If all parsing fails, we set innerHTML as a last resort
        div.innerHTML = svgContent.toJS;
      }
    }
    return div;
  });
}
