import 'dart:js_interop';
import 'dart:ui' show Rect;

import 'package:web/web.dart' as web;

Future<void> exportAnalyticsCsv({
  required String filename,
  required String csv,
  Rect? sharePositionOrigin,
}) async {
  final blob = web.Blob(
    [csv.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

const analyticsCsvExportLabel = 'downloaded';
