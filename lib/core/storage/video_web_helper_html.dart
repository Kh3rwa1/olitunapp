import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

String createObjectUrl(List<int> bytes) {
  final blob = web.Blob(<JSAny>[Uint8List.fromList(bytes).toJS].toJS);
  return web.URL.createObjectURL(blob);
}

void revokeObjectUrl(String url) {
  web.URL.revokeObjectURL(url);
}
