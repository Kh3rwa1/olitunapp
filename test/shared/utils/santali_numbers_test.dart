import 'package:flutter_test/flutter_test.dart';
import 'package:itun/shared/utils/santali_numbers.dart';

void main() {
  test('Ol Chiki numerals use U+1C50 block for 0-100', () {
    expect(SantaliNumbers.toOlChikiNumeral(0), '᱐');
    expect(SantaliNumbers.toOlChikiNumeral(3), '᱓');
    expect(SantaliNumbers.toOlChikiNumeral(10), '᱑᱐');
    expect(SantaliNumbers.toOlChikiNumeral(14), '᱑᱔');
    expect(SantaliNumbers.toOlChikiNumeral(20), '᱒᱐');
    expect(SantaliNumbers.toOlChikiNumeral(42), '᱔᱒');
    expect(SantaliNumbers.toOlChikiNumeral(100), '᱑᱐᱐');
    for (var v = 0; v <= 100; v++) {
      final numeral = SantaliNumbers.toOlChikiNumeral(v);
      expect(
        numeral.runes.every((r) => r >= 0x1C50 && r <= 0x1C59),
        isTrue,
        reason: 'value $v -> $numeral',
      );
    }
  });

  test('Santali names follow Gel/Isi/Pe Gel/Say counting', () {
    expect(SantaliNumbers.nameLatin(0), 'Sunya');
    expect(SantaliNumbers.nameLatin(1), 'Mit');
    expect(SantaliNumbers.nameLatin(10), 'Gel');
    expect(SantaliNumbers.nameLatin(11), 'Gel Mit');
    expect(SantaliNumbers.nameLatin(19), 'Gel Are');
    expect(SantaliNumbers.nameLatin(20), 'Isi');
    expect(SantaliNumbers.nameLatin(21), 'Isi Mit');
    expect(SantaliNumbers.nameLatin(30), 'Pe Gel');
    expect(SantaliNumbers.nameLatin(42), 'Pun Gel Bar');
    expect(SantaliNumbers.nameLatin(99), 'Are Gel Are');
    expect(SantaliNumbers.nameLatin(100), 'Say');

    expect(SantaliNumbers.nameOlChiki(10), 'ᱜᱮᱞ');
    expect(SantaliNumbers.nameOlChiki(11), 'ᱜᱮᱞ ᱢᱤᱫ');
    expect(SantaliNumbers.nameOlChiki(20), 'ᱤᱥᱤ');
    expect(SantaliNumbers.nameOlChiki(30), 'ᱯᱮ ᱜᱮᱞ');
    expect(SantaliNumbers.nameOlChiki(100), 'ᱥᱟᱭ');
  });

  test('English labels match lesson block style', () {
    expect(SantaliNumbers.englishName(0), 'Zero');
    expect(SantaliNumbers.englishName(14), 'Fourteen');
    expect(SantaliNumbers.englishName(20), 'Twenty');
    expect(SantaliNumbers.englishName(21), 'Twenty-One');
    expect(SantaliNumbers.englishName(100), 'One Hundred');
  });
}
