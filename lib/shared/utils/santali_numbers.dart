/// Canonical Santali (Ol Chiki) number catalog, 0-100.
///
/// Single source of truth for:
/// - [toOlChikiNumeral]: decimal value -> Ol Chiki digits (᱐-᱙).
/// - [nameLatin]/[nameOlChiki]: Santali number names (Mit, Bar, ..., Gel Mit,
///   Isi, Pe Gel, ..., Say) per omniglot/Santali counting
///   (10 Gel, 20 Isi, 30 Pe Gel, ..., 100 Say).
/// - [englishName]: English labels used for lesson blocks
///   (Zero ... Twenty, Twenty-One ... One Hundred).
class SantaliNumbers {
  static const List<String> olChikiDigits = [
    '᱐',
    '᱑',
    '᱒',
    '᱓',
    '᱔',
    '᱕',
    '᱖',
    '᱗',
    '᱘',
    '᱙',
  ];

  static const Map<int, String> _unitLatin = {
    0: 'Sunya',
    1: 'Mit',
    2: 'Bar',
    3: 'Pe',
    4: 'Pun',
    5: 'Mone',
    6: 'Turui',
    7: 'Eae',
    8: 'Iral',
    9: 'Are',
  };

  static const Map<int, String> _unitOlChiki = {
    0: 'ᱥᱩᱱᱭᱟ',
    1: 'ᱢᱤᱫ',
    2: 'ᱵᱟᱨ',
    3: 'ᱯᱮ',
    4: 'ᱯᱩᱱ',
    5: 'ᱢᱚᱬᱮ',
    6: 'ᱛᱩᱨᱩᱭ',
    7: 'ᱮᱭᱟᱭ',
    8: 'ᱤᱨᱟᱹᱞ',
    9: 'ᱟᱨᱮ',
  };

  static const String gelLatin = 'Gel';
  static const String gelOlChiki = 'ᱜᱮᱞ';
  static const String isiLatin = 'Isi';
  static const String isiOlChiki = 'ᱤᱥᱤ';
  static const String sayLatin = 'Say';
  static const String sayOlChiki = 'ᱥᱟᱭ';

  static const int maxValue = 100;

  /// Decimal [value] (0-100) rendered with Ol Chiki digits.
  static String toOlChikiNumeral(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    final decimal = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < decimal.length; i++) {
      buffer.write(olChikiDigits[decimal.codeUnitAt(i) - 0x30]);
    }
    return buffer.toString();
  }

  /// Santali name in Latin script, Title Case (e.g. `Gel Mit`, `Isi Bar`,
  /// `Pe Gel`, `Pe Gel Mit`, `Say`).
  static String nameLatin(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    if (value <= 9) return _unitLatin[value]!;
    if (value == 10) return gelLatin;
    if (value < 20) return '$gelLatin ${_unitLatin[value - 10]!}';
    if (value == 20) return isiLatin;
    if (value < 30) return '$isiLatin ${_unitLatin[value - 20]!}';
    if (value == 100) return sayLatin;
    final tens = value ~/ 10;
    final ones = value % 10;
    final tensBase = '${_unitLatin[tens]!} $gelLatin';
    if (ones == 0) return tensBase;
    return '$tensBase ${_unitLatin[ones]!}';
  }

  /// Santali name in Ol Chiki (e.g. `ᱜᱮᱞ ᱢᱤᱫ`, `ᱤᱥᱤ ᱵᱟᱨ`,
  /// `ᱯᱮ ᱜᱮᱞ`, `ᱥᱟᱭ`).
  static String nameOlChiki(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    if (value <= 9) return _unitOlChiki[value]!;
    if (value == 10) return gelOlChiki;
    if (value < 20) return '$gelOlChiki ${_unitOlChiki[value - 10]!}';
    if (value == 20) return isiOlChiki;
    if (value < 30) return '$isiOlChiki ${_unitOlChiki[value - 20]!}';
    if (value == 100) return sayOlChiki;
    final tens = value ~/ 10;
    final ones = value % 10;
    final tensBase = '${_unitOlChiki[tens]!} $gelOlChiki';
    if (ones == 0) return tensBase;
    return '$tensBase ${_unitOlChiki[ones]!}';
  }

  static const List<String> _onesEnglish = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
    'Eleven',
    'Twelve',
    'Thirteen',
    'Fourteen',
    'Fifteen',
    'Sixteen',
    'Seventeen',
    'Eighteen',
    'Nineteen',
  ];

  static const Map<int, String> _tensEnglish = {
    2: 'Twenty',
    3: 'Thirty',
    4: 'Forty',
    5: 'Fifty',
    6: 'Sixty',
    7: 'Seventy',
    8: 'Eighty',
    9: 'Ninety',
  };

  /// English label for lesson blocks (matches existing `0 – Zero` style).
  static String englishName(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    if (value < 20) return _onesEnglish[value];
    if (value == 100) return 'One Hundred';
    final tens = value ~/ 10;
    final ones = value % 10;
    final tensWord = _tensEnglish[tens]!;
    if (ones == 0) return tensWord;
    return '$tensWord-${_onesEnglish[ones]}';
  }
}
