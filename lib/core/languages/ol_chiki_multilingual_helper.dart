import 'package:flutter/widgets.dart';


/// Resolved localized presentation of an Ol Chiki learning item.
@immutable
class LocalizedItemDisplay {
  /// The primary script glyph / target text (Ol Chiki).
  final String scriptText;

  /// Transliterated pronunciation guide in the user's script (Bengali, Devanagari, Odia, Latin).
  final String transliteration;

  /// Meaning / explanation translated to the learner's chosen language (Bengali, Hindi, Odia, English).
  final String meaning;

  /// Combined subtitle for cards (e.g. "বাবা – পিতা" or "Baba – Father").
  final String subtitle;

  /// Clean hero title (without repetitive clutter).
  final String title;

  /// Action button label (e.g. "শুনুন" / "सुनেন" / "ଶୁଣନ୍ତୁ" / "LISTEN").
  final String ctaText;

  const LocalizedItemDisplay({
    required this.scriptText,
    required this.transliteration,
    required this.meaning,
    required this.subtitle,
    required this.title,
    required this.ctaText,
  });
}

/// Helper utility for transliterating Ol Chiki into regional Indic scripts
/// (Bengali, Hindi/Devanagari, Odia) and English/Latin, as well as resolving
/// localized meanings and clean subtitles for any learning block.
class OlChikiMultilingualHelper {
  const OlChikiMultilingualHelper._();

  // ──────────────────────────────────────────────────────────────────────────
  // 1. CHARACTER MAPPINGS
  // ──────────────────────────────────────────────────────────────────────────

  static const Map<String, String> _toBengaliChar = {
    // Vowels (Independent)
    'ᱚ': 'অ', 'ᱟ': 'আ', 'ᱤ': 'ই', 'ᱩ': 'উ', 'ᱮ': 'এ', 'ᱳ': 'ও',
    // Consonants
    'ᱛ': 'ত', 'ᱜ': 'গ', 'ᱝ': 'ঙ', 'ᱞ': 'ল', 'ᱠ': 'ক',
    'ᱡ': 'জ', 'ᱢ': 'ম', 'ᱣ': 'ওয়', 'ᱥ': 'স', 'ᱦ': 'হ',
    'ᱧ': 'ঞ', 'ᱨ': 'র', 'ᱪ': 'চ', 'ᱫ': 'দ', 'ᱬ': 'ণ',
    'ᱭ': 'য়', 'ᱯ': 'প', 'ᱰ': 'ড', 'ᱱ': 'ন', 'ᱲ': 'ড়',
    'ᱴ': 'ট', 'ᱵ': 'ব', 'ᱶ': 'ঁ',
    // Modifiers & Diacritics
    'ᱷ': 'হ্', 'ᱸ': 'ঁ', 'ᱹ': '়', 'ᱺ': 'ঃ', 'ᱻ': 'ঽ', 'ᱼ': '্', 'ᱽ': '্',
    // Digits
    '᱐': '০', '᱑': '১', '᱒': '২', '᱓': '৩', '᱔': '৪',
    '᱕': '৫', '᱖': '৬', '᱗': '৭', '᱘': '৮', '᱙': '৯',
    // Punctuation
    '᱾': '।', '᱿': '॥',
  };

  static const Map<String, String> _toHindiChar = {
    // Vowels (Independent)
    'ᱚ': 'अ', 'ᱟ': 'आ', 'ᱤ': 'इ', 'ᱩ': 'उ', 'ᱮ': 'ए', 'ᱳ': 'ओ',
    // Consonants
    'ᱛ': 'त', 'ᱜ': 'ग', 'ᱝ': 'ङ', 'ᱞ': 'ल', 'ᱠ': 'क',
    'ᱡ': 'ज', 'ᱢ': 'म', 'ᱣ': 'व', 'ᱥ': 'स', 'ᱦ': 'ह',
    'ᱧ': 'ञ', 'ᱨ': 'र', 'ᱪ': 'च', 'ᱫ': 'द', 'ᱬ': 'ण',
    'ᱭ': 'य', 'ᱯ': 'प', 'ᱰ': 'ड', 'ᱱ': 'न', 'ᱲ': 'ड़',
    'ᱴ': 'ट', 'ᱵ': 'ब', 'ᱶ': 'ँ',
    // Modifiers & Diacritics
    'ᱷ': 'ह्', 'ᱸ': 'ँ', 'ᱹ': '़', 'ᱺ': 'ः', 'ᱻ': 'ऽ', 'ᱼ': '्', 'ᱽ': '्',
    // Digits
    '᱐': '०', '᱑': '१', '᱒': '२', '᱓': '३', '᱔': '४',
    '᱕': '५', '᱖': '६', '᱗': '७', '᱘': '८', '᱙': '९',
    // Punctuation
    '᱾': '।', '᱿': '॥',
  };

