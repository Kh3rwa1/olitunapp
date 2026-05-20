import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class VocabSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
  ) async {
    final wordsNotifier = ref.read(wordsProvider.notifier);
    final lessonsNotifier = ref.read(lessonNotifierProvider.notifier);

    final actualVocabId = await addCategoryIfNew(
      const CategoryModel(
        id: 'cat_vocab',
        titleOlChiki: 'ᱨᱚᱲ',
        titleLatin: 'Vocabulary',
        iconName: 'words',
        gradientPreset: 'mint',
        order: 2,
        totalLessons: 14,
      ),
    );

    await wordsNotifier.seed();

    final vocabLessons = [
      {
        'id': 'lesson_vocab_basics',
        'titleLatin': 'Greetings & Basics',
        'titleOlChiki': 'ᱡᱚᱦᱟᱨ ᱟᱨ ᱢᱩᱞ ᱨᱚᱲ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱦᱟᱨ',
            textLatin: 'Johar – Hello / Greetings',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Sarhaw – Thank you',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ',
            textLatin: 'Hẽ – Yes',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱝ',
            textLatin: 'Bang – No',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
            textLatin: 'Sagun Daram – Welcome',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_family',
        'titleLatin': 'Family & Relationships',
        'titleOlChiki': 'ᱯᱟᱨᱤᱣᱟᱨ ᱟᱨ ᱥᱟᱹᱜᱟᱹᱭ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱵᱟ',
            textLatin: 'Baba – Father',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱭᱳ',
            textLatin: 'Ayo – Mother',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱳᱲᱟᱜ ᱦᱚᱲ',
            textLatin: 'Orag hor – Spouse / Family member',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱫᱟ',
            textLatin: 'Dada – Elder brother',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱹᱭ',
            textLatin: 'Dai – Elder sister',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱚᱠᱚᱧ',
            textLatin: 'Bokonj – Younger brother',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱤᱥᱮᱨᱟ',
            textLatin: 'Misera – Younger sister',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_daily',
        'titleLatin': 'Daily Use Words',
        'titleOlChiki': 'ᱫᱤᱱᱟᱹᱢ ᱵᱮᱵᱷᱟᱨ ᱨᱚᱲ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ',
            textLatin: 'Dag – Water',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱠᱟ',
            textLatin: 'Daka – Cooked Rice / Food',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱳᱲᱟᱜ',
            textLatin: 'Orag – Home / House',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱤᱪᱨᱤᱡ',
            textLatin: 'Kicrij – Cloth',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱨ',
            textLatin: 'Hor – Path / Road',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ',
            textLatin: 'Atu – Village',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱴᱟᱠᱟ',
            textLatin: 'Taka – Money',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_colors',
        'titleLatin': 'Colors',
        'titleOlChiki': 'ᱨᱚᱝ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱨᱟᱜ',
            textLatin: 'Arag – Red',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱥᱟᱝ',
            textLatin: 'Sasang – Yellow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱹᱨᱭᱟᱹᱲ',
            textLatin: 'Haryar – Green',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱩᱸᱰ',
            textLatin: 'Pund – White',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱱᱫᱮ',
            textLatin: 'Hende – Black',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱤᱞ',
            textLatin: 'Lil – Blue',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_nature',
        'titleLatin': 'Animals & Nature',
        'titleOlChiki': 'ᱡᱟᱱᱣᱟᱨ ᱟᱨ ᱠᱩᱫᱽᱨᱟᱹᱛ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱛᱟ',
            textLatin: 'Seta – Dog',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱩᱥᱤ',
            textLatin: 'Pusi – Cat',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱨᱳᱢ',
            textLatin: 'Merom – Goat',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱹᱭ',
            textLatin: 'Gai – Cow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱟᱹᱨᱩᱵ',
            textLatin: 'Tarub – Tiger',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱮᱬᱮ',
            textLatin: 'Cene – Bird',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱹᱠᱩ',
            textLatin: 'Haku – Fish',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ',
            textLatin: 'Dare – Tree',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ',
            textLatin: 'Baha – Flower',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_time',
        'titleLatin': 'Months, Days & Seasons',
        'titleOlChiki': 'ᱪᱟᱸᱫᱚ ᱟᱨ ᱨᱤᱛᱩ',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱟᱸᱫᱚ',
            textLatin: 'Chando – Month',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱦᱟ',
            textLatin: 'Maha – Day',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ',
            textLatin: 'Tehenj – Today',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱯᱟ',
            textLatin: 'Gapa – Tomorrow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱞᱟ',
            textLatin: 'Hola – Yesterday',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ',
            textLatin: 'Situng ritu – Summer',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ',
            textLatin: 'Dag ritu – Rainy Season',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_trending',
        'titleLatin': 'Trending & Popular Words',
        'titleOlChiki': 'ᱦᱟᱹᱞᱤ ᱨᱮᱭᱟᱜ ᱨᱚᱲ',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱟᱹᱨᱥᱤ',
            textLatin: 'Parsi – Language',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ',
            textLatin: 'Santali – Santali',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
            textLatin: 'Ol Chiki – Ol Chiki Script',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱩᱛᱷᱤ',
            textLatin: 'Puthi – Book',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
            textLatin: 'Itun asra – School',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ',
            textLatin: 'Disom – Country',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ',
            textLatin: 'Hor – People',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_idioms_beginner',
        'titleLatin': 'Simple Idioms & Daily Life',
        'titleOlChiki': 'ᱢᱩᱞ ᱵᱮᱱᱛᱟ ᱠᱟᱛᱷᱟ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱯᱚᱱ',
            textLatin: 'Hor hopon – Santal people',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ',
            textLatin: 'Sari katha – Truth / True words',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱨᱚᱲ',
            textLatin: 'Sibil ror – Gentle speech / Kind words',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱹᱢᱤ ᱜᱮ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Kami ge dhorom – Work is worship',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱩᱞᱟᱹᱲ',
            textLatin: 'Disom dular – Patriotism / Country love',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
            textLatin: 'Sagun daram – Warm welcome',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱷᱤᱨᱤ',
            textLatin: 'Dhiri – Stone',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱤᱛᱤᱞ',
            textLatin: 'Gitil – Sand',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱸᱜᱮᱞ',
            textLatin: 'Sengel – Fire',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ',
            textLatin: 'Hoy – Air / Wind',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱤᱢᱤᱞ',
            textLatin: 'Rimil – Cloud',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱯᱤᱞ',
            textLatin: 'Ipil – Star',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ',
            textLatin: 'Njida – Night',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱢᱟᱦᱟ',
            textLatin: 'Singe maha – Sunday',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱛ',
            textLatin: 'Ot – Earth / Ground',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ',
            textLatin: 'Serma – Sky / Year',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ',
            textLatin: 'Bir – Forest',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱩᱨᱩ',
            textLatin: 'Buru – Mountain / Hill',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱰᱟ',
            textLatin: 'Gada – River',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱷᱟᱨᱱᱟ',
            textLatin: 'Jharna – Spring / Waterfall',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱦᱟᱱ',
            textLatin: 'Sahan – Firewood',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_idioms_intermediate',
        'titleLatin': 'Folk Proverbs & Expressions',
        'titleOlChiki': 'ᱠᱩᱫᱩᱢ ᱟᱨ ᱥᱟᱹᱜᱟᱹᱭ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱞᱩᱴᱩᱨ ᱵᱮᱸᱜᱮᱫ',
            textLatin:
                'Med lutur benget – Keeping eyes and ears open / Vigilant',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱞᱟᱰᱮ',
            textLatin: 'Mone lade – Discouraged / Dejected',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱡᱟᱞᱟ',
            textLatin: 'Jiwi jala – Life struggles',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱩᱢᱩᱞ ᱦᱚᱲ ᱩᱢᱩᱞ',
            textLatin:
                'Dare umul hor umul – Protection of elders / Family shelter',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱛᱟ ᱡᱷᱟᱹᱞᱤ ᱞᱮᱠᱟ',
            textLatin: 'Seta jhale leka – Entangled in trouble / Trapped',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱᱢᱤ ᱡᱤᱣᱤ',
            textLatin: 'Manmi jiwi – Human life',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱ ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Man sarhaw – Respect and praise',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱜᱽᱬᱮ',
            textLatin: 'Lagne – Traditional Santal dance',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱚᱝ',
            textLatin: 'Dong – Marriage dance and song genre',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱩᱢᱫᱟᱜ',
            textLatin: 'Tumdag – Clay drum / Madal',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱴᱟᱢᱟᱠ',
            textLatin: 'Tamak – Kettle drum',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱱᱟᱢ',
            textLatin: 'Banam – Traditional single-stringed fiddle',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱤᱨᱭᱳ',
            textLatin: 'Tiryo – Bamboo flute',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱡᱚᱢ',
            textLatin: 'Sarjom – Sal tree (sacred to Santals)',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱛᱠᱟᱹᱢ',
            textLatin: 'Matkam – Mahua flower/fruit',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱦᱟᱨ ᱠᱟᱛᱷᱟ',
            textLatin: 'Johar katha – Welcoming words',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱞᱦᱤ',
            textLatin: 'Kulhi – Village street',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱛᱷᱟᱱ',
            textLatin: 'Jaher than – Sacred grove',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱛᱷᱟᱱ',
            textLatin: 'Manjhi than – Village headman\'s altar',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱦᱚᱲ',
            textLatin: 'Atu hor – Villagers',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱲᱟᱢ ᱵᱩᱰᱷᱤ',
            textLatin: 'Haram budhi – Ancestors / Old couple',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱠᱟ ᱩᱛᱩ',
            textLatin: 'Daka utu – Rice and curry / Meal',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_idioms_advanced',
        'titleLatin': 'Deep Wisdom & Philosophy',
        'titleOlChiki': 'ᱜᱟᱹᱦᱤᱨ ᱵᱮᱱᱛᱟ ᱠᱟᱛᱷᱟ',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱪᱩᱭᱞᱩ',
            textLatin: 'Luti chuylu – Sulking / Pouting in anger',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱩ ᱛᱮ ᱦᱚᱭ ᱚᱰᱚᱠ',
            textLatin: 'Mu te hoy odok – Snorting in rage / Proud',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱮ ᱡᱷᱟᱹᱞᱤ ᱵᱟᱹᱭᱥᱟᱹᱣ',
            textLatin:
                'Dag re jhale baysaw – Chasing shadows / Setting net in water',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱜᱮ ᱡᱤᱣᱤ',
            textLatin: 'Dare ge jiwi – Trees are life / Environmental wisdom',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱦᱚᱲ ᱫᱚ ᱵᱟᱹᱠᱩ ᱨᱚᱲᱟ',
            textLatin:
                'Goj hor do baku rora – Dead people do not speak / Let bygones be bygones',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱦᱚᱲ ᱜᱮ ᱫᱤᱥᱚᱢ ᱦᱚᱲ',
            textLatin:
                'Atu hor ge disom hor – Village community is the country\'s strength',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱠᱷᱚᱱ ᱫᱟᱜ ᱡᱚᱨᱚ',
            textLatin: 'Med khon dag joro – Weeping bitterly / Deep grief',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱵᱟᱹᱲᱤᱡ',
            textLatin: 'Mone barij – Feel sad / Heart-broken',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱠᱟᱛᱷᱟ',
            textLatin: 'Dular katha – Loving words / Kind speech',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱫᱷᱚᱱ',
            textLatin: 'Jiwi dhon – Wealth of life / Beloved',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ',
            textLatin: 'Disom daran – Traveling / Exploring the land',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱷᱚᱨᱚᱢ ᱠᱟᱹᱢᱤ',
            textLatin: 'Dhorom kami – Righteous deed / Virtuous work',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ',
            textLatin: 'Sohrae porob – Harvest festival / Sohrae',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵ',
            textLatin: 'Baha porob – Spring festival / Flower festival',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ',
            textLatin: 'Santali sawhet – Santali literature',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ',
            textLatin: 'Guru kolom – The pen of the Guru / Education',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ',
            textLatin: 'Olog parhaw – Education / Learning',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱮᱭᱟᱱ ᱦᱚᱨ',
            textLatin: 'Geyan hor – Path of knowledge',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ',
            textLatin: 'Lakchar – Culture',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ',
            textLatin: 'Ari chali – Customs and traditions',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱲᱮᱢ ᱨᱚᱲ',
            textLatin: 'Herem ror – Sweet words / Fluent speech',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ',
            textLatin: 'Sirjoniya – Creator / Nature',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_conversational_1',
        'titleLatin': 'Modern Conversational Idioms',
        'titleOlChiki': 'ᱦᱟᱹᱞᱤ ᱨᱚᱲ ᱵᱮᱱᱛᱟ ᱠᱟᱛᱷᱟ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱷᱮᱞ',
            textLatin: 'Mone khel – Mind game / Flirting',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱛᱮ ᱞᱟᱸᱫᱟ',
            textLatin: 'Ror te landa – Smiling through words / Sarcasm',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱡᱟᱹᱞᱤ',
            textLatin: 'Dular jhale – Love trap',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱥᱟᱢᱟᱝ',
            textLatin: 'Hor samang – Public / In front of people',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱞᱟᱲᱟᱣ',
            textLatin: 'Luti laraw – Chatting / Gossip',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱛᱷᱟ ᱠᱤᱨᱤᱧ',
            textLatin: 'Katha kirinj – Buying words / Accepting advice',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱞᱚ',
            textLatin: 'Jiwi lo – Heartburn / Jealousy',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱚᱞ',
            textLatin: 'Mone ol – Writing on heart / Deeply remembering',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱫᱟᱜ',
            textLatin: 'Med dag – Tears',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ ᱛᱮ ᱜᱚᱡ',
            textLatin: 'Landa te goj – Dying of laughter',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱲᱤ ᱦᱚᱯᱚᱱ',
            textLatin: 'Kuri hopon – Women / Girls',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱚᱲᱟ ᱦᱚᱯᱚᱱ',
            textLatin: 'Kora hopon – Men / Boys',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ ᱠᱩᱲᱤ',
            textLatin: 'Gate kuri – Female friend',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ ᱠᱚᱲᱟ',
            textLatin: 'Gate kora – Male friend',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱯᱩᱛᱤ ᱠᱟᱛᱷᱟ',
            textLatin: 'Guputi katha – Secret talk / Whisper',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱟᱹᱥᱠᱟᱹ ᱢᱚᱱᱮ',
            textLatin: 'Raska mone – Joyful mind / Happy heart',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱠᱷ ᱡᱤᱣᱤ',
            textLatin: 'Dukh jiwi – Sorrowful life',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱢᱚᱱᱮ',
            textLatin: 'Hor mone – Public opinion / Human heart',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱡᱚᱢ',
            textLatin: 'Sibil jom – Delicious food',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱲᱮ ᱩᱫᱩᱜ',
            textLatin: 'Dare udug – Show of strength',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱴᱷᱟᱶ',
            textLatin: 'Mone thaw – Settled mind / Contentment',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱞᱟᱹᱱᱟᱹᱭ',
            textLatin: 'Ror lanay – Reply / Answer',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱠᱟᱹᱢᱤ',
            textLatin: 'Dinam kami – Daily chore',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱤᱱ',
            textLatin: 'Sagun din – Auspicious day',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ',
            textLatin: 'Sari mone – Honest heart',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_conversational_2',
        'titleLatin': 'Casual Idioms & Social Slang',
        'titleOlChiki': 'ᱫᱤᱱᱟᱹᱢ ᱵᱮᱵᱷᱟᱨ ᱵᱮᱱᱛᱟ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱞᱩᱞᱩ',
            textLatin: 'Med lulu – Staring blankly / Daydreaming',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱩᱨ ᱠᱷᱟᱲᱟ',
            textLatin: 'Lutur khara – Pricking ears / Listening intently',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱛᱷᱟ ᱨᱟᱹᱯᱩᱫ',
            textLatin: 'Katha rapud – Breaking words / Interrupting',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱦᱟᱹᱴᱤᱧ',
            textLatin: 'Mone hatinj – Sharing feelings / Divided mind',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱡᱩᱞ',
            textLatin: 'Jiwi jul – Burning life / Passionate / Angry',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ ᱛᱷᱚᱠ',
            textLatin: 'Landa thok – Weary of laughing',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱪᱮᱦᱨᱟ',
            textLatin: 'Ror chehra – Beautiful speech',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱫᱟᱲᱮ',
            textLatin: 'Mone dare – Willpower / Mental strength',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱟᱹᱭ ᱛᱚᱞ',
            textLatin: 'Sagay tol – Binding relationship / Making friends',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱛᱷᱟ ᱛᱚᱞ',
            textLatin: 'Katha tol – Finalizing a promise',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱨᱟᱲᱟ',
            textLatin: 'Mone rara – Relieved / Free mind',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱛᱟᱦᱮᱸᱱ',
            textLatin: 'Jiwi tahen – Staying alive / Living well',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱜᱟᱛᱮ',
            textLatin: 'Dular gate – Sweetheart / Dear friend',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱨ',
            textLatin: 'Hor hor – Human path / Way of life',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Sari sarhaw – True appreciation',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱞᱟᱹᱰᱩ',
            textLatin: 'Ror ladu – Sweet talks / Flattery',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱟᱹᱭ',
            textLatin: 'Mone kay – Sin of the heart / Guilty conscience',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱦᱟᱹᱞᱤ',
            textLatin: 'Jiwi hali – Lively spirit / Fresh energy',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱹᱢᱤ ᱞᱟᱹᱜᱤᱫ',
            textLatin: 'Kami lagid – Ready to work',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱲ',
            textLatin: 'Santali ror – Speaking Santali',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱩᱭᱦᱟᱹᱨ',
            textLatin: 'Mone uyhar – Thoughts of the heart',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱫᱟᱠᱟ',
            textLatin: 'Dinam daka – Daily bread',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱮᱞ',
            textLatin: 'Sagun njel – Good vision / Omen',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱫᱟᱲᱮ',
            textLatin: 'Hor dare – Collective human strength',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Sari dhorom – True religion / Path of truth',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_folk_1',
        'titleLatin': 'Folk Proverbs & Tribal Wisdom I',
        'titleOlChiki': 'ᱠᱩᱫᱩᱢ ᱟᱨ ᱟᱹᱛᱩ ᱦᱚᱨ ᱜᱮᱭᱟᱱ ᱢᱟᱹᱦᱤᱛ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱜᱮ ᱫᱷᱚᱱ',
            textLatin: 'Dare ge dhon – Forest is wealth',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱨᱚᱲ ᱵᱩᱨᱩ ᱨᱚᱲ',
            textLatin: 'Hor ror buru ror – Man\'s word is as firm as the hill',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱮ ᱡᱟᱱᱟᱢ',
            textLatin: 'Dag re janam – Born in water / Pure spirit',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱦᱚᱲᱢᱚ',
            textLatin: 'Hasa hormo – Clay body / Mortal self',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱸᱜᱮᱞ ᱡᱤᱣᱤ',
            textLatin: 'Sengel jiwi – Fiery soul / Passionate spirit',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ ᱞᱮᱠᱟ ᱫᱟᱹᱲ',
            textLatin: 'Hoy leka dar – Running like the wind / Fleet-footed',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱩᱢᱩᱞ',
            textLatin: 'Bir umul – Shade of the forest / Nature\'s protection',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱥᱟᱠᱟᱢ',
            textLatin: 'Dare sakam – Tree leaves / Herbal cure',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱡᱟᱹᱞᱤ',
            textLatin: 'Jiwi jhale – Snare of life / Interconnected existence',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱥᱮᱨᱢᱟ',
            textLatin: 'Sari serma – True heavens / Cosmic order',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱫᱩᱢ ᱠᱟᱛᱷᱟ',
            textLatin: 'Kudum katha – Riddle talk / Figurative expression',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱮᱱᱛᱟ ᱨᱚᱲ',
            textLatin: 'Benta ror – Idiomatic speech / Indirect speech',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱲᱟᱢ ᱠᱟᱛᱷᱟ',
            textLatin: 'Haram katha – Ancestral wisdom / Sayings of elders',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱩᱰᱷᱤ ᱩᱭᱦᱟᱹᱨ',
            textLatin: 'Budhi uyhar – Wise grandmother\'s advice',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱟᱹᱨᱤ',
            textLatin: 'Atu ari – Custom of the village',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ ᱫᱟᱲᱮ',
            textLatin: 'Jumid dare – Strength in unity',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱥᱮᱨᱮᱧ',
            textLatin: 'Sohrae serenj – Traditional Sohrae harvest songs',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱥᱟᱠᱟᱢ',
            textLatin: 'Baha sakam – Flower petals / Sacred offerings',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱩᱢᱩᱞ',
            textLatin: 'Jaher umul – Protection of the sacred grove',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱵᱤᱪᱟᱹᱨ',
            textLatin: 'Manjhi bicar – Headman\'s judgment / Local justice',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Hor dhorom – The way of the Santal / Righteousness',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ',
            textLatin: 'Sirjon dular – Love for nature',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱛ ᱦᱟᱥᱟ',
            textLatin: 'Ot hasa – Land and soil / Motherland',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱡᱟᱱᱣᱟᱨ',
            textLatin: 'Bir janwar – Wild beasts / Forest fauna',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱟᱠᱟᱢ',
            textLatin: 'Sagun sakam – Auspicious leaf / Sacred message',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱᱢᱤ ᱜᱮᱭᱟᱱ',
            textLatin: 'Manmi geyan – Human wisdom',
          ),
        ],
      },
      {
        'id': 'lesson_vocab_folk_2',
        'titleLatin': 'Folk Proverbs & Tribal Wisdom II',
        'titleOlChiki': 'ᱫᱤᱥᱚᱢ ᱦᱟᱲᱟᱢ ᱵᱮᱱᱛᱟ ᱠᱟᱛᱷᱟ',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱜᱤᱰᱤ',
            textLatin: 'Goj gidi – Discarded / Dead and thrown / Forgotten',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱛᱚᱞ',
            textLatin: 'Jiwi tol – Mind bound / Dedication / Vow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱛᱷᱟᱹᱭ',
            textLatin: 'Mone thay – Firm decision',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱡᱚᱢ',
            textLatin: 'Luti jom – Eating through lips / False promises',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱩ ᱛᱮ ᱨᱟᱠᱟᱵ',
            textLatin: 'Mu te rakab – Boiling with anger / Nostril rage',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱫᱷᱤᱨᱤ',
            textLatin: 'Dag dhiri – Wet stone / Indifferent person',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱫᱟᱨᱮ',
            textLatin: 'Bir dare – Forest trees / Native strength',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱚᱲᱟᱜ',
            textLatin: 'Hasa orag – Mud house / Humble dwelling',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ ᱤᱯᱤᱞ',
            textLatin: 'Serma ipil – Heavenly stars / Guide',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ ᱩᱢᱩᱞ',
            textLatin: 'Njida umul – Night shadow / Mysterious',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱥᱤᱛᱩᱝ',
            textLatin: 'Singe situng – Scorching midday sun',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱤᱢᱤᱞ ᱫᱟᱜ',
            textLatin: 'Rimil dag – Cloud rain / Dynamic blessing',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱨᱢᱚ',
            textLatin: 'Hor hormo – Santal body / Earthly vessel',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱥᱟᱹᱜᱟᱹᱭ',
            textLatin:
                'Sibil sagay – Sweet relationship / Affectionate bonding',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱮᱴᱮᱡ',
            textLatin: 'Mone ketej – Strong mind / Brave heart',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱨᱟᱲᱟ',
            textLatin: 'Jiwi rara – Soul liberation / Ultimate peace',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱜᱟᱹᱰᱤ',
            textLatin: 'Dular gadi – River of love',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱜᱩᱨᱩ',
            textLatin: 'Sari guru – True teacher / Master',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱮᱭᱟᱱ ᱫᱚᱨᱭᱟ',
            textLatin: 'Geyan dorya – Ocean of knowledge',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ ᱦᱚᱨ',
            textLatin: 'Lakchar hor – Cultural path',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱥᱟᱹᱨᱤ',
            textLatin: 'Ari sari – Pure traditions / Absolute truth',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱶᱦᱮᱫ ᱡᱤᱣᱤ',
            textLatin: 'Sawhet jiwi – Soul of literature',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Sirjon dhorom – Religion of nature',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱲᱮ',
            textLatin: 'Disom dare – Power of the land',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱩᱛᱩᱢ',
            textLatin: 'Sagun nyutum – Good name / Renown',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱᱢᱤ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Manmi dhorom – Humanity / Service to mankind',
          ),
        ],
      },
    ];

    for (int i = 0; i < vocabLessons.length; i++) {
      final lesson = vocabLessons[i];
      await lessonsNotifier.addLesson(
        LessonModel(
          id: lesson['id'] as String,
          categoryId: actualVocabId,
          titleOlChiki: lesson['titleOlChiki'] as String,
          titleLatin: lesson['titleLatin'] as String,
          level: lesson['level'] as String? ?? 'beginner',
          order: i,
          blocks: lesson['blocks'] as List<LessonBlockModel>,
        ),
      );
    }

    return actualVocabId;
  }
}
