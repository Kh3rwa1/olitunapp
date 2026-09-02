import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/affirmations/domain/entities/affirmation_entity.dart';

AffirmationEntity _entity({String? audioUrl, bool isPremium = false}) =>
    AffirmationEntity(
      id: 'aff_1',
      olChikiText: 'ᱚᱛᱮ ᱵᱟᱵᱩ',
      santaliPhonetic: 'ate babu',
      englishMeaning: 'Be strong, child',
      audioUrl: audioUrl,
      category: 'courage',
      isPremium: isPremium,
      order: 3,
      publishedAt: '2026-01-15',
    );

void main() {
  test('equal entities with identical fields are equal and hash-equal', () {
    final a = _entity();
    final b = _entity();

    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
  });

  test('any differing field breaks equality via props', () {
    final base = _entity();
    expect(
      base,
      isNot(
        equals(
          const AffirmationEntity(
            id: 'aff_2',
            olChikiText: 'ᱚᱛᱮ ᱵᱟᱵᱩ',
            santaliPhonetic: 'ate babu',
            englishMeaning: 'Be strong, child',
            category: 'courage',
            order: 3,
            publishedAt: '2026-01-15',
          ),
        ),
      ),
    );
    expect(base, isNot(equals(_entity(isPremium: true))));
  });

  test('optional audio url participates in props', () {
    final withoutAudio = _entity();
    final withAudio = _entity(audioUrl: 'https://cdn.test/aff_1.mp3');

    expect(withAudio.audioUrl, 'https://cdn.test/aff_1.mp3');
    expect(withAudio, isNot(equals(withoutAudio)));
  });

  test('defaults keep non-premium tier and preserve field values', () {
    final entity = _entity();

    expect(entity.isPremium, isFalse);
    expect(entity.order, 3);
    expect(entity.category, 'courage');
    expect(entity.englishMeaning, 'Be strong, child');
    expect(entity.santaliPhonetic, 'ate babu');
  });
}