  static const Map<String, String> _toOdiaChar = {
    // Vowels (Independent)
    'ᱚ': 'ଅ', 'ᱟ': 'ଆ', 'ᱤ': 'ଇ', 'ᱩ': 'ଉ', 'ᱮ': 'ଏ', 'ᱳ': 'ଓ',
    // Consonants
    'ᱛ': 'ତ', 'ᱜ': 'ଗ', 'ᱝ': 'ଙ', 'ᱞ': 'ଲ', 'ᱠ': 'କ',
    'ᱡ': 'ଜ', 'ᱢ': 'ମ', 'ᱣ': 'ୱ', 'ᱥ': 'ସ', 'ᱦ': 'ହ',
    'ᱧ': 'ଞ', 'ᱨ': 'ର', 'ᱪ': 'ଚ', 'ᱫ': 'ଦ', 'ᱬ': 'ଣ',
    'ᱭ': 'ୟ', 'ᱯ': 'ପ', 'ᱰ': 'ଡ', 'ᱱ': 'ନ', 'ᱲ': 'ଡ଼',
    'ᱴ': 'ଟ', 'ᱵ': 'ବ', 'ᱶ': 'ଁ',
    // Modifiers & Diacritics
    'ᱷ': 'ହ୍', 'ᱸ': 'ଁ', 'ᱹ': '଼', 'ᱺ': 'ଃ', 'ᱻ': 'ଽ', 'ᱼ': '୍', 'ᱽ': '୍',
    // Digits
    '᱐': '୦', '᱑': '୧', '᱒': '୨', '᱓': '୩', '᱔': '୪',
    '᱕': '୫', '᱖': '୬', '᱗': '୭', '᱘': '୮', '᱙': '୯',
    // Punctuation
    '᱾': '।', '᱿': '॥',
  };

  static const Map<String, String> _toLatinChar = {
    // Vowels
    'ᱚ': 'o', 'ᱟ': 'a', 'ᱤ': 'i', 'ᱩ': 'u', 'ᱮ': 'e', 'ᱳ': 'o',
    // Consonants
    'ᱛ': 't', 'ᱜ': 'g', 'ᱝ': 'ng', 'ᱞ': 'l', 'ᱠ': 'k',
    'ᱡ': 'j', 'ᱢ': 'm', 'ᱣ': 'w', 'ᱥ': 's', 'ᱦ': 'h',
    'ᱧ': 'ny', 'ᱨ': 'r', 'ᱪ': 'c', 'ᱫ': 'd', 'ᱬ': 'n',
    'ᱭ': 'y', 'ᱯ': 'p', 'ᱰ': 'd', 'ᱱ': 'n', 'ᱲ': 'r',
    'ᱴ': 't', 'ᱵ': 'b', 'ᱶ': 'n',
    // Modifiers & Diacritics
    'ᱷ': 'h', 'ᱸ': 'n', 'ᱹ': '', 'ᱺ': '', 'ᱻ': '', 'ᱼ': '', 'ᱽ': '',
    // Digits
    '᱐': '0', '᱑': '1', '᱒': '2', '᱓': '3', '᱔': '4',
    '᱕': '5', '᱖': '6', '᱗': '7', '᱘': '8', '᱙': '9',
    // Punctuation
    '᱾': '.', '᱿': '..',
  };

  static const Set<String> _consonants = {
    'ᱛ',
    'ᱜ',
    'ᱝ',
    'ᱞ',
    'ᱠ',
    'ᱡ',
    'ᱢ',
    'ᱣ',
    'ᱥ',
    'ᱦ',
    'ᱧ',
    'ᱨ',
    'ᱪ',
    'ᱫ',
    'ᱬ',
    'ᱭ',
    'ᱯ',
    'ᱰ',
    'ᱱ',
    'ᱲ',
    'ᱴ',
    'ᱵ',
    'ᱶ',
  };

