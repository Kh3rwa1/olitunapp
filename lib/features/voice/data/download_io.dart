import 'dart:io' show Directory, File;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile/desktop save: keeps the WAV under `<app-docs>/olitun_voice/` and
/// returns the absolute path for the share sheet.
Future<String?> saveVoiceBytes(String fileName, Uint8List bytes) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/olitun_voice');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
