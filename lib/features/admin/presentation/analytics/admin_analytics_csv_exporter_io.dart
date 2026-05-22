import 'dart:io';
import 'dart:ui' show Rect;

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportAnalyticsCsv({
  required String filename,
  required String csv,
  Rect? sharePositionOrigin,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(csv, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      title: 'Olitun analytics CSV',
      subject: 'Olitun learning analytics export',
      text: 'Olitun learning analytics export',
      files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
      fileNameOverrides: [filename],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

const analyticsCsvExportLabel = 'opened in share sheet';