  static const Set<String> _vowels = {'ᱚ', 'ᱟ', 'ᱤ', 'ᱩ', 'ᱮ', 'ᱳ'};

  static const Map<String, String> _bengaliMatra = {
    'ᱚ': '',
    'ᱟ': 'া',
    'ᱤ': 'ি',
    'ᱩ': 'ু',
    'ᱮ': 'ে',
    'ᱳ': 'ো',
  };

  static const Map<String, String> _hindiMatra = {
    'ᱚ': '',
    'ᱟ': 'ा',
    'ᱤ': 'ि',
    'ᱩ': 'ु',
    'ᱮ': 'े',
    'ᱳ': 'ो',
  };

  static const Map<String, String> _odiaMatra = {
    'ᱚ': '',
    'ᱟ': 'ା',
    'ᱤ': 'ି',
    'ᱩ': 'ୁ',
    'ᱮ': 'େ',
    'ᱳ': 'ୋ',
  };

  // ──────────────────────────────────────────────────────────────────────────
  // 2. COMMON DICTIONARY / GLOSS TRANSLATIONS
  // ──────────────────────────────────────────────────────────────────────────

  static const Map<String, Map<String, String>> _glossTranslations = {
    // Family & People
    'father': {'bn': 'পিতা', 'hi': 'पिता', 'or': 'ବାପା', 'en': 'Father'},
    'mother': {'bn': 'মাতা', 'hi': 'माता', 'or': 'ମାଆ', 'en': 'Mother'},
    'baba': {'bn': 'পিতা', 'hi': 'पिता', 'or': 'ବାପା', 'en': 'Father'},
    'ayo': {'bn': 'মাতা', 'hi': 'माता', 'or': 'ମାଆ', 'en': 'Mother'},
    'brother': {'bn': 'ভাই', 'hi': 'भाई', 'or': 'ଭାଇ', 'en': 'Brother'},
    'sister': {'bn': 'বোন', 'hi': 'बहन', 'or': 'ଭଉଣୀ', 'en': 'Sister'},
    'elder brother': {
      'bn': 'দাদা',
      'hi': 'बड़ा भाई',
      'or': 'ବଡ଼ ଭାଇ',
      'en': 'Elder brother',
    },
    'younger brother': {
      'bn': 'ছোট ভাই',
      'hi': 'छोटा भाई',
      'or': 'ସାନ ଭାଇ',
      'en': 'Younger brother',
    },
    'elder sister': {
      'bn': 'দিদি',
      'hi': 'बड़ी बहन',
      'or': 'ବଡ଼ ଭଉଣୀ',
      'en': 'Elder sister',
    },
    'younger sister': {
      'bn': 'ছোট বোন',
      'hi': 'छोटी बहन',
      'or': 'ସାନ ଭଉଣୀ',
      'en': 'Younger sister',
    },
    'grandfather': {
      'bn': 'দাদু',
      'hi': 'दादा',
      'or': 'ଜେଜେବାପା',
      'en': 'Grandfather',
    },
    'grandmother': {
      'bn': 'ঠাকুমা',
      'hi': 'दादी',
      'or': 'ଜେଜେମାଆ',
      'en': 'Grandmother',
    },
    'friend': {'bn': 'বন্ধু', 'hi': 'दोस्त', 'or': 'ସାଙ୍ଗ', 'en': 'Friend'},
    'child': {'bn': 'শিশু', 'hi': 'बच्चा', 'or': 'ପିଲା', 'en': 'Child'},
    'boy': {'bn': 'ছেলে', 'hi': 'लड़का', 'or': 'ପୁଅ', 'en': 'Boy'},
    'girl': {'bn': 'মেয়ে', 'hi': 'लड़की', 'or': 'ଝିଅ', 'en': 'Girl'},
    'man': {'bn': 'মানুষ', 'hi': 'आदमी', 'or': 'ଲୋକ', 'en': 'Man'},
    'woman': {'bn': 'মহিলা', 'hi': 'महिला', 'or': 'ମହିଳା', 'en': 'Woman'},

    // Greetings & Common Phrases
    'hello': {
      'bn': 'নমস্কার / জোহার',
      'hi': 'नमस्ते / जोहार',
      'or': 'ନମସ୍କାର / ଜୋହାର',
    },
    'greetings': {'bn': 'জোহার', 'hi': 'जोहार', 'or': 'ଜୋହାର'},
    'thank you': {'bn': 'ধন্যবাদ', 'hi': 'धन्यवाद', 'or': 'ଧନ୍ୟବାଦ'},
    'welcome': {'bn': 'স্বাগতম', 'hi': 'स्वागत है', 'or': 'ସ୍ୱାଗତ'},
    'goodbye': {'bn': 'বিদায়', 'hi': 'अलविदा', 'or': 'ବିଦାୟ'},
    'yes': {'bn': 'হ্যাঁ', 'hi': 'हाँ', 'or': 'ହଁ'},
    'no': {'bn': 'না', 'hi': 'नहीं', 'or': 'ନାହିଁ'},
    'what is your name?': {
      'bn': 'তোমার নাম কী?',
      'hi': 'तुम्हारा नाम क्या है?',
      'or': 'ତୁମର ନାମ କ’ଣ?',
    },
    'my name is': {'bn': 'আমার নাম', 'hi': 'मेरा नाम है', 'or': 'ମୋର ନାମ'},
    'where are you going?': {
      'bn': 'তুমি কোথায় যাচ্ছো?',
      'hi': 'तुम कहाँ जा रहे हो?',
      'or': 'ତୁମେ କୁଆଡ଼େ ଯାଉଛ?',
    },
    'i am hungry': {
      'bn': 'আমার খিদে পেয়েছে',
      'hi': 'मुझे भूख लगी है',
      'or': 'ମୋତେ ଭୋକ ଲାଗୁଛି',
    },
    'i am thirsty': {
      'bn': 'আমার তেষ্টা পেয়েছে',
      'hi': 'मुझे प्यास लगी है',
      'or': 'ମୋତେ ଶୋଷ ଲାଗୁଛି',
    },
    'how are you?': {
      'bn': 'তুমি কেমন আছো?',
      'hi': 'आप कैसे हैं?',
      'or': 'ତୁମେ କେମିତି ଅଛ?',
    },
    'i am fine': {
      'bn': 'আমি ভালো আছি',
      'hi': 'मैं ठीक हूँ',
      'or': 'ମୁଁ ଭଲ ଅଛି',
    },
    'come here': {'bn': 'এখানে এসো', 'hi': 'यहाँ आओ', 'or': 'ଏଠାକୁ ଆସ'},
    'go there': {'bn': 'সেখানে যাও', 'hi': 'वहाँ जाओ', 'or': 'ସେଠାକୁ ଯାଅ'},
    'sit down': {'bn': 'বসো', 'hi': 'बैठो', 'or': 'ବସ'},
    'stand up': {'bn': 'দাঁড়াও', 'hi': 'खड़े हो जाओ', 'or': 'ଠିଆ ହୁଅ'},
    'eat food': {'bn': 'খাবার খাও', 'hi': 'खाना खाओ', 'or': 'ଖାଦ୍ୟ ଖାଅ'},
    'drink water': {'bn': 'জল পান করো', 'hi': 'पानी पियो', 'or': 'ପାଣି ପିଅ'},

    // Nature & Daily Life
    'water': {'bn': 'জল', 'hi': 'पानी', 'or': 'ପାଣି'},
    'food': {'bn': 'খাবার', 'hi': 'खाना', 'or': 'ଖାଦ୍ୟ'},
    'rice': {'bn': 'ভাত', 'hi': 'चावल', 'or': 'ଭାତ'},
    'house': {'bn': 'বাড়ি', 'hi': 'ঘর', 'or': 'ଘର'},
    'tree': {'bn': 'গাছ', 'hi': 'पेड़', 'or': 'ଗଛ'},
    'flower': {'bn': 'ফুল', 'hi': 'फूल', 'or': 'ଫୁଲ'},
    'fruit': {'bn': 'ফল', 'hi': 'फल', 'or': 'ଫଳ'},
    'sun': {'bn': 'সূর্য', 'hi': 'सूरज', 'or': 'ସୂର୍ଯ୍ୟ'},
    'moon': {'bn': 'চাঁদ', 'hi': 'चाँद', 'or': 'ଚନ୍ଦ୍ର'},
    'star': {'bn': 'তারা', 'hi': 'तारा', 'or': 'ତାରା'},
    'sky': {'bn': 'আকাশ', 'hi': 'आकाश', 'or': 'ଆକାଶ'},
    'earth': {'bn': 'পৃথিবী', 'hi': 'धरती', 'or': 'ପୃଥିବୀ'},
    'river': {'bn': 'নদী', 'hi': 'नदी', 'or': 'ନଦୀ'},
    'mountain': {'bn': 'পাহাড়', 'hi': 'पहाड़', 'or': 'ପାହାଡ଼'},
    'forest': {'bn': 'জঙ্গল', 'hi': 'जंगल', 'or': 'ଜଙ୍ଗଲ'},
    'fire': {'bn': 'আগুন', 'hi': 'आग', 'or': 'ନିଆଁ'},
    'wind': {'bn': 'বাতাস', 'hi': 'हवा', 'or': 'ପବନ'},
    'rain': {'bn': 'বৃষ্টি', 'hi': 'बारिश', 'or': 'ବର୍ଷା'},
    'village': {'bn': 'গ্রাম', 'hi': 'गाँव', 'or': 'ଗାଁ'},
    'city': {'bn': 'শহর', 'hi': 'शहर', 'or': 'ସହର'},
    'school': {'bn': 'বিদ্যালয়', 'hi': 'विद्यालय', 'or': 'ବିଦ୍ୟାଳୟ'},
    'book': {'bn': 'বই', 'hi': 'किताब', 'or': 'ବହି'},
    'pen': {'bn': 'কলম', 'hi': 'कलम', 'or': 'କଲମ'},
    'road': {'bn': 'রাস্তা', 'hi': 'सड़क', 'or': 'ରାସ୍ତା'},
    'bird': {'bn': 'পাখি', 'hi': 'পक्षी', 'or': 'ଚଢ଼େଇ'},
    'animal': {'bn': 'পশু', 'hi': 'जानवर', 'or': 'ପଶୁ'},
    'dog': {'bn': 'কুকুর', 'hi': 'कुत्ता', 'or': 'କୁକୁର'},
    'cat': {'bn': 'বিড়াল', 'hi': 'बिल्ली', 'or': 'ବିଲେଇ'},
    'cow': {'bn': 'গরু', 'hi': 'गाय', 'or': 'ଗାଈ'},
    'tiger': {'bn': 'বাঘ', 'hi': 'बाघ', 'or': 'ବାଘ'},
    'elephant': {'bn': 'হাতি', 'hi': 'हाथी', 'or': 'ହାତୀ'},
    'fish': {'bn': 'মাছ', 'hi': 'मछली', 'or': 'ମାଛ'},

    // Body parts
    'head': {'bn': 'মাথা', 'hi': 'सिर', 'or': 'ମୁଣ୍ଡ'},
    'eye': {'bn': 'চোখ', 'hi': 'आँख', 'or': 'ଆଖି'},
    'ear': {'bn': 'কান', 'hi': 'कान', 'or': 'କାନ'},
    'nose': {'bn': 'নাক', 'hi': 'नाक', 'or': 'ନାକ'},
    'mouth': {'bn': 'মুখ', 'hi': 'मुँह', 'or': 'ପାଟି'},
    'hand': {'bn': 'হাত', 'hi': 'हाथ', 'or': 'ହାତ'},
    'leg': {'bn': 'পা', 'hi': 'पैर', 'or': 'ଗୋଡ଼'},
    'foot': {'bn': 'পা', 'hi': 'पैर', 'or': 'ପାଦ'},
    'finger': {'bn': 'আঙুল', 'hi': 'उँगली', 'or': 'ଆଙ୍ଗୁଠି'},
    'heart': {'bn': 'হৃদয়', 'hi': 'हृदय', 'or': 'ହୃଦୟ'},

    // Numbers
    'one': {'bn': 'এক (১)', 'hi': 'एक (१)', 'or': 'ଏକ (୧)'},
    'two': {'bn': 'দুই (২)', 'hi': 'दो (२)', 'or': 'ଦୁଇ (୨)'},
    'three': {'bn': 'তিন (৩)', 'hi': 'तीन (३)', 'or': 'ତିନି (୩)'},
    'four': {'bn': 'চার (৪)', 'hi': 'चार (४)', 'or': 'ଚାରି (୪)'},
    'five': {'bn': 'পাঁচ (৫)', 'hi': 'पाँच (५)', 'or': 'ପାଞ୍ଚ (୫)'},
    'six': {'bn': 'ছয় (৬)', 'hi': 'छह (६)', 'or': 'ଛଅ (୬)'},
    'seven': {'bn': 'সাত (৭)', 'hi': 'सात (७)', 'or': 'ସାତ (୭)'},
    'eight': {'bn': 'আট (৮)', 'hi': 'आठ (८)', 'or': 'ଆଠ (୮)'},
    'nine': {'bn': 'নয় (৯)', 'hi': 'नौ (९)', 'or': 'ନଅ (୯)'},
    'ten': {'bn': 'দশ (১০)', 'hi': 'दस (१०)', 'or': 'ଦଶ (୧୦)'},
  };

