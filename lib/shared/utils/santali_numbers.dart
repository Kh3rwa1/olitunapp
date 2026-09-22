/// Canonical Santali (Ol Chiki) number catalog, 0-100.
///
/// Single source of truth for:
/// - [toOlChikiNumeral] / [toNumeral]: decimal value -> localized digits (᱐-᱙, ০-৯, ०-९, ୦-୯, 0-9).
/// - [nameLatin]/[nameOlChiki]: Santali number names (Mit, Bar, ..., Gel Mit,
///   Isi, Pe Gel, ..., Say) per omniglot/Santali counting
///   (10 Gel, 20 Isi, 30 Pe Gel, ..., 100 Say).
/// - [pronunciation]: Santali phonetic pronunciation in user's script ('bn', 'hi', 'or', 'en', 'sat').
/// - [teachingLanguageName]: Number meaning/name in learner's teaching language with numerals ('bn', 'hi', 'or', 'en', 'sat').
/// - [tryParseValue]: Resolves decimal value 0-100 from Ol Chiki numerals or Latin strings.
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

  static const List<String> _bengaliDigits = [
    '০',
    '১',
    '২',
    '৩',
    '৪',
    '৫',
    '৬',
    '৭',
    '৮',
    '৯',
  ];

  static const List<String> _hindiDigits = [
    '०',
    '१',
    '२',
    '३',
    '४',
    '५',
    '६',
    '७',
    '८',
    '९',
  ];

  static const List<String> _odiaDigits = [
    '୦',
    '୧',
    '୨',
    '୩',
    '୪',
    '୫',
    '୬',
    '୭',
    '୮',
    '୯',
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

  static const Map<int, String> _unitBengali = {
    0: 'সুনয়া',
    1: 'মিৎ',
    2: 'বার',
    3: 'পে',
    4: 'পুন',
    5: 'মণে',
    6: 'তুরুয়',
    7: 'এয়ায়',
    8: 'ইরল',
    9: 'আরে',
  };

  static const Map<int, String> _unitHindi = {
    0: 'सुनया',
    1: 'मित',
    2: 'बार',
    3: 'पे',
    4: 'पुन',
    5: 'मणे',
    6: 'तुरुय',
    7: 'एयाय',
    8: 'इरल',
    9: 'आरे',
  };

  static const Map<int, String> _unitOdia = {
    0: 'ସୁନୟା',
    1: 'ମିତ୍',
    2: 'ବାର୍',
    3: 'ପେ',
    4: 'ପୁନ୍',
    5: 'ମଣେ',
    6: 'ତୁରୁୟ',
    7: 'ଏୟାୟ',
    8: 'ଇରଲ୍',
    9: 'ଆରେ',
  };

  static const String gelLatin = 'Gel';
  static const String gelOlChiki = 'ᱜᱮᱞ';
  static const String gelBengali = 'গেল';
  static const String gelHindi = 'गेल';
  static const String gelOdia = 'ଗେଲ୍';

  static const String isiLatin = 'Isi';
  static const String isiOlChiki = 'ᱤᱥᱤ';
  static const String isiBengali = 'ইসি';
  static const String isiHindi = 'इसी';
  static const String isiOdia = 'ଇସି';

  static const String sayLatin = 'Say';
  static const String sayOlChiki = 'ᱥᱟᱭ';
  static const String sayBengali = 'সায়';
  static const String sayHindi = 'साय';
  static const String sayOdia = 'ସାୟ୍';

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

  /// Decimal [value] (0-100) rendered in digits of [lang] ('bn', 'hi', 'or', 'sat', 'en').
  static String toNumeral(int value, String lang) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    final decimal = value.toString();
    final buffer = StringBuffer();
    List<String>? targetDigits;
    switch (lang) {
      case 'bn':
        targetDigits = _bengaliDigits;
        break;
      case 'hi':
        targetDigits = _hindiDigits;
        break;
      case 'or':
        targetDigits = _odiaDigits;
        break;
      case 'sat':
        targetDigits = olChikiDigits;
        break;
      case 'en':
      default:
        return decimal;
    }
    for (var i = 0; i < decimal.length; i++) {
      buffer.write(targetDigits[decimal.codeUnitAt(i) - 0x30]);
    }
    return buffer.toString();
  }

  /// Santali name in Latin script, Title Case (e.g. `Gel Mit`, `Isi Bar`,
  /// `Pe Gel`, `Pe Gel Mit`, `Say`).
  static String nameLatin(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    return _composePhonetic(
      value: value,
      units: _unitLatin,
      gel: gelLatin,
      isi: isiLatin,
      say: sayLatin,
    );
  }

  /// Santali name in Ol Chiki (e.g. `ᱜᱮᱞ ᱢᱤᱫ`, `ᱤᱥᱤ ᱵᱟᱨ`,
  /// `ᱯᱮ ᱜᱮᱞ`, `ᱥᱟᱭ`).
  static String nameOlChiki(int value) {
    if (value < 0 || value > maxValue) {
      throw RangeError.range(value, 0, maxValue, 'value');
    }
    return _composePhonetic(
      value: value,
      units: _unitOlChiki,
      gel: gelOlChiki,
      isi: isiOlChiki,
      say: sayOlChiki,
    );
  }

  /// Santali pronunciation in the learner's chosen script/language [lang]
  /// ('bn', 'hi', 'or', 'en', 'sat').
  static String pronunciation(int value, String lang) {
    if (value < 0 || value > maxValue) return '';
    switch (lang) {
      case 'bn':
        return _composePhonetic(
          value: value,
          units: _unitBengali,
          gel: gelBengali,
          isi: isiBengali,
          say: sayBengali,
        );
      case 'hi':
        return _composePhonetic(
          value: value,
          units: _unitHindi,
          gel: gelHindi,
          isi: isiHindi,
          say: sayHindi,
        );
      case 'or':
        return _composePhonetic(
          value: value,
          units: _unitOdia,
          gel: gelOdia,
          isi: isiOdia,
          say: sayOdia,
        );
      case 'sat':
        return nameOlChiki(value);
      case 'en':
      default:
        return nameLatin(value);
    }
  }

  static String _composePhonetic({
    required int value,
    required Map<int, String> units,
    required String gel,
    required String isi,
    required String say,
  }) {
    if (value <= 9) return units[value]!;
    if (value == 10) return gel;
    if (value < 20) return '$gel ${units[value - 10]!}';
    if (value == 20) return isi;
    if (value < 30) return '$isi ${units[value - 20]!}';
    if (value == 100) return say;
    final tens = value ~/ 10;
    final ones = value % 10;
    final tensBase = '${units[tens]!} $gel';
    if (ones == 0) return tensBase;
    return '$tensBase ${units[ones]!}';
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

  /// English label for lesson blocks (e.g. `One`, `Twenty-One`, `One Hundred`).
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

  /// Canonical Bengali names for numbers 0 to 100.
  static const List<String> _bengaliNames = [
    'শূন্য',
    'এক',
    'দুই',
    'তিন',
    'চার',
    'পাঁচ',
    'ছয়',
    'সাত',
    'আট',
    'নয়',
    'দশ',
    'এগারো',
    'বারো',
    'তেরো',
    'চৌদ্দ',
    'পনেরো',
    'ষোলো',
    'সতেরো',
    'আঠারো',
    'উনিশ',
    'বিশ',
    'একুশ',
    'বাইশ',
    'তেইশ',
    'চব্বিশ',
    'পঁচিশ',
    'ছাব্বিশ',
    'সাতাশ',
    'আঠাশ',
    'উনত্রিশ',
    'ত্রিশ',
    'একত্রিশ',
    'বত্রিশ',
    'তেত্রিশ',
    'চৌত্রিশ',
    'পঁয়ত্রিশ',
    'ছত্রিশ',
    'সাঁইত্রিশ',
    'আটত্রিশ',
    'উনচল্লিশ',
    'চল্লিশ',
    'একচল্লিশ',
    'বিয়াল্লিশ',
    'তেতাল্লিশ',
    'চুয়াল্লিশ',
    'পঁয়তাল্লিশ',
    'ছেচল্লিশ',
    'সাতচল্লিশ',
    'আটচল্লিশ',
    'উনপঞ্চাশ',
    'পঞ্চাশ',
    'একান্ন',
    'বায়ান্ন',
    'তিপ্পান্ন',
    'চুয়ান্ন',
    'পঞ্চান্ন',
    'ছাপ্পান্ন',
    'সাতান্ন',
    'আটান্ন',
    'উনষাট',
    'ষাট',
    'একষট্টি',
    'বাষট্টি',
    'তেষট্টি',
    'চৌষট্টি',
    'পঁয়ষট্টি',
    'ছেষট্টি',
    'সাতষট্টি',
    'আটষট্টি',
    'উনসত্তর',
    'সত্তর',
    'একাত্তর',
    'বাহাত্তর',
    'তিয়াত্তর',
    'চুয়াত্তর',
    'পঁচাত্তর',
    'ছিয়াত্তর',
    'সাতাত্তর',
    'আটাত্তর',
    'উনআশি',
    'আশি',
    'একাশি',
    'বিরাশি',
    'তিরাশি',
    'চুরাশি',
    'পঁচাশি',
    'ছিয়াশি',
    'সাতাশি',
    'আটাশি',
    'উননব্বই',
    'নব্বই',
    'একানব্বই',
    'বিরানব্বই',
    'তিরানব্বই',
    'চুরানব্বই',
    'পঁচানব্বই',
    'ছিয়ানব্বই',
    'সাতানব্বই',
    'আটানব্বই',
    'নিরানব্বই',
    'একশো',
  ];

  /// Canonical Hindi names for numbers 0 to 100.
  static const List<String> _hindiNames = [
    'शून्य',
    'एक',
    'दो',
    'तीन',
    'चार',
    'पाँच',
    'छह',
    'सात',
    'आठ',
    'नौ',
    'दस',
    'ग्यारह',
    'बारह',
    'तेरह',
    'चौदह',
    'पंद्रह',
    'सोलह',
    'सत्रह',
    'अठारह',
    'उन्नीस',
    'बीस',
    'इक्कीस',
    'बाईस',
    'तेईस',
    'चौबीस',
    'पच्चीस',
    'छब्बीस',
    'सत्ताईस',
    'अट्ठाईस',
    'उनतीस',
    'तीस',
    'इकतीस',
    'बत्तीस',
    'तैंतीस',
    'चौंतीस',
    'पैंतीस',
    'छत्तीस',
    'सैंतीस',
    'अड़तीस',
    'उनतालीस',
    'चालीस',
    'इकतालीस',
    'बयालीस',
    'तैंतालीस',
    'चवालीस',
    'पैंतालीस',
    'छियालीस',
    'सैंतालीस',
    'अड़तालीस',
    'उनचास',
    'पचास',
    'इक्यावन',
    'बावन',
    'तिरपन',
    'चौवन',
    'पचपन',
    'छप्पन',
    'सत्तावन',
    'अट्ठावन',
    'उनसठ',
    'साठ',
    'इकसठ',
    'बासठ',
    'तिरसठ',
    'चौंसठ',
    'पैंसठ',
    'छियासठ',
    'सरसठ',
    'अड़सठ',
    'उनहत्तर',
    'सत्तर',
    'इकहत्तर',
    'बहत्तर',
    'तिहत्तर',
    'चौहत्तर',
    'पचहत्तर',
    'छिहत्तर',
    'सतहत्तर',
    'अठहत्तर',
    'उन्यासी',
    'अस्सी',
    'इक्यासी',
    'बयासी',
    'तिरासी',
    'चौरासी',
    'पचासी',
    'छियासी',
    'सत्तासी',
    'अट्ठासी',
    'नवासी',
    'नब्बे',
    'इक्यानवे',
    'बानवे',
    'तिरानवे',
    'चौरानवे',
    'पंचानवे',
    'छियानवे',
    'सत्तानवे',
    'अट्ठानवे',
    'निन्यानवे',
    'एक सौ',
  ];

  /// Canonical Odia names for numbers 0 to 100.
  static const List<String> _odiaNames = [
    'ଶୂନ୍ୟ',
    'ଏକ',
    'ଦୁଇ',
    'ତିନି',
    'ଚାରି',
    'ପାଞ୍ଚ',
    'ଛଅ',
    'ସାତ',
    'ଆଠ',
    'ନଅ',
    'ଦଶ',
    'ଏଗାର',
    'ବାର',
    'ତେର',
    'ଚଉଦ',
    'ପନ୍ଦର',
    'ଷୋହଳ',
    'ସତର',
    'ଅଠର',
    'ଉଣାଇଶ',
    'କୋଡ଼ିଏ',
    'ଏକୋଇଶ',
    'ବାଇଶ',
    'ତେଇଶ',
    'ଚବିଶ',
    'ପଚିଶ',
    'ଛବିଶ',
    'ସତାଇଶ',
    'ଅଠାଇଶ',
    'ଅଣତିରିଶ',
    'ତିରିଶ',
    'ଏକତିରିଶ',
    'ବତିରିଶ',
    'ତେତିରିଶ',
    'ଚଉତିରିଶ',
    'ପଞ୍ଚତିରିଶ',
    'ଛତିରିଶ',
    'ସଇଁତିରିଶ',
    'ଅଠତିରିଶ',
    'ଅଣଚାଳିଶ',
    'ଚାଳିଶ',
    'ଏକଚାଳିଶ',
    'ବୟାଳିଶ',
    'ତେୟାଳିଶ',
    'ଚଉରାଳିଶ',
    'ପଞ୍ଚଚାଳିଶ',
    'ଛୟାଳିଶ',
    'ସତଚାଳିଶ',
    'ଅଠଚାଳିଶ',
    'ଅଣଚାଶ',
    'ପଚାଶ',
    'ଏକାବନ',
    'ବାଉନ',
    'ତେପନ',
    'ଚଉବନ',
    'ପଞ୍ଚପନ',
    'ଛପନ',
    'ସତାବନ',
    'ଅଠାବନ',
    'ଅଣଷଠି',
    'ଷଠି',
    'ଏକଷଠି',
    'ବାଷଠି',
    'ତେଷଠି',
    'ଚଉଷଠି',
    'ପଞ୍ଚଷଠି',
    'ଛଅଷଠି',
    'ସତଷଠି',
    'ଅଠଷଠି',
    'ଅଣସ୍ତରି',
    'ସତରି',
    'ଏକସ୍ତରି',
    'ବାସ୍ତରି',
    'ତେସ୍ତରି',
    'ଚଉସ୍ତରି',
    'ପଞ୍ଚସ୍ତରି',
    'ଛଅସ୍ତରି',
    'ସତସ୍ତରି',
    'ଅଠସ୍ତରି',
    'ଅଣାଅଶୀ',
    'ଅଶୀ',
    'ଏକାଅଶୀ',
    'ବୟାଅଶୀ',
    'ତେୟାଅଶୀ',
    'ଚଉରାଅଶୀ',
    'ପଞ୍ଚାଅଶୀ',
    'ଛୟାଅଶୀ',
    'ସତାଅଶୀ',
    'ଅଠାଅଶୀ',
    'ଅଣାନବ୍ବେ',
    'ନବ୍ବେ',
    'ଏକାନବ୍ବେ',
    'ବୟାନବ୍ବେ',
    'ତେୟାନବ୍ବେ',
    'ଚଉରାନବ୍ବେ',
    'ପଞ୍ଚାନବ୍ବେ',
    'ଛୟାନବ୍ବେ',
    'ସତାନବ୍ବେ',
    'ଅଠାନବ୍ବେ',
    'ନବେନବ୍ବେ',
    'ଏକ ଶହ',
  ];

  /// Returns the localized name of [value] in the learner's chosen [teachingLanguage]
  /// ('bn', 'hi', 'or', 'en', 'sat'), optionally formatted with the numeral (e.g. `এক (১)`).
  static String teachingLanguageName(
    int value,
    String teachingLanguage, {
    bool includeNumeral = true,
  }) {
    if (value < 0 || value > maxValue) return '';
    final String rawName;
    switch (teachingLanguage) {
      case 'bn':
        rawName = _bengaliNames[value];
        break;
      case 'hi':
        rawName = _hindiNames[value];
        break;
      case 'or':
        rawName = _odiaNames[value];
        break;
      case 'sat':
        rawName = nameOlChiki(value);
        break;
      case 'en':
      default:
        rawName = englishName(value);
        break;
    }
    if (!includeNumeral) return rawName;
    final numeralStr = toNumeral(value, teachingLanguage);
    return '$rawName ($numeralStr)';
  }

  /// Attempts to parse an integer 0..100 from an Ol Chiki numeral string or
  /// a Latin string (such as `"1 – One"` or `"21 – Twenty-One"` or `"10"`).
  ///
  /// Returns `null` if the input is not a recognized number in 0..100.
  static int? tryParseValue(String? olChiki, String? latin) {
    if (olChiki != null && olChiki.trim().isNotEmpty) {
      final clean = olChiki.trim();
      int val = 0;
      bool allOlChikiDigits = true;
      for (final r in clean.runes) {
        if (r >= 0x1C50 && r <= 0x1C59) {
          val = val * 10 + (r - 0x1C50);
        } else {
          allOlChikiDigits = false;
          break;
        }
      }
      if (allOlChikiDigits && val >= 0 && val <= maxValue) {
        return val;
      }
    }

    if (latin != null && latin.trim().isNotEmpty) {
      final trimmed = latin.trim();
      final match = RegExp(r'^(\d{1,3})').firstMatch(trimmed);
      if (match != null) {
        final parsed = int.tryParse(match.group(1)!);
        if (parsed != null && parsed >= 0 && parsed <= maxValue) {
          return parsed;
        }
      }
    }

    return null;
  }
}
