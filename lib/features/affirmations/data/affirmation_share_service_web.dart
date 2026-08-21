import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../../../../core/logging/app_logger.dart';
import '../domain/affirmation_share_service.dart';
import 'web_share_adapter.dart';

class AffirmationShareServiceImpl implements AffirmationShareService {
  final WebShareAdapter adapter;

  AffirmationShareServiceImpl({WebShareAdapter? adapter})
    : adapter = adapter ?? createDefaultWebShareAdapter();

  @override
  Future<bool> canShareFiles(Uint8List imageBytes) async {
    return adapter.canShareFiles(imageBytes, 'test.png');
  }

  @override
  Future<bool> canShareText() async {
    return adapter.canShareText('test', 'test');
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
      if (adapter.isShareSupported()) {
        if (adapter.canShareFiles(imageBytes, filename)) {
          await adapter.shareFiles(
            imageBytes: imageBytes,
            filename: filename,
            title: title,
            text: text,
          );
          return AffirmationShareResult.shared;
        }

        if (adapter.canShareText(text, title)) {
          await adapter.shareText(text: text, title: title);
          return AffirmationShareResult.shared;
        }
      }

      // If native sharing is completely unavailable or lacks file/text capability, download PNG image
      return await downloadImage(imageBytes: imageBytes, filename: filename);
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
      if (adapter.isShareSupported() &&
          adapter.canShareText(text, title, url)) {
        await adapter.shareText(text: text, title: title, url: url);
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
      final url = adapter.createBlobUrl(imageBytes, 'image/png');
      adapter.triggerDownload(url, filename);

      // Delayed object URL revocation prevents download cancellation races in Safari/WebKit
      unawaited(
        Future.delayed(const Duration(milliseconds: 1500), () {
          try {
            adapter.revokeBlobUrl(url);
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
      await adapter.copyToClipboard(text);
      return AffirmationShareResult.textCopied;
    } catch (_) {
      return AffirmationShareResult.failed;
    }
  }
}