  // ──────────────────────────────────────────────────────────────────────────
  // 3. CORE TRANSLITERATION & TRANSLATION FUNCTIONS
  // ──────────────────────────────────────────────────────────────────────────

  /// Transliterates Ol Chiki text into [targetLang] script ('bn', 'hi', 'or', 'en')
  /// with intelligent Brahmic matra / vowel ligature processing.
  static String transliterateOlChiki(String olChikiText, String targetLang) {
    if (olChikiText.isEmpty) return '';

    final lang = targetLang.toLowerCase();
    if (lang == 'en' || lang == 'latin') {
      final buffer = StringBuffer();
      for (final char in olChikiText.characters) {
        buffer.write(_toLatinChar[char] ?? char);
      }
      return buffer.toString();
    }

    final Map<String, String> charMap;
    final Map<String, String> matraMap;

    switch (lang) {
      case 'bn':
      case 'bengali':
        charMap = _toBengaliChar;
        matraMap = _bengaliMatra;
        break;
      case 'hi':
      case 'hindi':
        charMap = _toHindiChar;
        matraMap = _hindiMatra;
        break;
      case 'or':
      case 'odia':
        charMap = _toOdiaChar;
        matraMap = _odiaMatra;
        break;
      default:
        charMap = _toLatinChar;
        matraMap = const {};
        break;
    }

    final buffer = StringBuffer();
    bool prevWasConsonant = false;

    for (final char in olChikiText.characters) {
      if (matraMap.isNotEmpty && _vowels.contains(char)) {
        if (prevWasConsonant) {
          buffer.write(matraMap[char] ?? charMap[char] ?? char);
        } else {
          buffer.write(charMap[char] ?? char);
        }
        prevWasConsonant = false;
      } else {
        buffer.write(charMap[char] ?? char);
        prevWasConsonant = _consonants.contains(char);
      }
    }
    return buffer.toString();
  }

