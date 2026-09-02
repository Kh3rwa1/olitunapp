import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
// The gate requires the shared re-export surface itself to be exercised.
import 'package:itun/shared/models/content/category_model.dart';

void main() {
  group('CategoryModel (via shared/models re-export)', () {
    test('fromJson applies defaults for optional fields', () {
      final model = CategoryModel.fromJson({
        'id': 'cat_vocab',
        'titleOlChiki': 'ᱜᱟᱛᱮ',
        'titleLatin': 'Vocab',
      }, 'cat_vocab');

      expect(model.id, 'cat_vocab');
      expect(model.titleOlChiki, 'ᱜᱟᱛᱮ');
      expect(model.titleLatin, 'Vocab');
      expect(model.gradientPreset, 'skyBlue');
      expect(model.order, 0);
      expect(model.isActive, isTrue);
      expect(model.totalLessons, 0);
      expect(model.unlockMode, 'free');
      expect(model.priceInr, 0);
      expect(model.previewLessonCount, 3);
    });

    test('fromJson decodes the full paid-category payload', () {
      final model = CategoryModel.fromJson({
        r'$id': 'cat_premium',
        'titleOlChiki': 'ᱥᱮᱬᱟ',
        'titleLatin': 'Advanced',
        'iconName': 'school',
        'gradientPreset': 'sunset',
        'order': 7,
        'isActive': false,
        'totalLessons': 12,
        'description': 'Deep dive',
        'unlockMode': 'purchase',
        'priceInr': 199,
        'previewLessonCount': 2,
      });

      expect(model.id, 'cat_premium');
      expect(model.iconName, 'school');
      expect(model.gradientPreset, 'sunset');
      expect(model.order, 7);
      expect(model.isActive, isFalse);
      expect(model.totalLessons, 12);
      expect(model.unlockMode, 'purchase');
      expect(model.priceInr, 199);
      expect(model.previewLessonCount, 2);
    });

    test('toJson round-trips through fromJson', () {
      const model = CategoryModel(
        id: 'cat_rhymes',
        titleOlChiki: 'ᱫᱮᱞᱟ',
        titleLatin: 'Rhymes',
        iconName: 'music',
        order: 4,
        totalLessons: 9,
      );

      final restored = CategoryModel.fromJson(model.toJson());

      expect(restored.id, model.id);
      expect(restored.titleOlChiki, model.titleOlChiki);
      expect(restored.titleLatin, model.titleLatin);
      expect(restored.iconName, model.iconName);
      expect(restored.order, model.order);
      expect(restored.totalLessons, model.totalLessons);
    });

    test('still satisfies the CategoryEntity contract', () {
      const model = CategoryModel(
        id: 'cat_x',
        titleOlChiki: 'ᱛ',
        titleLatin: 'T',
      );
      expect(model, isA<CategoryEntity>());
      expect(model.props, contains('cat_x'));
    });
  });
}
