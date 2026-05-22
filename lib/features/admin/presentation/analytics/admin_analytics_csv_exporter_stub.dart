import 'package:flutter/services.dart';

Future<void> exportAnalyticsCsv({
  required String filename,
  required String csv,
  Rect? sharePositionOrigin,
}) async {
  await Clipboard.setData(ClipboardData(text: csv));
}

const analyticsCsvExportLabel = 'copied';
