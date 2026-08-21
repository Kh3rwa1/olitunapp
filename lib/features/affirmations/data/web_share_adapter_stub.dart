import 'package:flutter/services.dart';
import 'web_share_adapter.dart';

WebShareAdapter getWebShareAdapter() => const StubWebShareAdapter();

class StubWebShareAdapter implements WebShareAdapter {
  const StubWebShareAdapter();

  @override
  bool isShareSupported() => false;

  @override
  bool canShareFiles(Uint8List imageBytes, String filename) => false;

  @override
  bool canShareText(String text, String title, [String? url]) => false;

  @override
  Future<void> shareFiles({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
  }) async {}

  @override
  Future<void> shareText({
    required String text,
    required String title,
    String? url,
  }) async {}

  @override
  String createBlobUrl(Uint8List bytes, String mimeType) => '';

  @override
  void triggerDownload(String blobUrl, String filename) {}

  @override
  void revokeBlobUrl(String blobUrl) {}

  @override
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
