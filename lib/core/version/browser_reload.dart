import 'browser_reload_io.dart'
    if (dart.library.html) 'browser_reload_html.dart' as impl;

void reloadBrowser() {
  impl.reloadBrowser();
}
