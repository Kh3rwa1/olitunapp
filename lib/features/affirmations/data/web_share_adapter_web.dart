import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'web_share_adapter.dart';

WebShareAdapter getWebShareAdapter() => const StandardWebShareAdapter();

class StandardWebShareAdapter implements WebShareAdapter {
  const StandardWebShareAdapter();

  @override
  bool isShareSupported() {
    try {
      final nav = web.window.navigator;
      return (nav as dynamic).share != null;
    } catch (_) {
      return false;
    }
  }

  @override
  bool canShareFiles(Uint8List imageBytes, String filename) {
    try {
      final nav = web.window.navigator;
      final file = web.File(
        [imageBytes.toJS].toJS,
        filename,
        web.FilePropertyBag(type: 'image/png'),
      );
      final data = web.ShareData(files: [file].toJS);
      return nav.canShare(data);
    } catch (_) {
      return false;
    }
  }

  @override
  bool canShareText(String text, String title, [String? url]) {
    try {
      final nav = web.window.navigator;
      final data = web.ShareData(title: title, text: text, url: url ?? '');
      return nav.canShare(data);
    } catch (_) {
      return true;
    }
  }

  @override
  Future<void> shareFiles({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
  }) async {
    final nav = web.window.navigator;
    final file = web.File(
      [imageBytes.toJS].toJS,
      filename,
      web.FilePropertyBag(type: 'image/png'),
    );
    final shareData = web.ShareData(
      title: title,
      text: text,
      files: [file].toJS,
    );
    await nav.share(shareData).toDart;
  }

  @override
  Future<void> shareText({
    required String text,
    required String title,
    String? url,
  }) async {
    final nav = web.window.navigator;
    final shareData = web.ShareData(title: title, text: text, url: url ?? '');
    await nav.share(shareData).toDart;
  }

  @override
  String createBlobUrl(Uint8List bytes, String mimeType) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    return web.URL.createObjectURL(blob);
  }

  @override
  void triggerDownload(String blobUrl, String filename) {
    final anchor = web.HTMLAnchorElement()
      ..href = blobUrl
      ..download = filename
      ..style.display = 'none';

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  }

  @override
  void revokeBlobUrl(String blobUrl) {
    web.URL.revokeObjectURL(blobUrl);
  }

  @override
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
