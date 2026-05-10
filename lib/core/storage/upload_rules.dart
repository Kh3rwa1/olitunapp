/// Centralised upload validation rules for admin media uploads.
///
/// All admin screens should call [validate] before uploading to ensure
/// consistent limits, naming constraints, and content-type checks.
class UploadRules {
  UploadRules._();

  /// Max image dimension (either axis) — larger images should be
  /// compressed client-side before upload.
  static const int maxImageDimensionPx = 2048;

  /// Max file sizes by category.
  static const int maxImageBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxAudioBytes = 20 * 1024 * 1024; // 20 MB
  static const int maxAnimationBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxVideoBytes = 50 * 1024 * 1024; // 50 MB

  /// Allowed extensions per category.
  static const Set<String> imageExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'gif',
    'svg',
  };
  static const Set<String> audioExtensions = {
    'mp3',
    'wav',
    'ogg',
    'aac',
    'm4a',
  };
  static const Set<String> animationExtensions = {'json', 'lottie'};
  static const Set<String> videoExtensions = {'mp4', 'webm', 'mov'};

  /// Characters allowed in filenames after sanitisation.
  static final RegExp _safeFilename = RegExp(r'^[A-Za-z0-9._-]+$');

  /// Validate a file before upload. Returns null on success, or a
  /// human-readable error message.
  static String? validate({
    required String filename,
    required int sizeBytes,
    required UploadCategory category,
  }) {
    if (filename.isEmpty) return 'Filename is empty.';

    final ext = filename.split('.').last.toLowerCase();
    final allowed = _allowedExtensions(category);
    if (!allowed.contains(ext)) {
      return 'Unsupported file type ".$ext". Allowed: ${allowed.map((e) => '.$e').join(', ')}';
    }

    if (sizeBytes <= 0) return 'File is empty.';

    final maxBytes = _maxBytes(category);
    if (sizeBytes > maxBytes) {
      final maxMb = maxBytes / (1024 * 1024);
      final actualMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return 'File too large (${actualMb}MB). Maximum for ${category.name}: ${maxMb.toStringAsFixed(0)}MB.';
    }

    final sanitized = sanitizeFilename(filename);
    if (!_safeFilename.hasMatch(sanitized)) {
      return 'Filename contains invalid characters after sanitisation.';
    }

    return null;
  }

  /// Sanitise a filename: strip path separators, replace unsafe chars.
  static String sanitizeFilename(String raw) {
    final basename = raw.split(RegExp(r'[/\\]+')).last;
    final sanitized = basename
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return sanitized.isEmpty ? 'upload' : sanitized;
  }

  /// Whether the file is a candidate for client-side compression.
  ///
  /// Only raster images (png, jpg, webp, gif) benefit from compression;
  /// SVGs and Lottie JSONs should not be recompressed.
  static bool shouldCompress(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return const {'png', 'jpg', 'jpeg', 'webp', 'gif'}.contains(ext);
  }

  /// Recommended max quality (0–100) for JPEG/WebP compression.
  static int recommendedQuality(int sizeBytes) {
    if (sizeBytes > 3 * 1024 * 1024) return 70;
    if (sizeBytes > 1 * 1024 * 1024) return 80;
    return 90;
  }

  // ── Internal ──

  static Set<String> _allowedExtensions(UploadCategory category) {
    switch (category) {
      case UploadCategory.image:
        return imageExtensions;
      case UploadCategory.audio:
        return audioExtensions;
      case UploadCategory.animation:
        return animationExtensions;
      case UploadCategory.video:
        return videoExtensions;
    }
  }

  static int _maxBytes(UploadCategory category) {
    switch (category) {
      case UploadCategory.image:
        return maxImageBytes;
      case UploadCategory.audio:
        return maxAudioBytes;
      case UploadCategory.animation:
        return maxAnimationBytes;
      case UploadCategory.video:
        return maxVideoBytes;
    }
  }
}

/// Upload content categories.
enum UploadCategory { image, audio, animation, video }
