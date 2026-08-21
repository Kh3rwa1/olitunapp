import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import '../../../../core/logging/app_logger.dart';
import '../domain/affirmation_share_service.dart';

class AffirmationShareServiceImpl implements AffirmationShareService {
  @override
  Future<bool> canShareFiles(Uint8List imageBytes) async {
    try {
      final nav = web.window.navigator;
      final file = web.File(
        [imageBytes.toJS].toJS,
        'test.png',
        web.FilePropertyBag(type: 'image/png'),
      );
      final data = web.ShareData(files: [file].toJS);
      return nav.canShare(data);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> canShareText() async {
    try {
      final nav = web.window.navigator;
      final data = web.ShareData(text: 'test');
      return nav.canShare(data);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<AffirmationShareResult> shareImage({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
    Rect? shareOrigin,
  }) async {
    try {
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

      bool canShareFile = false;
      try {
        canShareFile = nav.canShare(shareData);
      } catch (_) {
        canShareFile = false;
      }

      if (canShareFile) {
        await nav.share(shareData).toDart;
        return AffirmationShareResult.shared;
      }

      // Fallback to text share if file sharing is not supported by this browser
      return await shareText(text: text, title: title);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('aborterror') ||
          errStr.contains('cancelled') ||
          errStr.contains('canceled') ||
          errStr.contains('user rejected')) {
        return AffirmationShareResult.cancelled;
      }
      AppLogger.debug('⚠️ Web shareImage failed, falling back to download: $e');
      return await downloadImage(imageBytes: imageBytes, filename: filename);
    }
  }

  @override
  Future<AffirmationShareResult> shareText({
    required String text,
    required String title,
    String? url,
    Rect? shareOrigin,
  }) async {
    try {
      final nav = web.window.navigator;
      final shareData = web.ShareData(title: title, text: text, url: url ?? '');

      bool supported = false;
      try {
        supported = nav.canShare(shareData);
      } catch (_) {
        // Some browser versions support share() but throw on canShare with text dictionaries
        supported = true;
      }

      if (supported) {
        await nav.share(shareData).toDart;
        return AffirmationShareResult.shared;
      }
      return await copyToClipboard(text);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('aborterror') ||
          errStr.contains('cancelled') ||
          errStr.contains('canceled') ||
          errStr.contains('user rejected')) {
        return AffirmationShareResult.cancelled;
      }
      return await copyToClipboard(text);
    }
  }

  @override
  Future<AffirmationShareResult> downloadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final blob = web.Blob(
        [imageBytes.toJS].toJS,
        web.BlobPropertyBag(type: 'image/png'),
      );
      final url = web.URL.createObjectURL(blob);
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none';

      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();

      // Delayed object URL revocation prevents download cancellation races in Safari/WebKit
      unawaited(
        Future.delayed(const Duration(milliseconds: 1500), () {
          try {
            web.URL.revokeObjectURL(url);
          } catch (_) {}
        }),
      );

      return AffirmationShareResult.downloaded;
    } catch (e) {
      AppLogger.debug('❌ Web downloadImage failed: $e');
      return AffirmationShareResult.failed;
    }
  }

  @override
  Future<AffirmationShareResult> copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return AffirmationShareResult.textCopied;
    } catch (_) {
      return AffirmationShareResult.failed;
    }
  }
}
