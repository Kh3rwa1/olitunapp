import 'dart:io' show File;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../logging/app_logger.dart';

enum ShareOutcome { shared, copiedToClipboard, downloaded, cancelled, failed }

class GrowthShareService {
  const GrowthShareService();

  /// Captures a widget attached to [boundaryKey] as a PNG [Uint8List].
  Future<Uint8List?> captureWidgetToImage(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary =
          boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        AppLogger.debug('Capture failed: RepaintBoundary not found.');
        return null;
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      AppLogger.debug('Error capturing widget image: $e');
      return null;
    }
  }

  /// Shares an image card on mobile via native share sheet or falls back to text/clipboard on web.
  Future<ShareOutcome> shareCardImage({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
    Rect? shareOrigin,
  }) async {
    if (kIsWeb) {
      // Web fallback: copy share text to clipboard
      return copyTextToClipboard(text);
    }

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
        return ShareOutcome.cancelled;
      }
      return ShareOutcome.shared;
    } catch (e) {
      AppLogger.debug(
        'Native image share failed: $e. Falling back to clipboard.',
      );
      return copyTextToClipboard(text);
    }
  }

  /// Shares promotional or milestone text with app download deep links.
  Future<ShareOutcome> shareText({
    required String text,
    required String title,
    String? url,
    Rect? shareOrigin,
  }) async {
    final fullText = url != null && url.isNotEmpty ? '$text\n\n$url' : text;

    if (kIsWeb) {
      return copyTextToClipboard(fullText);
    }

    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          title: title,
          subject: title,
          text: fullText,
          sharePositionOrigin: shareOrigin,
        ),
      );

      if (result.status == ShareResultStatus.dismissed) {
        return ShareOutcome.cancelled;
      }
      return ShareOutcome.shared;
    } catch (e) {
      AppLogger.debug('Native text share failed: $e');
      return copyTextToClipboard(fullText);
    }
  }

  /// Copies text to system clipboard.
  Future<ShareOutcome> copyTextToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return ShareOutcome.copiedToClipboard;
    } catch (e) {
      AppLogger.debug('Clipboard write failed: $e');
      return ShareOutcome.failed;
    }
  }
}
