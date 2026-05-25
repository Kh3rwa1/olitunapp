import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/utils/media_type_resolver.dart';

void main() {
  group('MediaTypeResolver', () {
    test('recognizes lesson hero media formats', () {
      expect(
        MediaTypeResolver.resolve('https://cdn.example.com/hero.webp'),
        MediaKind.image,
      );
      expect(
        MediaTypeResolver.resolve('https://cdn.example.com/hero.webm'),
        MediaKind.video,
      );
      expect(
        MediaTypeResolver.resolve('https://cdn.example.com/hero.lottie'),
        MediaKind.lottie,
      );
      expect(
        MediaTypeResolver.resolve('https://cdn.example.com/hero.json'),
        MediaKind.lottie,
      );
      expect(
        MediaTypeResolver.resolve('/storage/buckets/animations/files/a/view'),
        MediaKind.lottie,
      );
      expect(
        MediaTypeResolver.resolve('https://cdn.example.com/interactive.html'),
        MediaKind.html,
      );
      expect(
        MediaTypeResolver.resolve('/storage/buckets/html/files/a/view'),
        MediaKind.html,
      );
    });

    test('marks visual media as hero-renderable', () {
      expect(MediaTypeResolver.isRenderableHero('hero.mp4'), isTrue);
      expect(MediaTypeResolver.isRenderableHero('hero.svg'), isTrue);
      expect(MediaTypeResolver.isRenderableHero('hero.html'), isTrue);
      expect(MediaTypeResolver.isRenderableHero('hero.mp3'), isFalse);
      expect(MediaTypeResolver.isRenderableHero(null), isFalse);
    });
  });
}
