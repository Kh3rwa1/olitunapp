// Conditional export: url_strategy_web.dart on web, stub on mobile
export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
