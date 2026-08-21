import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/logging/app_logger.dart';
import '../domain/affirmation_share_service.dart';

class AffirmationShareServiceImpl implements AffirmationShareService {
  @override
  Future<bool> canShareFiles(Uint8List imageBytes) async => true;

  @override
  Future<bool> canShareText() async => true;

  @override
  Future<AffirmationShareResult> shareImage({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
    Rect? shareOrigin,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedFilename = filename.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final file = File('${tempDir.path}/$sanitizedFilename');
      await file.writeAsBytes(imageBytes);

      final result = await SharePlus.instance.share(
        ShareParams(
          title: title,
          subject: title,
          text: text,
          files: [XFile(file.path)],
          sharePositionOrigin: shareOrigin,
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        return AffirmationShareResult.cancelled;
      }
      return AffirmationShareResult.shared;
    } catch (e) {
      AppLogger.debug('❌ IO shareImage failed: $e');
      return await copyToClipboard(text);
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
      final content = url != null && url.isNotEmpty ? '$text\n\n$url' : text;
      final result = await SharePlus.instance.share(
        ShareParams(
          title: title,
          subject: title,
          text: content,
          sharePositionOrigin: shareOrigin,
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        return AffirmationShareResult.cancelled;
      }
      return AffirmationShareResult.shared;
    } catch (e) {
      AppLogger.debug('❌ IO shareText failed: $e');
      return await copyToClipboard(text);
    }
  }

  @override
  Future<AffirmationShareResult> downloadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    try {
      final sanitizedFilename = filename.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$sanitizedFilename');
      await file.writeAsBytes(imageBytes);
      return AffirmationShareResult.downloaded;
    } catch (e) {
      AppLogger.debug('❌ IO downloadImage failed: $e');
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
