import 'dart:ui' show Rect;
import 'package:flutter/foundation.dart';

/// Result of an affirmation sharing or export action.
enum AffirmationShareResult {
  shared,
  downloaded,
  textCopied,
  linkCopied,
  cancelled,
  unsupported,
  failed,
}

/// Abstract interface for platform-specific sharing operations.
abstract class AffirmationShareService {
  /// Whether native file sharing via Web Share API / OS is supported on the current platform.
  Future<bool> canShareFiles(Uint8List imageBytes);

  /// Whether native text sharing via Web Share API / OS is supported on the current platform.
  Future<bool> canShareText();

  /// Shares an image file with optional title and text.
  ///
  /// On Web, this MUST be called synchronously within a direct user interaction event.
  Future<AffirmationShareResult> shareImage({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
    Rect? shareOrigin,
  });

  /// Shares text and an optional URL.
  Future<AffirmationShareResult> shareText({
    required String text,
    required String title,
    String? url,
    Rect? shareOrigin,
  });

  /// Downloads the image file to the user's device.
  /// On Web, this creates a Blob, triggers an anchor download, and revokes the Object URL.
  /// On Mobile/Desktop, this saves to the downloads / documents directory or opens share.
  Future<AffirmationShareResult> downloadImage({
    required Uint8List imageBytes,
    required String filename,
  });

  /// Copies text to clipboard.
  Future<AffirmationShareResult> copyToClipboard(String text);
}