  static String toBengali(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'bn');
  static String toHindi(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'hi');
  static String toOdia(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'or');
  static String toLatin(String olChikiText) =>
      transliterateOlChiki(olChikiText, 'en');

  /// Translates an English meaning into the learner's chosen [targetLang].
  static String translateMeaning(String englishMeaning, String targetLang) {
    final cleaned = englishMeaning.trim();
    if (cleaned.isEmpty) return '';
    if (targetLang == 'en' || targetLang == 'latin') return cleaned;

    final lower = cleaned.toLowerCase();
    // Direct match
    if (_glossTranslations.containsKey(lower)) {
      final transMap = _glossTranslations[lower]!;
      if (transMap.containsKey(targetLang)) return transMap[targetLang]!;
    }

    // Partial / prefix match for sentences or phrases
    for (final entry in _glossTranslations.entries) {
      if (lower == entry.key ||
          lower.startsWith('${entry.key} ') ||
          lower.contains(entry.key)) {
        if (entry.value.containsKey(targetLang)) {
          if (lower == entry.key) return entry.value[targetLang]!;
        }
      }
    }

    // Fallback: return English meaning if translation not in dictionary
    return cleaned;
  }

  /// Splits a composite string like "Baba – Father" or "In rengej ed inja – I am hungry"
  /// into Romanized Santali + English Meaning parts.
  static ({String phoneticLatin, String meaningEnglish}) parseCompositeLatin(
    String rawLatin,
  ) {
    final trimmed = rawLatin.trim();
    if (trimmed.isEmpty) return (phoneticLatin: '', meaningEnglish: '');

    // Check for standard separators: '–', '-', ':', '='
    final separators = [' – ', ' - ', ' — ', ': '];
    for (final sep in separators) {
      if (trimmed.contains(sep)) {
        final parts = trimmed.split(sep);
        if (parts.length >= 2) {
          final romanized = parts[0].trim();
          final meaning = parts.sublist(1).join(sep).trim();
          return (phoneticLatin: romanized, meaningEnglish: meaning);
        }
      }
    }

    // Lookup known single words if no separator
    final lower = trimmed.toLowerCase();
    if (_glossTranslations.containsKey(lower)) {
      final meaning =
          _glossTranslations[lower]?['en'] ??
          (trimmed[0].toUpperCase() + trimmed.substring(1));
      return (phoneticLatin: trimmed, meaningEnglish: meaning);
    }

    return (phoneticLatin: trimmed, meaningEnglish: '');
  }

