import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/data/models/lesson_model.dart';

void main() {
  group('LessonModel media fields', () {
    test('injects root hero media fields into data for UI compatibility', () {
      final model = LessonModel.fromJson({
        'id': 'lesson-1',
        'categoryId': 'cat-1',
        'titleOlChiki': 'ᱯᱟᱲᱦᱟ',
        'titleLatin': 'Daily Conversations',
        'heroMediaUrl': 'https://cdn.example.com/hero.webm',
        'heroMediaType': 'video',
        'heroPosterUrl': 'https://cdn.example.com/poster.webp',
      });

      expect(model.data?['heroMediaUrl'], 'https://cdn.example.com/hero.webm');
      expect(model.data?['heroMediaType'], 'video');
      expect(
        model.data?['heroPosterUrl'],
        'https://cdn.example.com/poster.webp',
      );
    });

    test('serializes hero media fields back to Appwrite root attributes', () {
      const model = LessonModel(
        id: 'lesson-1',
        categoryId: 'cat-1',
        titleOlChiki: 'ᱯᱟᱲᱦᱟ',
        titleLatin: 'Daily Conversations',
        data: {
          'heroMediaUrl': 'https://cdn.example.com/hero.lottie',
          'heroMediaType': 'lottie',
          'heroPosterUrl': 'https://cdn.example.com/poster.webp',
          'thumbnailUrl': 'https://cdn.example.com/poster.webp',
        },
        blocks: [],
      );

      final json = model.toJson();

      expect(json['heroMediaUrl'], 'https://cdn.example.com/hero.lottie');
      expect(json['heroMediaType'], 'lottie');
      expect(json['heroPosterUrl'], 'https://cdn.example.com/poster.webp');
      expect(json['thumbnailUrl'], 'https://cdn.example.com/poster.webp');
    });
  });
}
