import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/categories/data/models/category_model.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';

void main() {
  group('Category Model & Entity Coverage Tests', () {
    test('CategoryModel JSON serialization and deserialization', () {
      final json = {
        '\$id': 'cat_101',
        'titleLatin': 'Alphabet Basics',
        'titleOlChiki': 'ᱚᱞ ᱪᱤᱠᱤ',
        'subtitle': 'Learn Ol Chiki alphabet',
        'description': 'Description text',
        'iconName': 'school',
        'sortOrder': 1,
        'unlockMode': 'free',
        'priceInr': 0,
        'prerequisiteCategoryId': '',
        'passScorePercentage': 80,
        'totalLessonsCount': 10,
        'version': 1,
        'badgeId': 'badge_1',
      };

      final model = CategoryModel.fromJson(json);
      expect(model.id, 'cat_101');
      expect(model.titleLatin, 'Alphabet Basics');
      expect(model.unlockMode, 'free');

      final toMap = model.toJson();
      expect(toMap['id'], 'cat_101');

      final entity = model.toEntity();
      expect(entity.id, 'cat_101');
      expect(entity.titleLatin, 'Alphabet Basics');

      final fromEntity = CategoryModel.fromEntity(entity);
      expect(fromEntity.id, 'cat_101');
    });

    test('CategoryEntity properties and getters', () {
      const category = CategoryEntity(
        id: 'cat_202',
        titleLatin: 'Advanced Ol Chiki',
        titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
        description: 'Advanced course description',
        iconName: 'book',
        order: 2,
        unlockMode: 'paid_only',
        priceInr: 499,
        totalLessons: 15,
      );

      expect(category.isPremium, isTrue);
      expect(category.unlockMode, 'paid_only');
      expect(category.priceInr, 499);
    });
  });
}
