import 'package:flutter/services.dart';

Future<void> exportAnalyticsCsv({
  required String filename,
  required String csv,
}) async {
  await Clipboard.setData(ClipboardData(text: csv));
}

const analyticsCsvExportLabel = 'copied';
