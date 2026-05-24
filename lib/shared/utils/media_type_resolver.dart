enum MediaKind { image, svg, lottie, video, html, audio, unknown }

class MediaTypeResolver {
  const MediaTypeResolver._();

  static MediaKind resolve(String? url) {
    final lower = url?.trim().toLowerCase();
    if (lower == null || lower.isEmpty) return MediaKind.unknown;

    if (_hasAny(lower, const [
          '.mp4',
          '.webm',
          '.mov',
          '.m4v',
          '.3gp',
          '.avi',
        ]) ||
        lower.contains('/buckets/videos/')) {
      return MediaKind.video;
    }
    if (_hasAny(lower, const ['.json', '.lottie']) ||
        lower.contains('/buckets/animations/')) {
      return MediaKind.lottie;
    }
    if (lower.contains('.svg') || lower.contains('image/svg')) {
      return MediaKind.svg;
    }
    if (_hasAny(lower, const ['.html', '.htm']) ||
        lower.contains('text/html') ||
        lower.contains('/buckets/html/')) {
      return MediaKind.html;
    }
    if (_hasAny(lower, const ['.mp3', '.wav', '.ogg', '.aac', '.m4a']) ||
        lower.contains('/buckets/audio/')) {
      return MediaKind.audio;
    }
    if (_hasAny(lower, const ['.png', '.jpg', '.jpeg', '.webp', '.gif'])) {
      return MediaKind.image;
    }

    return MediaKind.unknown;
  }

  static String appwriteHeroMediaType(String? url) => resolve(url).name;

  static bool isRenderableHero(String? url) {
    switch (resolve(url)) {
      case MediaKind.image:
      case MediaKind.svg:
      case MediaKind.lottie:
      case MediaKind.video:
      case MediaKind.html:
        return true;
      case MediaKind.audio:
      case MediaKind.unknown:
        return false;
    }
  }

  static bool _hasAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }
}
