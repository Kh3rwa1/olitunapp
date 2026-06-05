import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Native (IO) implementation of the CSV exporter.
Future<void> saveAndShareCsv({
  required String csvContent,
  required String filename,
  required String shareSubject,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(csvContent, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      title: filename,
      subject: shareSubject,
      text: shareSubject,
      files: [XFile(file.path, mimeType: 'text/csv', name: filename)],
      fileNameOverrides: [filename],
    ),
  );
}
