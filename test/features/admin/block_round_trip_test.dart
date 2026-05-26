import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  group('LessonBlockEntity <-> ContentBlock round-trip', () {
    test('video block preserves URL, poster, autoplay through round-trip', () {
      const original = LessonBlockEntity(
        type: 'video',
        textLatin: 'A cool video',
        data: {
          'id': 'blk_video_fixed',
          'media': {
            'url': 'https://cdn.example.com/v.mp4',
            'kind': 'video',
            'fileId': 'f1',
          },
          'posterUrl': 'https://cdn.example.com/poster.png',
          'autoplay': true,
          'durationSeconds': 42,
          'themeColor': '#10B981', // meta passthrough
        },
      );

      final block = original.toContentBlock(0) as VideoBlock;
      expect(block.media.url, 'https://cdn.example.com/v.mp4');
      expect(block.posterUrl, 'https://cdn.example.com/poster.png');
      expect(block.autoplay, isTrue);
      expect(block.durationSeconds, 42);
      expect(block.meta['themeColor'], '#10B981');
      expect(block.id, 'blk_video_fixed');

      // JSON round-trip through Appwrite-style string column
      final encoded = jsonEncode(block.toJson());
      final decoded = ContentBlock.fromJson(jsonDecode(encoded));
      expect(decoded, isA<VideoBlock>());
      final v2 = decoded as VideoBlock;
      expect(v2.media.url, block.media.url);
      expect(v2.posterUrl, block.posterUrl);
      expect(v2.autoplay, block.autoplay);
      expect(v2.meta['themeColor'], '#10B981');
    });

    test(
      'lottie block preserves animation URL even when only legacy imageUrl is set',
      () {
        const legacy = LessonBlockEntity(
          type: 'lottie',
          imageUrl: 'https://cdn.example.com/anim.json',
          data: {'loop': false, 'pronunciation': 'lo-tee'},
        );
        final block = legacy.toContentBlock(0) as LottieBlock;
        expect(block.media.url, 'https://cdn.example.com/anim.json');
        expect(block.loop, isFalse);
        expect(block.meta['pronunciation'], 'lo-tee');
      },
    );

    test('quiz block accepts both quizId and legacy quizRefId', () {
      const legacy = LessonBlockEntity(
        type: 'quiz',
        data: {'quizRefId': 'quiz_42'},
      );
      const modern = LessonBlockEntity(
        type: 'quiz',
        data: {'quizId': 'quiz_99'},
      );
      expect((legacy.toContentBlock(0) as QuizBlock).quizId, 'quiz_42');
      expect((modern.toContentBlock(1) as QuizBlock).quizId, 'quiz_99');
    });

    test(
      'reverse: ContentBlock -> LessonBlockEntity preserves media for editor reopen',
      () {
        const original = VideoBlock(
          id: 'blk_v',
          order: 0,
          media: ContentMedia(
            url: 'https://x/y.mp4',
            fileId: 'f',
            kind: ContentMediaKind.video,
          ),
          posterUrl: 'https://x/p.png',
          autoplay: true,
          meta: {'themeColor': '#EE0000'},
        );
        final legacy = original.toLessonBlockEntity();
        expect(legacy.data?['media']?['url'], 'https://x/y.mp4');
        expect(legacy.data?['posterUrl'], 'https://x/p.png');
        expect(legacy.data?['autoplay'], true);
        expect(legacy.data?['themeColor'], '#EE0000');
        expect(legacy.audioUrl, 'https://x/y.mp4'); // legacy compat
        expect(legacy.imageUrl, 'https://x/p.png'); // legacy compat
      },
    );

    test('reorder does not change block ids', () {
      const blocks = [
        LessonBlockEntity(type: 'text', textLatin: 'A', data: {'id': 'blk_a'}),
        LessonBlockEntity(type: 'text', textLatin: 'B', data: {'id': 'blk_b'}),
      ];
      final c0 = blocks[0].toContentBlock(0);
      final c1 = blocks[1].toContentBlock(1);
      // swap
      final swapped0 = blocks[1].toContentBlock(0);
      final swapped1 = blocks[0].toContentBlock(1);
      expect(c0.id, swapped1.id); // A keeps its id even at index 1
      expect(c1.id, swapped0.id);
    });
  });
}
