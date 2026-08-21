import 'package:flutter/foundation.dart';
import 'web_share_adapter_stub.dart'
    if (dart.library.js_interop) 'web_share_adapter_web.dart';

/// Abstract adapter for browser-level sharing, file downloads, and clipboard operations.
///
/// Enables dependency injection and comprehensive unit testing of the JavaScript/DOM boundary.
abstract class WebShareAdapter {
  bool isShareSupported();
  bool canShareFiles(Uint8List imageBytes, String filename);
  bool canShareText(String text, String title, [String? url]);
  Future<void> shareFiles({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
  });
  Future<void> shareText({
    required String text,
    required String title,
    String? url,
  });
  String createBlobUrl(Uint8List bytes, String mimeType);
  void triggerDownload(String blobUrl, String filename);
  void revokeBlobUrl(String blobUrl);
  Future<void> copyToClipboard(String text);
}

WebShareAdapter createDefaultWebShareAdapter() => getWebShareAdapter();
