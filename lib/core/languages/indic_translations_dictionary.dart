import 'indic_translations_lessons.dart';
import 'indic_translations_sentences.dart';
import 'indic_translations_stories.dart';
import 'indic_translations_words.dart';

/// Aggregated Indic translations dictionary covering Bengali (`bn`),
/// Hindi (`hi`), Odia (`or`), and English (`en`) for Santali learning content.
class IndicTranslationsDictionary {
  const IndicTranslationsDictionary._();

  static const Map<String, Map<String, String>> _vocabulary = {
    // Cultural Phrases & Wisdom
    'going on the cultural path is the honor of the santal people.': {
      'bn': 'সংস্কৃতির পথে চলা সাঁওতাল জাতির গৌরব।',
      'hi': 'संस्कृति के मार्ग पर चलना संताल समाज का गौरव है।',
      'or': 'ସଂସ୍କୃତିର ବାଟରେ ଚାଲିବା ସାନ୍ତାଳ ଜାତିର ଗୌରବ।',
      'en': 'Going on the cultural path is the honor of the Santal people.',
    },
    'going on the cultural path is the honor of the santal people': {
      'bn': 'সংস্কৃতির পথে চলা সাঁওতাল জাতির গৌরব।',
      'hi': 'संस्कृति के मार्ग पर चलना संताल समाज का गौरव है।',
      'or': 'ସଂସ୍କୃତିର ବାଟରେ ଚାଲିବା ସାନ୍ତାଳ ଜାତିର ଗୌରବ।',
      'en': 'Going on the cultural path is the honor of the Santal people.',
    },
    'living life with pure traditions is righteousness.': {
      'bn': 'পবিত্র পরম্পরা অনুসারে জীবনযাপন করাই প্রকৃত ধর্ম।',
      'hi': 'पवित्र परंपराओं के अनुसार जीवन जीना ही धर्म है।',
      'or': 'ପବିତ୍ର ପରମ୍ପରା ଅନୁଯାୟୀ ଜୀବନ ବିତାଇବା ହିଁ ଧର୍ମ।',
      'en': 'Living life with pure traditions is righteousness.',
    },
    'living life with pure traditions is righteousness': {
      'bn': 'পবিত্র পরম্পরা অনুসারে জীবনযাপন করাই প্রকৃত ধর্ম।',
      'hi': 'पवित्र परंपराओं के अनुसार जीवन जीना ही धर्म है।',
      'or': 'ପବିତ୍ର ପରମ୍ପରା ଅନୁଯାୟୀ ଜୀବନ ବିତାଇବା ହିଁ ଧର୍ମ।',
      'en': 'Living life with pure traditions is righteousness.',
    },
    'mind game / flirting': {
      'bn': 'মনের খেলা / প্রেমভাব',
      'hi': 'मन का खेल / छेड़खानी',
      'or': 'ମନର ଖେଳ / ପ୍ରେମଭାବ',
      'en': 'Mind game / Flirting',
    },
    'mind game': {
      'bn': 'মনের খেলা',
      'hi': 'मन का खेल',
      'or': 'ମନର ଖେଳ',
      'en': 'Mind game',
    },
    'flirting': {
      'bn': 'প্রেমভাব / দুষ্টুমি',
      'hi': 'छेड़खानी / प्रेमभाव',
      'or': 'ପ୍ରେମଭାବ / ଥଟ୍ଟା',
      'en': 'Flirting',
    },

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

    // Greetings & Daily Phrases
    'hello': {
      'bn': 'নমস্কার / জোহার',
      'hi': 'नमस्ते / जोहार',
      'or': 'ନମସ୍କାର / ଜୋହାର',
      'en': 'Hello',
    },
    'hello / greetings': {
      'bn': 'নমস্কার / জোহার',
      'hi': 'नमस्ते / जोहार',
      'or': 'ନମସ୍କାର / ଜୋହାର',
      'en': 'Hello / Greetings',
    },
    'greetings': {
      'bn': 'জোহার',
      'hi': 'जोहार',
      'or': 'ଜୋହାର',
      'en': 'Greetings',
    },
    'thank you': {
      'bn': 'ধন্যবাদ / সারহাও',
      'hi': 'धन्यवाद / सराहव',
      'or': 'ଧନ୍ୟବାଦ / ସାରହାଓ',
      'en': 'Thank you',
    },
    'welcome': {
      'bn': 'স্বাগতম',
      'hi': 'स्वागत है',
      'or': 'ସ୍ୱାଗତ',
      'en': 'Welcome',
    },
    'goodbye': {'bn': 'বিদায়', 'hi': 'अलविदा', 'or': 'ବିଦାୟ', 'en': 'Goodbye'},
    'good morning': {
      'bn': 'সুপ্রভাত',
      'hi': 'शुभ प्रभात',
      'or': 'ଶୁଭ ସକାଳ',
      'en': 'Good morning',
    },
    'good evening': {
      'bn': 'শুভ সন্ধ্যা',
      'hi': 'शुभ संध्या',
      'or': 'ଶୁଭ ସନ୍ଧ୍ୟା',
      'en': 'Good evening',
    },
    'good night': {
      'bn': 'শুভ রাত্রি',
      'hi': 'शुभ रात्रि',
      'or': 'ଶୁଭ ରାତ୍ରି',
      'en': 'Good night',
    },
    'yes': {'bn': 'হ্যাঁ', 'hi': 'हाँ', 'or': 'ହଁ', 'en': 'Yes'},
    'no': {'bn': 'না', 'hi': 'नहीं', 'or': 'ନାହିଁ', 'en': 'No'},

    // Nature, Daily Objects & Animals
    'water': {'bn': 'জল', 'hi': 'पानी', 'or': 'ପାଣି', 'en': 'Water'},
    'food': {'bn': 'খাবার', 'hi': 'खाना', 'or': 'ଖାଦ୍ୟ', 'en': 'Food'},
    'rice': {'bn': 'ভাত', 'hi': 'चावल', 'or': 'ଭାତ', 'en': 'Rice'},
    'house': {'bn': 'বাড়ি', 'hi': 'घर', 'or': 'ଘର', 'en': 'House'},
    'tree': {'bn': 'গাছ', 'hi': 'पेड़', 'or': 'ଗଛ', 'en': 'Tree'},
    'flower': {'bn': 'ফুল', 'hi': 'फूल', 'or': 'ଫୁଲ', 'en': 'Flower'},
    'fruit': {'bn': 'ফল', 'hi': 'फल', 'or': 'ଫଳ', 'en': 'Fruit'},
    'sun': {'bn': 'সূর্য', 'hi': 'सूरज', 'or': 'ସୂର୍ଯ୍ୟ', 'en': 'Sun'},
    'moon': {'bn': 'চাঁদ', 'hi': 'चाँद', 'or': 'ଚନ୍ଦ୍ର', 'en': 'Moon'},
    'star': {'bn': 'তারা', 'hi': 'तारा', 'or': 'ତାରା', 'en': 'Star'},
    'sky': {'bn': 'আকাশ', 'hi': 'आकाश', 'or': 'ଆକାଶ', 'en': 'Sky'},
    'earth': {'bn': 'পৃথিবী', 'hi': 'धरती', 'or': 'ପୃଥିବୀ', 'en': 'Earth'},
    'river': {'bn': 'নদী', 'hi': 'নদী', 'or': 'ନଦୀ', 'en': 'River'},
    'mountain': {
      'bn': 'পাহাড়',
      'hi': 'पहाड़',
      'or': 'ପାହାଡ଼',
      'en': 'Mountain',
    },
    'forest': {'bn': 'জঙ্গল', 'hi': 'जंगल', 'or': 'ଜଙ୍ଗଲ', 'en': 'Forest'},
    'fire': {'bn': 'আগুন', 'hi': 'आग', 'or': 'ନିଆଁ', 'en': 'Fire'},
    'wind': {'bn': 'বাতাস', 'hi': 'हवा', 'or': 'ପବନ', 'en': 'Wind'},
    'rain': {'bn': 'বৃষ্টি', 'hi': 'बारिश', 'or': 'ବର୍ଷା', 'en': 'Rain'},
    'village': {'bn': 'গ্রাম', 'hi': 'गाँव', 'or': 'ଗାଁ', 'en': 'Village'},
    'city': {'bn': 'শহর', 'hi': 'शहर', 'or': 'ସହର', 'en': 'City'},
    'school': {
      'bn': 'বিদ্যালয়',
      'hi': 'विद्यालय',
      'or': 'ବିଦ୍ୟାଳୟ',
      'en': 'School',
    },
    'book': {'bn': 'বই', 'hi': 'किताब', 'or': 'ବହି', 'en': 'Book'},
    'pen': {'bn': 'কলম', 'hi': 'कलम', 'or': 'କଲମ', 'en': 'Pen'},
    'road': {'bn': 'রাস্তা', 'hi': 'सड़क', 'or': 'ରାସ୍ତା', 'en': 'Road'},
    'bird': {'bn': 'পাখি', 'hi': 'पक्षी', 'or': 'ଚଢ଼େଇ', 'en': 'Bird'},
    'animal': {'bn': 'পশু', 'hi': 'जानवर', 'or': 'ପଶୁ', 'en': 'Animal'},
    'dog': {'bn': 'কুকুর', 'hi': 'कुत्ता', 'or': 'କୁକୁର', 'en': 'Dog'},
    'cat': {'bn': 'বিড়াল', 'hi': 'बिल्ली', 'or': 'ବିଲେଇ', 'en': 'Cat'},
    'cow': {'bn': 'গরু', 'hi': 'गाय', 'or': 'ଗାଈ', 'en': 'Cow'},
    'tiger': {'bn': 'বাঘ', 'hi': 'बाघ', 'or': 'ବାଘ', 'en': 'Tiger'},
    'elephant': {'bn': 'হাতি', 'hi': 'हाथी', 'or': 'ହାତୀ', 'en': 'Elephant'},
    'fish': {'bn': 'মাছ', 'hi': 'मछली', 'or': 'ମାଛ', 'en': 'Fish'},

    // Body Parts
    'head': {'bn': 'মাথা', 'hi': 'सिर', 'or': 'ମୁଣ୍ଡ', 'en': 'Head'},
    'eye': {'bn': 'চোখ', 'hi': 'आँख', 'or': 'ଆଖି', 'en': 'Eye'},
    'ear': {'bn': 'কান', 'hi': 'कान', 'or': 'କାନ', 'en': 'Ear'},
    'nose': {'bn': 'নাক', 'hi': 'नाक', 'or': 'ନାକ', 'en': 'Nose'},
    'mouth': {'bn': 'মুখ', 'hi': 'मुँह', 'or': 'ପାଟି', 'en': 'Mouth'},
    'hand': {'bn': 'হাত', 'hi': 'हाथ', 'or': 'ହାତ', 'en': 'Hand'},
    'leg': {'bn': 'পা', 'hi': 'पैर', 'or': 'ଗୋଡ଼', 'en': 'Leg'},
    'foot': {'bn': 'পা', 'hi': 'पैर', 'or': 'ପାଦ', 'en': 'Foot'},
    'finger': {'bn': 'আঙুল', 'hi': 'उँगली', 'or': 'ଆଙ୍ଗୁଠି', 'en': 'Finger'},
    'heart': {'bn': 'হৃদয়', 'hi': 'हृदय', 'or': 'ହୃଦୟ', 'en': 'Heart'},

    // Colors
    'red': {'bn': 'লাল', 'hi': 'लाल', 'or': 'ନାଲି', 'en': 'Red'},
    'green': {'bn': 'সবুজ', 'hi': 'हरा', 'or': 'ସବୁଜ', 'en': 'Green'},
    'blue': {'bn': 'নীল', 'hi': 'नीला', 'or': 'ନୀଳ', 'en': 'Blue'},
    'yellow': {'bn': 'হলুদ', 'hi': 'पीला', 'or': 'ହଳଦିଆ', 'en': 'Yellow'},
    'white': {'bn': 'সাদা', 'hi': 'सफ़ेद', 'or': 'ଧଳା', 'en': 'White'},
    'black': {'bn': 'কালো', 'hi': 'काला', 'or': 'କଳା', 'en': 'Black'},

    // Time & Days
    'today': {'bn': 'আজ', 'hi': 'आज', 'or': 'ଆଜି', 'en': 'Today'},
    'tomorrow': {
      'bn': 'আগামীকাল',
      'hi': 'कल (आने वाला)',
      'or': 'ଆସନ୍ତାକାଲି',
      'en': 'Tomorrow',
    },
    'yesterday': {
      'bn': 'গতকাল',
      'hi': 'कल (बीता हुआ)',
      'or': 'ଗତକାଲି',
      'en': 'Yesterday',
    },
    'morning': {'bn': 'সকাল', 'hi': 'सुबह', 'or': 'ସକାଳ', 'en': 'Morning'},
    'evening': {'bn': 'সন্ধ্যা', 'hi': 'शाम', 'or': 'ସନ୍ଧ୍ୟା', 'en': 'Evening'},
    'night': {'bn': 'রাত', 'hi': 'रात', 'or': 'ରାତି', 'en': 'Night'},

    // Numbers
    'one': {'bn': 'এক (১)', 'hi': 'एक (१)', 'or': 'ଏକ (୧)', 'en': 'One'},
    'two': {'bn': 'দুই (২)', 'hi': 'दो (२)', 'or': 'ଦୁଇ (୨)', 'en': 'Two'},
    'three': {
      'bn': 'তিন (৩)',
      'hi': 'तीन (३)',
      'or': 'ତିନି (୩)',
      'en': 'Three',
    },
    'four': {'bn': 'চার (৪)', 'hi': 'चार (४)', 'or': 'ଚାରି (୪)', 'en': 'Four'},
    'five': {
      'bn': 'পাঁচ (৫)',
      'hi': 'पाँच (५)',
      'or': 'ପାଞ୍ଚ (୫)',
      'en': 'Five',
    },
    'six': {'bn': 'ছয় (৬)', 'hi': 'छह (६)', 'or': 'ଛଅ (୬)', 'en': 'Six'},
    'seven': {'bn': 'সাত (৭)', 'hi': 'सात (७)', 'or': 'ସାତ (୭)', 'en': 'Seven'},
    'eight': {'bn': 'আট (৮)', 'hi': 'আठ (८)', 'or': 'ଆଠ (୮)', 'en': 'Eight'},
    'nine': {'bn': 'নয় (৯)', 'hi': 'नौ (९)', 'or': 'ନଅ (୯)', 'en': 'Nine'},
    'ten': {'bn': 'দশ (১০)', 'hi': 'दस (१०)', 'or': 'ଦଶ (୧୦)', 'en': 'Ten'},
  };