  /// Master resolver that computes the presentation details for any lesson block, word, or sentence
  /// according to the learner's active [teachingLanguage] ('bn', 'hi', 'or', 'en', 'sat')
  /// and [scriptMode] ('both', 'olchiki', 'latin').
  static LocalizedItemDisplay resolveBlockDisplay({
    String? textOlChiki,
    String? textLatin,
    String? textBengali,
    String? textHindi,
    String? textOdia,
    String? explicitMeaning,
    String? explicitPronunciation,
    required String teachingLanguage,
    required String scriptMode,
  }) {
    final olChiki = (textOlChiki ?? '').trim();
    final latin = (textLatin ?? '').trim();

    // 1. Separate Romanized Santali and English Meaning from composite textLatin
    final parsed = parseCompositeLatin(latin);
    final englishMeaning = (explicitMeaning?.trim().isNotEmpty == true)
        ? explicitMeaning!.trim()
        : parsed.meaningEnglish;
    final romanizedSantali = parsed.phoneticLatin.isNotEmpty
        ? parsed.phoneticLatin
        : latin;

    // 2. Resolve Transliteration according to teaching language
    String transliteration;
    switch (teachingLanguage) {
      case 'bn':
        transliteration = (textBengali != null && textBengali.trim().isNotEmpty)
            ? textBengali.trim()
            : (olChiki.isNotEmpty
                  ? transliterateOlChiki(olChiki, 'bn')
                  : romanizedSantali);
        break;
      case 'hi':
        transliteration = (textHindi != null && textHindi.trim().isNotEmpty)
            ? textHindi.trim()
            : (olChiki.isNotEmpty
                  ? transliterateOlChiki(olChiki, 'hi')
                  : romanizedSantali);
        break;
      case 'or':
        transliteration = (textOdia != null && textOdia.trim().isNotEmpty)
            ? textOdia.trim()
            : (olChiki.isNotEmpty
                  ? transliterateOlChiki(olChiki, 'or')
                  : romanizedSantali);
        break;
      case 'sat':
        transliteration = '';
        break;
      case 'en':
      default:
        transliteration = romanizedSantali;
        break;
    }

    // 3. Resolve Localized Meaning
    final String localizedMeaning;
    if (teachingLanguage == 'sat') {
      localizedMeaning = '';
    } else {
      localizedMeaning = translateMeaning(englishMeaning, teachingLanguage);
    }

    // 4. Construct Subtitle (e.g. "বাবা – পিতা" or "Baba – Father")
    String subtitle;
    if (scriptMode == 'olchiki' || teachingLanguage == 'sat') {
      subtitle = '';
    } else if (transliteration.isNotEmpty && localizedMeaning.isNotEmpty) {
      subtitle = '$transliteration – $localizedMeaning';
    } else if (transliteration.isNotEmpty) {
      subtitle = transliteration;
    } else {
      subtitle = localizedMeaning;
    }

    // 5. Construct Clean Title (Hero/Header)
    final String title;
    if (localizedMeaning.isNotEmpty && teachingLanguage != 'sat') {
      title = localizedMeaning;
    } else if (transliteration.isNotEmpty) {
      title = transliteration;
    } else {
      title = olChiki;
    }

    // 6. Action Button CTA text
    final String ctaText;
    switch (teachingLanguage) {
      case 'bn':
        ctaText = 'শুনুন';
        break;
      case 'hi':
        ctaText = 'सुनें';
        break;
      case 'or':
        ctaText = 'ଶୁଣନ୍ତୁ';
        break;
      case 'sat':
        ctaText = 'ᱟᱸᱡᱚᱢ';
        break;
      case 'en':
      default:
        ctaText = 'LISTEN';
        break;
    }

    return LocalizedItemDisplay(
      scriptText: olChiki,
      transliteration: transliteration,
      meaning: localizedMeaning,
      subtitle: subtitle,
      title: title,
      ctaText: ctaText,
    );
  }
}
