import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Web (HTML) implementation of the CSV exporter.
Future<void> saveAndShareCsv({
  required String csvContent,
  required String filename,
  required String shareSubject,
}) async {
  final bytes = utf8.encode(csvContent);
  final blob = web.Blob(
    <JSAny>[bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