  /// Lookup translation from aggregated datasets.
  static String? lookup(String key, String targetLang) {
    final lower = key.toLowerCase().trim();
    if (lower.isEmpty) return null;

    // 1. Direct vocabulary
    if (_vocabulary.containsKey(lower) &&
        _vocabulary[lower]!.containsKey(targetLang)) {
      return _vocabulary[lower]![targetLang];
    }
    // 2. Sentences dataset
    if (IndicTranslationsSentences.translations.containsKey(lower) &&
        IndicTranslationsSentences.translations[lower]!.containsKey(
          targetLang,
        )) {
      return IndicTranslationsSentences.translations[lower]![targetLang];
    }
    // 3. Words dataset
    if (IndicTranslationsWords.translations.containsKey(lower) &&
        IndicTranslationsWords.translations[lower]!.containsKey(targetLang)) {
      return IndicTranslationsWords.translations[lower]![targetLang];
    }
    // 4. Lessons dataset
    if (IndicTranslationsLessons.translations.containsKey(lower) &&
        IndicTranslationsLessons.translations[lower]!.containsKey(targetLang)) {
      return IndicTranslationsLessons.translations[lower]![targetLang];
    }
    // 5. Stories dataset
    if (IndicTranslationsStories.translations.containsKey(lower) &&
        IndicTranslationsStories.translations[lower]!.containsKey(targetLang)) {
      return IndicTranslationsStories.translations[lower]![targetLang];
    }

    // 6. Fuzzy match: Strip trailing punctuation (?, ., !, ,)
    if (lower.endsWith('?') ||
        lower.endsWith('.') ||
        lower.endsWith('!') ||
        lower.endsWith(',')) {
      final stripped = lower.substring(0, lower.length - 1).trim();
      final sub = lookup(stripped, targetLang);
      if (sub != null && sub.isNotEmpty) {
        if (lower.endsWith('?') && !sub.endsWith('?') && !sub.endsWith('？')) {
          return '$sub?';
        }
        return sub;
      }
    }

    return null;
  }
}
