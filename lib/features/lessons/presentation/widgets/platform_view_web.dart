import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

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
