import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class SentenceSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
    Future<void> Function(LessonModel) addLessonIfNew,
  ) async {
    final sentencesNotifier = ref.read(sentencesProvider.notifier);

    final actualSentencesId = await addCategoryIfNew(
      const CategoryModel(
        id: 'cat_sentences',
        titleOlChiki: 'ᱣᱟᱠᱭ',
        titleLatin: 'Sentences',
        iconName: 'sentences',
        gradientPreset: 'ocean',
        order: 3,
        totalLessons: 13,
      ),
    );

    await sentencesNotifier.seed();

    final sentenceLessons = [
      {
        'id': 'lesson_sentences_basics',
        'titleLatin': 'Basic Sentences',
        'titleOlChiki': 'ᱢᱩᱞ ᱣᱟᱠᱭ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
            textLatin: 'Amaak nyutum ced? – What is your name?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ',
            textLatin: 'Injaak nyutum do Santhal – My name is Santhal',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱛᱮᱢ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
            textLatin: 'Am do okatem chalag kana? – Where are you going?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱨᱮᱢ ᱛᱟᱦᱮᱸᱱᱟ?',
            textLatin: 'Am do okarem tahena? – Where do you live?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱚᱸᱰᱮᱧ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin: 'In do nondenj tahena – I live here',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin: 'Inj donj chalag kana – I am going',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱭ ᱠᱟᱱᱟᱢ?',
            textLatin: 'Am do okoy kanam? – Who are you?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱤᱧᱤᱡ ᱵᱚᱠᱚᱧ ᱠᱟᱱᱟᱭ',
            textLatin: 'Uni do injij bokonj kanay – He is my younger brother',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱩᱭ ᱫᱚ ᱤᱧᱤᱡ ᱜᱟᱛᱮ ᱠᱟᱱᱟᱭ',
            textLatin: 'Nuy do injij gate kanay – This is my friend',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟ ᱠᱷᱚᱱ ᱮᱢ ᱦᱮᱡ ᱮᱱᱟ?',
            textLatin: 'Am do oka khon em hej ena? – Where did you come from?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱟᱹᱛᱩ ᱠᱷᱚᱱ ᱤᱧ ᱦᱮᱡ ᱮᱱᱟ',
            textLatin: 'Inj do atu khon inj hej ena – I came from the village',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?',
            textLatin: 'Nowa do ced kana? – What is this?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱫᱟᱨᱮ ᱠᱟᱱᱟ',
            textLatin: 'Nowa do dare kana – This is a tree',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin: 'Am do ced em kusiyaga? – What do you like?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱲ ᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
            textLatin:
                'Inj do Santali ror inj kusiyaga – I like speaking Santali',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱟᱢ?',
            textLatin: 'Am do kamiyam? – Do you work?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱟᱹᱧ',
            textLatin: 'Hẽ, inj do kamiyanj – Yes, I work',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱭᱟ?',
            textLatin: 'Uni do okare menaya? – Where is he/she?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱚᱲᱟᱜ ᱨᱮ ᱢᱮᱱᱟᱭᱟ',
            textLatin: 'Uni do orag re menaya – He/she is at home',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱧᱮᱞᱮᱫ ᱟᱧᱟᱢ?',
            textLatin: 'Am do nyeled anyam? – Do you see me?',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_conversations',
        'titleLatin': 'Daily Conversations',
        'titleOlChiki': 'ᱫᱤᱱᱟᱹᱢ ᱜᱟᱞᱢᱟᱨᱟᱣ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
            textLatin: 'In rengej ed inja – I am hungry',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
            textLatin: 'Daka jom me – Please eat food',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱧᱩ ᱢᱮ',
            textLatin: 'Dag nju me – Please drink water',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟᱧ',
            textLatin: 'In parhaag kananj – I am studying',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?',
            textLatin: 'Am ced em cikayeda? – What are you doing?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱧ',
            textLatin: 'In do kamiyedanj – I am working',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱛᱩᱢᱫᱟᱜ ᱨᱩ ᱮᱢ ᱵᱟᱰᱟᱭᱟ?',
            textLatin:
                'Am tumdag ru em badaya? – Do you know how to play the drum?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱹᱧ ᱵᱟᱰᱟᱭᱟ',
            textLatin: 'Banj badaya – I do not know',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱪᱮᱫ ᱟᱹᱧ ᱢᱮ',
            textLatin: 'Daya kate chet anj me – Please teach me',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱜᱟᱯᱟᱧ ᱪᱮᱫ ᱟᱢᱟ',
            textLatin: 'Hẽ, gapanj chet ama – Yes, I will teach you tomorrow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹ ᱫᱤᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do adi raska din kana – Today is a very joyful day',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ',
            textLatin: 'Ale orag te hijug me – Come to our house',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱜᱟᱯᱟ ᱱᱩ ᱦᱤᱡᱩᱜᱼᱟ',
            textLatin: 'Inj do gapa nu hijuga – I will come tomorrow',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱞ ᱪᱤᱠᱤ ᱯᱩᱛᱷᱤ ᱮᱢᱟᱧ ᱢᱮ',
            textLatin:
                'Amaak Ol Chiki puthi emanj me – Give me your Ol Chiki book',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱤᱧᱟᱜ ᱯᱩᱛᱷᱤ ᱠᱟᱱᱟ',
            textLatin: 'Nowa do injaak puthi kana – This is my book',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱤᱨᱭᱳ ᱚᱨᱚᱝ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin:
                'Am do tiryo orong em kusiyaga? – Do you like blowing the flute?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱛᱤᱨᱭᱳ ᱚᱨᱚᱝ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱵᱤᱞ ᱜᱮᱭᱟ',
            textLatin:
                'Hẽ, tiryo orong do adi sibil geya – Yes, blowing the flute is very sweet',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱞᱟᱸᱫᱟᱭᱮᱫᱟᱢ ᱪᱮᱫᱟᱜ?',
            textLatin: 'Am do landayedam cedag? – Why are you laughing?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱨᱟᱹᱥᱠᱟᱹ ᱮᱱᱟᱧ ᱚᱱᱟᱛᱮ',
            textLatin: 'Inj do raska enanj onate – I became happy, that\'s why',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ, ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱟ',
            textLatin: 'Gate, gapa bon njapama – Friend, we will meet tomorrow',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_polite',
        'titleLatin': 'Greetings & Politeness',
        'titleOlChiki': 'ᱡᱚᱦᱟᱨ ᱟᱨ ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱪᱮᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
            textLatin: 'Am celeka menama? – Hello, how are you?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱱᱟᱯᱟᱭ ᱜᱮ ᱢᱮᱱᱟᱧᱟ',
            textLatin: 'In napay ge menanja – I am fine',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
            textLatin: 'Sagun setag – Good morning',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ',
            textLatin: 'Sagun njida – Good night',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
            textLatin: 'Ika kanj me – Excuse me / Sorry',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
            textLatin: 'Napay te tahen me – Take care',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱩᱲᱩᱵ ᱢᱮ',
            textLatin: 'Daya kate durub me – Please sit down',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ, ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ',
            textLatin:
                'Sagun daram, orag te hijug me – Welcome, come inside the house',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱟᱹᱰᱤᱧ ᱨᱟᱹᱥᱠᱟᱹ ᱮᱱᱟ',
            textLatin:
                'Am njapam kate adinj raska ena – I am very happy to meet you',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱰᱤ ᱟᱹᱰᱤ ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Adi adi sarhaw – Thank you very much',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱚᱢ ᱵᱷᱟᱵᱽᱱᱟᱜᱼᱟ, ᱥᱟᱱᱟᱢ ᱱᱟᱯᱟᱭ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Alom bhabnaga, sanam napay huyuga – Don\'t worry, everything will be fine',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱚᱶᱟ ᱠᱟᱹᱢᱤ ᱟᱹᱧ ᱢᱮ',
            textLatin:
                'Daya kate nowa kami anj me – Please help me with this work',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱹᱥᱤᱥ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin: 'Amaak asis dohoy me – Keep your blessings',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱟᱢ ᱥᱟᱨᱦᱟᱣ ᱮᱫ ᱢᱮᱭᱟᱧ',
            textLatin: 'Inj do am sarhaw ed meyaj – I appreciate you',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱨᱚᱲ ᱢᱮ',
            textLatin: 'Daya kate ror me – Please speak',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱥᱮᱱᱚᱜ ᱢᱮ',
            textLatin: 'Napay te senog me – Go safely',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱨᱟᱝ ᱦᱚᱲ ᱠᱚ ᱢᱟᱱ ᱮᱢᱟ ᱠᱚ ᱢᱮ',
            textLatin:
                'Marang hor ko man ema ko me – Give respect to the elders',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱨᱚᱲ ᱛᱮ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱢᱮ',
            textLatin:
                'Sibil ror te galmaraw me – Speak with gentle/sweet words',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱡᱚᱦᱟᱨ ᱦᱟᱛᱟᱣ ᱢᱮ',
            textLatin: 'Injaak johar hataw me – Accept my greetings',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱟᱹᱭᱩᱵ, ᱜᱟᱛᱮ ᱠᱚ',
            textLatin: 'Sagun ayub, gate ko – Good evening, friends',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_time_weather',
        'titleLatin': 'Time & Weather',
        'titleOlChiki': 'ᱚᱠᱛᱚ ᱟᱨ ᱦᱚᱭ ᱦᱤᱥᱤᱫ',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱫᱤᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do adi napay din kana – Today is a beautiful day',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱛᱤᱱᱟᱹᱜ ᱫᱟᱢ ᱠᱟᱱᱟ?',
            textLatin: 'Nowa do tinag dam kana? – How much is this?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱮ ᱡᱟᱹᱲᱤᱭᱮᱫᱟ',
            textLatin: 'Dag e jariyeda – It is raining',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱛᱩᱝ ᱠᱟᱱᱟ',
            textLatin: 'Tehenj do adi situng kana – It is very hot today',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱤᱱᱟᱹᱜ ᱵᱟᱡᱟᱣ ᱮᱱᱟ?',
            textLatin: 'Tinag bajaw ena? – What time is it?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱤᱛᱚᱜ ᱫᱚ ᱥᱮᱛᱟᱜ ᱟᱠᱟᱱᱟ',
            textLatin: 'Nitog do setag akana – Now it is morning',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱯᱟ ᱫᱚ ᱨᱟᱵᱟᱝ ᱨᱤᱛᱩ ᱮᱦᱚᱵᱚᱜᱼᱟ',
            textLatin:
                'Gapa do rabang ritu ehoboga – Tomorrow winter season starts',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱧᱤᱫᱟᱹ ᱫᱚ ᱟᱹᱰᱤ ᱨᱟᱵᱟᱝ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj njida do adi rabang kana – Tonight it is very cold',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱢᱟ ᱨᱮ ᱨᱤᱢᱤᱞ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin: 'Sirma re rimil menaga – There are clouds in the sky',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ ᱟᱹᱰᱤ ᱡᱩᱨ ᱛᱮ ᱦᱤᱥᱤᱫ ᱠᱟᱱᱟ',
            textLatin:
                'Hoy adi jur te hisid kana – The wind is blowing very hard',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱚᱠᱟ ᱢᱟᱦᱟ ᱠᱟᱱᱟ?',
            textLatin: 'Tehenj do oka maha kana? – What day is today?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱥᱟᱹᱜᱩᱱ ᱢᱟᱦᱟ ᱠᱟᱱᱟ',
            textLatin: 'Tehenj do Sagun maha kana – Today is Wednesday',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱟᱸᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱯᱷᱟ ᱜᱮᱭᱟ',
            textLatin: 'Chando adi sapha geya – The moon is very clear',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ ᱨᱮ ᱫᱟᱜ ᱛᱮᱛᱟᱝ ᱮᱫ ᱤᱧᱟ',
            textLatin:
                'Situng ritu re dag tetang ed inja – In the summer season, I feel thirsty',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ ᱨᱮ ᱫᱟᱨᱮ ᱠᱚ ᱦᱟᱹᱨᱭᱟᱹᱲᱚᱜᱼᱟ',
            textLatin:
                'Dag ritu re dare ko haryaroga – In the rainy season, the trees turn green',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱞᱟ ᱫᱚ ᱟᱹᱰᱤ ᱡᱩᱨ ᱮ ᱫᱟᱜ ᱠᱮᱫᱟ',
            textLatin:
                'Hola do adi jur e dag keda – Yesterday it rained heavily',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱥᱮᱨᱢᱟ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱜᱮᱭᱟ',
            textLatin: 'Nowa serma do adi napay geya – This year is very good',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱴᱤᱠᱤᱱ ᱚᱠᱛᱚ ᱠᱟᱱᱟ',
            textLatin: 'Tehenj do tikin okto kana – Today it is noon time',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱭᱩᱵ ᱚᱠᱛᱚ ᱨᱮ ᱜᱟᱛᱮ ᱠᱚ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱢᱮ',
            textLatin:
                'Ayub okto re gate ko saw njapam me – Meet with friends in the evening time',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱠᱛᱚ ᱫᱚ ᱟᱹᱰᱤ ᱫᱟᱢᱟᱱ ᱜᱮᱭᱟ',
            textLatin: 'Okto do adi daman geya – Time is very precious',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_complex_beginner',
        'titleLatin': 'Simple Dialogues & Routines',
        'titleOlChiki': 'ᱢᱩᱞ ᱜᱟᱞᱢᱟᱨᱟᱣ',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ ᱵᱟᱵᱟ, ᱟᱢ ᱪᱮᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
            textLatin:
                'Sagun setag baba, am celeka menama? – Good morning father, how are you?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱟᱯᱟᱭ ᱜᱮ ᱢᱮᱱᱟᱧᱟ, ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?',
            textLatin:
                'In do napay ge menanja, am ced em cikayeda? – I am doing well, what are you doing?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱚᱞ ᱪᱤᱠᱤ ᱯᱟᱹᱨᱥᱤᱧ ᱪᱮᱫᱚᱜ ᱠᱟᱱᱟ',
            textLatin:
                'In do Ol Chiki parsin chedog kana – I am learning the Ol Chiki language.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱠᱟᱛᱷᱟ ᱠᱟᱱᱟ, ᱥᱟᱨᱦᱟᱣ',
            textLatin:
                'Nowa do adi napay katha kana, sarhaw – This is very good news, thank you!',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱲᱟᱜ ᱫᱚ ᱚᱠᱟ ᱟᱹᱛᱩ ᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ?',
            textLatin:
                'Amaak orag do oka atu re menaga? – In which village is your home located?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱚᱲᱟᱜ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱟᱹᱛᱩ ᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Injaak orag do adi napay atu re menaga – My home is in a very beautiful village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱞᱚᱢ ᱠᱟᱹᱢᱤᱭᱟ, ᱡᱤᱨᱟᱹᱣ ᱢᱮ',
            textLatin:
                'Tehenj do alom kamiya, jiraw me – Do not work today, take rest.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱚᱸᱰᱮ ᱦᱤᱡᱩᱜ ᱢᱮ, ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
            textLatin:
                'Daya kate nonde hijug me, daka jom me – Please come here and eat food.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱫᱟᱜ ᱧᱩ ᱥᱟᱱᱟᱧ ᱠᱟᱱᱟ, ᱫᱟᱜ ᱮᱢᱟᱧ ᱢᱮ',
            textLatin:
                'In do dag nju sananj kana, dag emanj me – I want to drink water, please give me water.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱦᱚᱨ ᱫᱚ ᱟᱹᱰᱤ ᱡᱤᱞᱤᱧ ᱜᱮᱭᱟ',
            textLatin:
                'Atu reyag hor do adi jilinj geya – The village road is very long.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱭᱳ ᱟᱨ ᱵᱟᱵᱟ ᱫᱚ ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱜ ᱠᱤᱱᱟ?',
            textLatin:
                'Amaak ayo ar baba do okare menag kina? – Where are your mother and father?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱠᱤᱱ ᱫᱚ ᱚᱲᱟᱜ ᱨᱮ ᱜᱮ ᱢᱮᱱᱟᱜ ᱠᱤᱱᱟ',
            textLatin:
                'Unkin do orag re ge menag kina – They are right at home.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱢᱤᱥᱮᱨᱟ ᱫᱚ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱛᱮ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Injaak misera do itun asra te chalag kana – My younger sister is going to school.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱥᱤᱸᱜᱮ ᱢᱟᱦᱟ ᱠᱟᱱᱟ, ᱪᱷᱩᱴᱤ ᱢᱟᱦᱟ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do Singe maha kana, chuti maha kana – Today is Sunday, it is a holiday.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱵᱤᱱ ᱫᱚ ᱚᱠᱟ ᱠᱷᱚᱱ ᱵᱤᱱ ᱦᱤᱡᱩᱜ ᱠᱟᱱᱟ?',
            textLatin:
                'Abin do oka khon bin hijug kana? – Where are you two coming from?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱤᱨ ᱛᱮᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ, ᱥᱟᱦᱟᱱ ᱞᱟᱹᱜᱤᱫ',
            textLatin:
                'In do bir tenj chalag kana, sahan lagid – I am going to the forest for firewood.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱡᱷᱟᱹᱞᱤ ᱫᱟᱜ ᱨᱮᱭᱟᱜ ᱡᱷᱟᱨᱱᱟ ᱢᱮᱱᱟᱜᱼᱟ?',
            textLatin:
                'Amaak atu re do jhale dag reyag jharna menaga? – Is there a clean waterfall in your village?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱟᱹᱰᱤ ᱥᱤᱵᱤᱞ ᱫᱟᱜ ᱡᱷᱟᱨᱱᱟ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, ale atu re adi sibil dag jharna menaga – Yes, there is a very sweet water spring in our village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱫᱚ ᱫᱟᱠᱟ ᱟᱨ ᱩᱛᱩ ᱡᱚᱢ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤ ᱛᱮᱧ ᱪᱟᱞᱟᱜᱼᱟ',
            textLatin:
                'Injaak do daka ar utu jom kate kami tenj chalaga – After eating rice and curry, I will go to my work.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱠᱟᱹᱢᱤ ᱢᱮ ᱜᱟᱛᱮ, ᱥᱟᱹᱜᱩᱱ ᱫᱤᱱ ᱦᱩᱭᱩᱜ ᱛᱟᱢ',
            textLatin:
                'Napay te kami me gate, sagun din huyug tam – Work well friend, have an auspicious day.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_complex_intermediate',
        'titleLatin': 'Village & Social Life',
        'titleOlChiki': 'ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱜᱟᱞᱢᱟᱨᱟᱣ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱡᱟᱦᱮᱨ ᱛᱷᱟᱱ ᱨᱮ ᱠᱚ ᱡᱟᱣᱨᱟ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Atu rin hor do jaher than re ko jawra akana – The villagers have gathered at the sacred grove.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱦᱟᱲᱟᱢ ᱫᱚ ᱟᱹᱛᱩ ᱦᱚᱲ ᱥᱟᱶ ᱮ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱠᱟᱱᱟ',
            textLatin:
                'Manjhi haram do atu hor saw e galmaraw kana – The village headman is talking with the villagers.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱮᱨᱮᱧ ᱠᱚ ᱥᱮᱨᱮᱧ ᱮᱫᱟ',
            textLatin:
                'Tehenj do adi napay Santali serenj ko serenj eda – Today they are singing very beautiful Santali songs.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱩᱢᱩᱞ ᱨᱮ ᱫᱩᱲᱩᱵ ᱠᱟᱛᱮ ᱩᱱᱠᱩ ᱠᱚ ᱡᱤᱨᱟᱹᱣ ᱠᱟᱱᱟ',
            textLatin:
                'Dare umul re durub kate unku ko jiraw kana – Sitting under the tree\'s shade, they are resting.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱩᱢᱫᱟᱜ ᱟᱨ ᱴᱟᱢᱟᱠ ᱨᱩ ᱮᱢ ᱵᱟᱰᱟᱭᱟ?',
            textLatin:
                'Am do tumdag ar tamak ru em badaya? – Do you know how to play the clay drum and kettle drum?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱛᱩᱢᱫᱟᱜ ᱨᱩ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱤᱧ ᱵᱟᱰᱟᱭᱟ',
            textLatin:
                'Hẽ, in do tumdag ru adi napay inj badaya – Yes, I know how to play the clay drum very well.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱜᱽᱬᱮ ᱮᱱᱮᱡ ᱞᱟᱹᱜᱤᱫ ᱠᱩᱲᱤ ᱟᱨ ᱠᱚᱲᱟ ᱠᱚ ᱥᱟᱯᱲᱟᱣ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Lagne enej lagid kuri ar kora ko sapraw akana – The boys and girls are ready for the Lagne dance.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱢᱟᱨᱟᱝ ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Ale atu re do adi marang Baha porob huyuga – A very grand Baha festival is celebrated in our village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱛᱮ ᱠᱩᱲᱤ ᱠᱚ ᱵᱚᱦᱚᱜ ᱠᱚ ᱥᱟᱡᱟᱣ ᱮᱫᱟ',
            textLatin:
                'Sarjom baha te kuri ko bohog ko sajaw eda – The girls are decorating their hair with Sal flowers.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱟᱱᱟᱢ ᱨᱩ ᱟᱨ ᱛᱤᱨᱭᱳ ᱚᱨᱚᱝ ᱥᱟᱱᱟᱧ ᱠᱟᱱᱟ',
            textLatin:
                'In do banam ru ar tiryo orong sananj kana – I want to play the fiddle and blow the bamboo flute.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱮ ᱫᱟᱜ ᱨᱮᱭᱟᱜ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱡᱷᱟᱨᱱᱟ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Atu re dag reyag adi napay jharna menaga – There is a very beautiful water spring in the village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱢᱚᱱᱮ ᱟᱞᱚᱢ ᱵᱟᱹᱲᱤᱡᱟ, ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱢᱮ',
            textLatin:
                'Amaak mone alom barija, sari katha ror me – Do not ruin your heart, speak the truth.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱠᱟᱹᱢᱤ ᱞᱟᱹᱜᱤᱫ ᱴᱟᱺᱰᱤ ᱛᱮ ᱪᱟᱞᱟᱣ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Uni do kami lagid tandi te chalaw akana – He has gone to the field for work.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱹᱫᱷᱩ ᱟᱨ ᱱᱟᱯᱟᱭ ᱜᱮᱭᱟ ᱠᱚ',
            textLatin:
                'Atu rin hor do adi sadhu ar napay geya ko – The village people are very honest and kind.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱡᱩᱨ ᱥᱤᱛᱩᱝ ᱮ ᱮᱢᱟ',
            textLatin:
                'Situng ritu re do adi jur situng e ema – In the summer season, the sun shines very brightly.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ ᱨᱮ ᱫᱚ ᱜᱟᱰᱟ ᱫᱟᱜ ᱛᱮ ᱯᱮᱨᱮᱡᱚᱜᱼᱟ',
            textLatin:
                'Dag ritu re do gada dag te perejoga – In the rainy season, the river overflows with water.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱢᱟᱹᱧᱡᱷᱤ ᱛᱷᱟᱱ ᱨᱮ ᱡᱟᱣᱨᱟ ᱠᱟᱛᱮ ᱠᱚ ᱵᱤᱪᱟᱹᱨᱮᱫᱟ',
            textLatin:
                'Atu rin hor do Manjhi than re jawra kate bicareda ko – The villagers gather at the headman\'s altar and are discussing.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ ᱨᱮ ᱠᱩᱲᱤ ᱦᱚᱯᱚᱱ ᱠᱚ ᱦᱟᱥᱟ ᱵᱷᱤᱛ ᱨᱮ ᱪᱤᱛᱟᱹᱨ ᱠᱚ ᱥᱟᱡᱟᱣ ᱮᱫᱟ',
            textLatin:
                'Sohrae porob re kuri hopon ko hasa bhit re citar ko sajaw eda – In the Sohrae festival, the women are decorating the clay walls with paintings.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱛᱩᱢᱫᱟᱜ ᱟᱨ ᱴᱟᱢᱟᱠ ᱨᱩ ᱟᱸᱡᱚᱢ ᱠᱟᱛᱮ ᱠᱚᱲᱟ ᱟᱨ ᱠᱩᱲᱤ ᱠᱚ ᱮᱱᱮᱡ ᱮᱫᱟ',
            textLatin:
                'Tumdag ar tamak ru anjom kate kora ar kuri ko enej eda – Hearing the clay drum and kettle drum, the boys and girls are dancing.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱠᱩᱞᱦᱤ ᱫᱚ ᱥᱟᱹᱜᱩᱱ ᱥᱟᱠᱟᱢ ᱟᱨ ᱵᱟᱦᱟ ᱛᱮ ᱠᱚ ᱥᱟᱡᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Atu reyag kulhi do sagun sakam ar baha te ko sajaw akada – They have decorated the village street with auspicious leaves and flowers.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_complex_advanced',
        'titleLatin': 'Traditional Wisdom & Ecology',
        'titleOlChiki': 'ᱜᱟᱹᱦᱤᱨ ᱥᱟᱱᱛᱟᱲᱤ ᱣᱟᱠᱭ',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱟᱨᱮ ᱜᱮ ᱡᱤᱣᱤ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱫᱟᱨᱮ ᱵᱟᱧᱪᱟᱣ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Dare ge jiwi kana, onate dare bancaw do abowaak dhorom kana – Trees are life, therefore protecting trees is our sacred duty.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱦᱚᱲ ᱫᱚ ᱵᱟᱹᱠᱩ ᱨᱚᱲᱟ, ᱚᱱᱟᱛᱮ ᱦᱚᱞᱟ ᱠᱟᱛᱷᱟ ᱫᱚ ᱦᱤᱲᱤᱧ ᱢᱮ',
            textLatin:
                'Goj hor do baku rora, onate hola katha do hirinj me – Dead people do not speak, so forget about yesterday\'s matters.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱛᱩ ᱦᱚᱲ ᱜᱮ ᱫᱤᱥᱚᱢ ᱦᱚᱲ ᱠᱟᱱᱟ ᱠᱚ, ᱡᱩᱢᱤᱫᱽ ᱜᱮ ᱟᱵᱚᱣᱟᱜ ᱫᱟᱲᱮ ᱠᱟᱱᱟ',
            textLatin:
                'Atu hor ge disom hor kana ko, jumid ge abowaak dare kana – The villagers are the country\'s strength; unity is our power.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱟᱜ ᱨᱮ ᱡᱷᱟᱹᱞᱤ ᱵᱟᱹᱭᱥᱟᱹᱣ ᱞᱮᱠᱟ, ᱵᱟᱝ ᱦᱩᱭᱩᱜ ᱠᱟᱹᱢᱤ ᱨᱮ ᱚᱠᱛᱚ ᱟᱞᱚᱢ ᱱᱚᱥᱴᱚᱭᱟ',
            textLatin:
                'Dag re jhale baysaw leka, bang huyug kami re okto alom nostoya – Like setting a net in water, do not waste time on impossible tasks.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱮᱫ ᱞᱩᱴᱩᱨ ᱵᱮᱸᱜᱮᱫ ᱠᱟᱛᱮ ᱪᱟᱞᱟᱜ ᱢᱮ, ᱦᱚᱨ ᱨᱮ ᱟᱹᱰᱤ ᱫᱷᱤᱨᱤ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Med lutur benget kate chalag me, hor re adi dhiri menaga – Keep your eyes and ears open; there are many stones on the road.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱡᱟᱦᱟᱸ ᱞᱮᱠᱟᱢ ᱨᱚᱲᱟ, ᱟᱢ ᱥᱟᱶ ᱦᱚᱲ ᱦᱚᱸ ᱚᱱᱠᱟ ᱜᱮ ᱠᱚ ᱨᱚᱲᱟ',
            textLatin:
                'Am jaha lekam rora, am saw hor ho onka ge ko rora – As you speak, people will speak with you in the same way.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ ᱨᱮ ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ, ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Sohrae porob re ale orag te hijug me, adi napay huyuga – Come to our home during the Sohrae festival, it will be wonderful.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ ᱛᱮ ᱚᱞ ᱢᱮ, ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱢᱮ',
            textLatin:
                'Guru kolom te ol me, geyan hor re lahag me – Write with the Guru\'s pen, advance on the path of knowledge.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ ᱟᱨ ᱞᱟᱠᱪᱟᱨ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱩᱯᱨᱩᱢ ᱠᱟᱱᱟ, ᱚᱱᱟ ᱫᱚ ᱵᱟᱧᱪᱟᱣ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Ari chali ar lakchar do abowaak uprum kana, ona do bancaw kag me – Customs and culture are our identity; protect them well.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱲᱮᱢ ᱨᱚᱲ ᱛᱮ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱢᱚᱱᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱢᱮ',
            textLatin:
                'Herem ror te sanam hor mone jitkar me – Win everyone\'s heart with sweet and fluent speech.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱫᱚ ᱱᱚᱶᱟ ᱫᱷᱟᱹᱨᱛᱤ ᱟᱹᱰᱤ ᱪᱮᱦᱨᱟ ᱛᱮ ᱥᱟᱡᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Sirjoniya do nowa dharti adi chehra te sajaw akada – The Creator has decorated this earth beautifully.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱡᱟᱞᱟ ᱨᱮ ᱫᱷᱤᱨᱚᱡᱽ ᱫᱚᱦᱚᱭ ᱢᱮ, ᱢᱤᱫ ᱫᱤᱱ ᱥᱟᱹᱨᱤ ᱜᱮ ᱱᱟᱯᱟᱭ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Amaak jiwi jala re dhiroj dohoy me, mid din sari ge napay huyuga – Keep patience in your life struggles; one day it will surely be good.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ ᱠᱟᱛᱮ ᱟᱹᱰᱤ ᱞᱮᱠᱟᱱ ᱜᱮᱭᱟᱱ ᱮᱢ ᱧᱟᱢ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Disom daran kate adi lekan geyan em njam dareyaga – By traveling the country, you can gain many kinds of knowledge.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱷᱚᱨᱚᱢ ᱠᱟᱹᱢᱤ ᱨᱮ ᱢᱚᱱᱮ ᱞᱟᱜᱟᱣ ᱢᱮ, ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱢᱟᱹᱱ ᱠᱚ ᱮᱢᱟᱢᱟ',
            textLatin:
                'Dhorom kami re mone lagaw me, sanam hor man ko emama – Engage in righteous deeds; everyone will respect you.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱫᱚ ᱟᱹᱰᱤ ᱠᱤᱥᱟᱹᱬ ᱟᱨ ᱜᱟᱹᱦᱤᱨ ᱜᱮᱭᱟ',
            textLatin:
                'Santali sawhet do adi kisan ar gahir geya – Santali literature is very rich and deep.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱟᱨ ᱫᱤᱥᱚᱢ ᱨᱮᱭᱟᱜ ᱧᱩᱛᱩᱢ ᱩᱡᱽᱣᱟᱹᱞ ᱢᱮ',
            textLatin:
                'Olog parhaw kate amaak atu ar disom reyag nyutum ujlaw me – By studying well, brighten the name of your village and country.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱹᱨᱤ ᱜᱩᱨᱩ ᱣᱟᱜ ᱥᱮᱪᱮᱫ ᱛᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱥᱟᱹᱱᱛᱤ ᱵᱚᱱ ᱧᱟᱢᱟ',
            textLatin:
                'Sari guru waak seched te abo sanam hor jiwi re sari santi bon njama – With the true teacher\'s education, we all find true peace in our lives.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱜᱮᱭᱟᱱ ᱫᱚᱨᱭᱟ ᱨᱮ ᱰᱩᱵᱩᱡ ᱠᱟᱛᱮ ᱟᱢ ᱫᱚ ᱥᱟᱹᱨᱤ ᱫᱷᱚᱨᱚᱢ ᱨᱮᱭᱟᱜ ᱜᱟᱹᱦᱤᱨ ᱠᱟᱛᱷᱟᱢ ᱵᱟᱰᱟᱭ ᱧᱟᱢᱟ',
            textLatin:
                'Geyan dorya re dubuj kate am do sari dhorom reyag gahir katham baday njama – By diving into the ocean of knowledge, you will understand the deep truths of the true religion.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ ᱟᱨ ᱞᱟᱠᱪᱟᱨ ᱵᱟᱧᱪᱟᱣ ᱫᱚᱦᱚ ᱜᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Ari chali ar lakchar bancaw doho ge sari hor hopon aak marang dhorom kana – Preserving customs and culture is the great duty of a true Santal.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ ᱟᱨ ᱡᱩᱢᱤᱫᱽ ᱜᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱥᱩᱠᱷ ᱮ ᱮᱢᱟ ᱵᱚᱱᱟ',
            textLatin:
                'Sirjon dular ar jumid ge abo sanam hor jiwi re sari sukh e ema bona – Love for nature and unity give true happiness in our lives.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_conversational_1',
        'titleLatin': 'Modern Conversational Exchanges I',
        'titleOlChiki': 'ᱦᱟᱹᱞᱤ ᱨᱚᱲ ᱣᱟᱠᱭ ᱢᱩᱦᱤᱛ ᱑',
        'level': 'beginner',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱛᱮᱦᱮᱧ ᱪᱮᱫ ᱮᱢ ᱡᱚᱢ ᱠᱮᱫᱟ?',
            textLatin: 'Am tehenj ced em jom keda? – What did you eat today?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱫᱟᱠᱟ ᱟᱨ ᱡᱮᱞᱤᱧ ᱩᱛᱩᱧ ᱡᱚᱢ ᱠᱮᱫᱟ',
            textLatin:
                'In do daka ar jelinj utunj jom keda – I ate rice and fish curry.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱜᱟᱛᱮ ᱠᱚᱲᱟ ᱫᱚ ᱚᱠᱚᱭ ᱠᱟᱱᱟᱭ?',
            textLatin:
                'Amaak gate kora do okoy kanay? – Who is your male friend?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱜᱟᱛᱮ ᱠᱚᱲᱟ ᱫᱚ ᱥᱟᱹᱜᱩᱱ ᱠᱟᱱᱟᱭ',
            textLatin:
                'Injaak gate kora do Sagun kanay – My male friend is Sagun.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱮᱦᱮᱧ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱮᱢ ᱪᱟᱞᱟᱣ ᱞᱮᱱᱟ?',
            textLatin:
                'Am do tehenj itun asra em chalaw lena? – Did you go to school today?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱝ, ᱛᱮᱦᱮᱧ ᱫᱚ ᱪᱷᱩᱴᱤ ᱫᱤᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Bang, tehenj do chuti din kana – No, today is a holiday.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱨᱮ ᱛᱤᱱᱟᱹᱜ ᱚᱲᱟᱜ ᱢᱮᱱᱟᱜᱼᱟ?',
            textLatin:
                'Amaak atu re tinag orag menaga? – How many houses are there in your village?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱸᱜᱮ ᱚᱲᱟᱜ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Ale atu re do adi sange orag menaga – There are many houses in our village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱤᱧ ᱥᱟᱶ ᱮᱢ ᱜᱟᱞᱢᱟᱨᱟᱣᱟ?',
            textLatin: 'Am do in saw em galmarawa? – Will you speak with me?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱟᱢ ᱥᱟᱶ ᱨᱚᱲ ᱟᱹᱰᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, in do am saw ror adinj kusiyaga – Yes, I really like to talk with you.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟ ᱠᱟᱹᱢᱤᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin: 'Am do oka kamim kusiyaga? – Which work do you like?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱹᱢᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
            textLatin:
                'In do olog parhaw kaminj kusiyaga – I like the work of studying.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱥᱤᱛᱩᱝ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do adi napay situng kana – Today it is very pleasantly sunny.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱟᱜ ᱮᱢᱟᱧ ᱢᱮ, ᱤᱧ ᱛᱮᱛᱟᱝ ᱮᱫ ᱤᱧᱟ',
            textLatin:
                'Daya kate dag emanj me, in tetang ed inja – Please give me water, I am thirsty.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱟᱜ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱟᱨ ᱥᱟᱯᱷᱟ ᱜᱮᱭᱟ',
            textLatin:
                'Nowa dag do adi napay ar sapha geya – This water is very good and clean.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱲᱟᱜ ᱨᱮ ᱚᱠᱚᱭ ᱠᱚ ᱢᱮᱱᱟᱜ ᱠᱚᱣᱟ?',
            textLatin:
                'Amaak orag re okoy ko menag kowa? – Who is at your home?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱚᱲᱟᱜ ᱨᱮ ᱟᱭᱳ, ᱵᱟᱵᱟ ᱟᱨ ᱢᱤᱥᱮᱨᱟ ᱢᱮᱱᱟᱜ ᱠᱚᱣᱟ',
            textLatin:
                'Injaak orag re ayo, baba ar misera menag kowa – In my home are mother, father, and younger sister.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱤᱥ ᱮᱢ ᱦᱤᱡᱩᱜᱼᱟ?',
            textLatin: 'Am do tis em hijuga? – When will you come?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱜᱟᱯᱟ ᱥᱮᱛᱟᱜ ᱤᱧ ᱦᱤᱡᱩᱜᱼᱟ',
            textLatin:
                'In do gapa setag inj hijuga – I will come tomorrow morning.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱥᱤᱵᱤᱞ ᱨᱚᱲ ᱫᱚ ᱤᱧ ᱟᱹᱰᱤᱧ ᱠᱩᱥᱤᱭᱟᱫᱼᱟ',
            textLatin:
                'Amaak sibil ror do in adinj kusiyada – I really liked your sweet words.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ ᱜᱟᱛᱮ, ᱥᱟᱨᱦᱟᱣ',
            textLatin:
                'Napay te tahen me gate, sarhaw – Stay well friend, thank you.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ, ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱟ',
            textLatin:
                'Sagun njida, gapa bon njapama – Good night, we will meet tomorrow.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_conversational_2',
        'titleLatin': 'Modern Conversational Exchanges II',
        'titleOlChiki': 'ᱦᱟᱹᱞᱤ ᱨᱚᱲ ᱣᱟᱠᱭ ᱢᱩᱦᱤᱛ ᱒',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱯᱩᱛᱷᱤᱢ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟ?',
            textLatin:
                'Am do ced puthim parhaag kana? – What book are you reading?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱨᱮᱭᱟᱜ ᱯᱩᱛᱷᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'In do Santali sawhet reyag puthinj parhaag kana – I am reading a book of Santali literature.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱯᱩᱛᱷᱤ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱠᱟᱛᱷᱟ ᱚᱞ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Nowa puthi re do adi napay katha ol menaga – Very good things are written in this book.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱚᱞ ᱪᱤᱠᱤᱢ ᱚᱞ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ?',
            textLatin:
                'Am do Santali Ol Chiki em ol dareyaga? – Can you write Santali Ol Chiki?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱚᱞ ᱪᱤᱠᱤᱧ ᱚᱞ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, in do adi napay Ol Chikinj ol dareyaga – Yes, I can write Ol Chiki very well.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱚᱭ ᱪᱮᱫ ᱟᱫ ᱢᱮᱭᱟᱭ?',
            textLatin: 'Am do okoy chet ad meyay? – Who taught you?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱤᱧᱟᱜ ᱵᱟᱵᱟ ᱟᱨ ᱜᱩᱨᱩ ᱠᱤᱱ ᱪᱮᱫ ᱟᱫ ᱤᱧᱟ',
            textLatin:
                'In do injaak baba ar guru kin chet ad inja – My father and teacher taught me.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱛᱩ ᱨᱮ ᱟᱹᱰᱤ ᱢᱟᱨᱟᱝ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱦᱩᱭᱩᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do atu re adi marang galmaraw huyug kana – Today a very big discussion is happening in the village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱱᱟ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱛᱮᱢ ᱪᱟᱞᱟᱜᱼᱟ?',
            textLatin:
                'Am do ona galmaraw tem chalaga? – Will you go to that discussion?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱥᱟᱶ ᱤᱧ ᱪᱟᱞᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, in do atu rin hor saw inj chalaga – Yes, I will go with the villagers.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱦᱟᱲᱟᱢ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱵᱤᱪᱟᱹᱨ ᱮ ᱮᱢᱟ',
            textLatin:
                'Manjhi haram do adi napay bicar e ema – The village headman gives very good judgment.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱡᱟᱣᱨᱟ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤᱭᱟ ᱠᱚ',
            textLatin:
                'Ale atu rin hor do jawra kate kamiya ko – Our villagers gather and work together.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ ᱜᱮ ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱟᱲᱮ ᱠᱟᱱᱟ',
            textLatin:
                'Jumid ge ale atu reyag marang dare kana – Unity is the great strength of our village.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱞᱟᱜᱽᱬᱮ ᱮᱱᱮᱡ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin:
                'Am do Lagne enej em kusiyaga? – Do you like the Lagne dance?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱞᱟᱜᱽᱬᱮ ᱮᱱᱮᱡ ᱟᱨ ᱥᱮᱨᱮᱧ ᱫᱚ ᱤᱧᱟᱜ ᱡᱤᱣᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Hẽ, Lagne enej ar serenj do injaak jiwi kana – Yes, Lagne dance and song are my life.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱩᱢᱫᱟᱜ ᱟᱨ ᱴᱟᱢᱟᱠ ᱨᱮᱭᱟᱜ ᱥᱟᱰᱮ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱵᱤᱞ ᱜᱮᱭᱟ',
            textLatin:
                'Tumdag ar tamak reyag sade do adi sibil geya – The sound of the clay drum and kettle drum is very sweet.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱲᱟᱜ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱯᱷᱟ ᱟᱨ ᱪᱮᱦᱨᱟ ᱜᱮᱭᱟ',
            textLatin:
                'Amaak orag do adi sapha ar chehra geya – Your home is very clean and beautiful.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱭᱳ ᱫᱚ ᱫᱤᱱᱟᱹᱢ ᱚᱲᱟᱜ ᱮ ᱥᱟᱯᱷᱟᱭᱟ ᱟᱨ ᱫᱟᱠᱟᱭᱟ',
            textLatin:
                'Ayo do dinam orag e saphaya ar dakaya – Mother cleans the house and cooks rice every day.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱵᱟ ᱫᱚ ᱴᱟᱺᱰᱤ ᱛᱮ ᱪᱟᱞᱟᱣ ᱟᱠᱟᱱᱟᱭ, ᱪᱟᱥ ᱠᱟᱹᱢᱤ ᱞᱟᱹᱜᱤᱫ',
            textLatin:
                'Baba do tandi te chalaw akanay, chas kami lagid – Father has gone to the field for farming.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱹᱫᱷᱩ ᱟᱨ ᱱᱟᱯᱟᱭ ᱡᱤᱣᱤ ᱞᱮ ᱠᱷᱟᱸᱰᱟᱣᱮᱫᱟ',
            textLatin:
                'Ale do adi sadhu ar napay jiwi le khandaweda – We live a very simple and peaceful life.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ ᱜᱮ ᱟᱞᱮᱭᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Sirjon dular ge aleyaak marang dhorom kana – Love for nature is our great religion.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱢᱮ, ᱡᱤᱣᱤ ᱨᱮ ᱥᱩᱠᱷ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Sari katha ror me, jiwi re sukh em njama – Speak the truth, you will find happiness in life.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_conversational_3',
        'titleLatin': 'Modern Conversational Exchanges III',
        'titleOlChiki': 'ᱦᱟᱹᱞᱤ ᱨᱚᱲ ᱣᱟᱠᱭ ᱢᱩᱦᱤᱛ ᱓',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱮᱦᱮᱧ ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ ᱮᱢ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
            textLatin:
                'Am do tehenj disom daran em chalag kana? – Are you going to travel the country today?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱱᱟᱶᱟ ᱟᱹᱛᱩ ᱟᱨ ᱱᱟᱶᱟ ᱦᱚᱲ ᱧᱮᱞ ᱤᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Hẽ, in do nawa atu ar nawa hor njel inj chalag kana – Yes, I am going to see new villages and new people.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ ᱠᱟᱛᱮ ᱟᱹᱰᱤ ᱞᱮᱠᱟᱱ ᱜᱮᱭᱟᱱ ᱧᱟᱢᱚᱜᱼᱟ',
            textLatin:
                'Disom daran kate adi lekan geyan njamoga – Traveling the country brings many kinds of knowledge.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱡᱟᱞᱟ ᱨᱮ ᱫᱷᱤᱨᱚᱡᱽ ᱫᱚᱦᱚᱭ ᱢᱮ, ᱡᱤᱛᱠᱟᱹᱨ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Amaak jiwi jala re dhiroj dohoy me, jitkar em njama – Keep patience in your life struggles, you will achieve victory.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱮᱴᱮᱡ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤ ᱢᱮ, ᱫᱟᱲᱮ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Mone ketej kate kami me, dare em njama – Work with a strong mind, you will find strength.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱵᱤᱨ ᱫᱟᱨᱮ ᱞᱮᱠᱟ ᱠᱮᱴᱮᱡ ᱜᱮᱭᱟ ᱠᱚ',
            textLatin:
                'Atu rin hor do bir dare leka ketej geya ko – The village people are as strong as the forest trees.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱥᱟᱠᱟᱢ ᱛᱮ ᱟᱹᱰᱤ ᱞᱮᱠᱟᱱ ᱨᱟᱱ ᱵᱮᱱᱟᱣᱚᱜᱼᱟ',
            textLatin:
                'Dare sakam te adi lekan ran benawoga – Many kinds of medicines are made from tree leaves.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱵᱟᱧᱪᱟᱣ ᱞᱟᱹᱜᱤᱫ ᱟᱹᱛᱩ ᱦᱚᱲ ᱠᱚ ᱥᱟᱯᱲᱟᱣ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Bir bancaw lagid atu hor ko sapraw akana – The villagers are ready to protect the forest.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ ᱨᱮ ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ ᱢᱮᱱᱟᱜ ᱢᱮᱭᱟ',
            textLatin:
                'Sohrae porob re ale orag te sagun daram menag meya – You are welcome to our house during the Sohrae festival.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱞᱮ ᱚᱲᱟᱜ ᱨᱮ ᱫᱚ ᱦᱟᱥᱟ ᱨᱮᱭᱟᱜ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱵᱷᱤᱛ ᱪᱤᱛᱟᱹᱨ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Ale orag re do hasa reyag adi napay bhit citar menaga – There are very beautiful clay wall paintings in our home.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱭᱳ ᱫᱚ ᱦᱟᱥᱟ ᱵᱷᱤᱛ ᱨᱮ ᱟᱹᱰᱤ ᱪᱮᱦᱨᱟ ᱪᱤᱛᱟᱹᱨ ᱮ ᱵᱮᱱᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Ayo do hasa bhit re adi chehra citar e benaw akada – Mother has drawn very beautiful paintings on the clay wall.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵ ᱨᱮ ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱛᱮ ᱵᱚᱸᱜᱟ ᱛᱷᱟᱱ ᱞᱮ ᱥᱟᱡᱟᱣᱟ',
            textLatin:
                'Baha porob re sarjom baha te bonga than le sajawa – In the Baha festival, we decorate the place of worship with Sal flowers.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱞᱟᱹᱜᱤᱫ ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ ᱟᱹᱰᱤ ᱞᱟᱹᱠᱛᱤ ᱜᱮᱭᱟ',
            textLatin:
                'Geyan hor re lahag lagid olog parhaw adi lakti geya – Studying is very necessary to advance on the path of knowledge.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ ᱛᱮ ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱥᱮᱨᱢᱟ ᱨᱮ ᱚᱞ ᱢᱮ',
            textLatin:
                'Guru kolom te amaak nyutum serma re ol me – Write your name in the sky with the Guru\'s pen.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ ᱟᱨ ᱞᱟᱠᱪᱟᱨ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱢᱟᱨᱟᱝ ᱩᱯᱨᱩᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Ari chali ar lakchar do abowaak marang uprum kana – Customs and culture are our great identity.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱲᱮᱢ ᱨᱚᱲ ᱛᱮ ᱟᱹᱛᱩ ᱦᱚᱲ ᱢᱚᱱᱮ ᱨᱮ ᱡᱟᱭᱜᱟ ᱵᱮᱱᱟᱣ ᱢᱮ',
            textLatin:
                'Herem ror te atu hor mone re jayga benaw me – Make a place in the hearts of the villagers with sweet speech.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱛᱮ ᱱᱚᱶᱟ ᱫᱷᱟᱹᱨᱛᱤ ᱮ ᱥᱤᱨᱡᱚᱱ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Sirjoniya do adi napay te nowa dharti e sirjon akada – The Creator has created this earth very beautifully.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱢᱟᱜ ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱛᱮ ᱠᱟᱹᱢᱤ ᱢᱮ, ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱟᱹᱥᱤᱥ ᱮ ᱮᱢᱟᱢᱟ',
            textLatin:
                'Amaak sari mone te kami me, sirjoniya asis e emama – Work with your honest heart, the Creator will bless you.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱛᱮ ᱤᱧ ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹᱧ ᱧᱟᱢ ᱠᱮᱫᱟ',
            textLatin:
                'Santali sawhet parhaw kate in adi raskanj njam keda – I found great joy by reading Santali literature.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱵᱤᱱ ᱫᱚ ᱛᱮᱦᱮᱧ ᱚᱠᱟ ᱛᱮ ᱵᱤᱱ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
            textLatin:
                'Abin do tehenj oka te bin chalag kana? – Where are you two going today?',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱞᱤᱧ ᱫᱚ ᱵᱤᱨ ᱛᱮ ᱞᱤᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ, ᱥᱟᱦᱟᱱ ᱞᱟᱹᱜᱤᱫ',
            textLatin:
                'Alinj do bir te linj chalag kana, sahan lagid – We two are going to the forest for firewood.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱪᱟᱞᱟᱣ ᱠᱟᱛᱮ ᱨᱩᱣᱟᱹᱲ ᱦᱤᱡᱩᱜ ᱢᱮ, ᱡᱚᱦᱟᱨ',
            textLatin:
                'Napay te chalaw kate ruwar hijug me, johar – Go safely and return, greetings.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_folk_1',
        'titleLatin': 'Cultural Proverbs & Wisdom I',
        'titleOlChiki': 'ᱞᱟᱠᱪᱟᱨ ᱵᱮᱱᱛᱟ ᱣᱟᱠᱭ ᱑',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱜᱮ ᱫᱷᱚᱱ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱫᱟᱨᱮ ᱟᱞᱚᱢ ᱢᱟᱜᱟ',
            textLatin:
                'Dare ge dhon kana, onate dare alom maga – Trees are wealth, therefore do not cut trees.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱦᱚᱲ ᱨᱚᱲ ᱵᱩᱨᱩ ᱨᱚᱲ, ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱫᱚ ᱛᱤᱥᱦᱚᱸ ᱵᱟᱝ ᱵᱚᱫᱚᱞᱚᱜᱼᱟ',
            textLatin:
                'Hor ror buru ror, sari katha do tishon bang bodologa – Man\'s word is as firm as the hill; the truth never changes.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱮ ᱡᱟᱱᱟᱢ ᱞᱮᱠᱟ, ᱟᱢᱟᱜ ᱢᱚᱱᱮ ᱫᱚ ᱥᱟᱯᱷᱟ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Dag re janam leka, amaak mone do sapha dohoy me – Like being born in water, keep your heart clean.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱦᱚᱲᱢᱚ ᱫᱚ ᱢᱤᱫ ᱫᱤᱱ ᱦᱟᱥᱟ ᱨᱮ ᱜᱮ ᱢᱮᱥᱟᱜᱼᱟ',
            textLatin:
                'Hasa hormo do mid din hasa re ge mesaga – The clay body will one day mix into the clay.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱮᱸᱜᱮᱞ ᱡᱤᱣᱤ ᱛᱟᱹᱦᱮᱱ ᱠᱷᱟᱱ, ᱡᱟᱦᱟᱸ ᱠᱟᱹᱢᱤ ᱜᱮ ᱦᱩᱭ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Sengel jiwi tahen khan, jaha kami ge huy dareyaga – If there is a fiery soul, any work can be accomplished.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ ᱞᱮᱠᱟ ᱫᱟᱹᱲ ᱠᱟᱛᱮ ᱚᱠᱛᱚ ᱟᱞᱚᱢ ᱱᱚᱥᱴᱚᱭᱟ',
            textLatin:
                'Hoy leka dar kate okto alom nostoya – Do not waste time by running like the wind.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱩᱢᱩᱞ ᱨᱮ ᱫᱩᱲᱩᱵ ᱠᱟᱛᱮ ᱟᱹᱛᱩ ᱦᱚᱲ ᱠᱚ ᱡᱤᱨᱟᱹᱣ ᱠᱟᱱᱟ',
            textLatin:
                'Bir umul re durub kate atu hor ko jiraw kana – The villagers are resting by sitting under the forest\'s shade.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱥᱟᱠᱟᱢ ᱛᱮ ᱟᱹᱛᱩ ᱨᱟᱱ ᱵᱮᱱᱟᱣ ᱠᱟᱛᱮ ᱦᱚᱲ ᱠᱚ ᱵᱮᱥᱚᱜᱼᱟ',
            textLatin:
                'Dare sakam te atu ran benaw kate hor ko besoga – People get cured by making village medicines from tree leaves.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱡᱤᱣᱤ ᱡᱟᱹᱞᱤ ᱨᱮ ᱛᱟᱹᱦᱮᱱ ᱞᱮᱠᱟ, ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱩᱢᱤᱫᱽ ᱛᱟᱦᱮᱸᱱ ᱞᱟᱹᱠᱛᱤ ᱜᱮᱭᱟ',
            textLatin:
                'Jiwi jhale re tahen leka, abo sanam hor jumid tahen lakti geya – As if living in the web of life, it is necessary for all of us to remain united.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱥᱮᱨᱢᱟ ᱨᱮ ᱤᱯᱤᱞ ᱠᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱠᱚ ᱡᱩᱞᱩᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Sari serma re ipil ko adi napay ko julug kana – Stars shine very beautifully in the true heavens.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱠᱩᱫᱩᱢ ᱠᱟᱛᱷᱟ ᱛᱮ ᱟᱹᱛᱩ ᱦᱟᱲᱟᱢ ᱫᱚ ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱜᱮᱭᱟᱱ ᱮ ᱮᱢᱟ ᱠᱚᱣᱟ',
            textLatin:
                'Kudum katha te atu haram do gidra ko geyan e ema kowa – The village elder gives knowledge to children through riddles.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱮᱱᱛᱟ ᱨᱚᱲ ᱛᱮ ᱟᱢᱟᱜ ᱠᱟᱛᱷᱟ ᱫᱚ ᱜᱟᱹᱦᱤᱨ ᱛᱮ ᱥᱚᱫᱚᱨ ᱢᱮ',
            textLatin:
                'Benta ror te amaak katha do gahir te sodor me – Present your words deeply with idiomatic speech.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱲᱟᱢ ᱠᱟᱛᱷᱟ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱨ ᱮ ᱩᱫᱩᱜᱼᱟ',
            textLatin:
                'Haram katha do abowaak jiwi re sari hor e uduga – Ancestral wisdom shows the true path in our lives.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱵᱩᱰᱷᱤ ᱩᱭᱦᱟᱹᱨ ᱛᱮ ᱚᱲᱟᱜ ᱨᱮᱭᱟᱜ ᱜᱷᱟᱨᱚᱸᱡᱽ ᱫᱚ ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin:
                'Budhi uyhar te orag reyag gharonj do napay te tahena – The household remains peaceful with the wise grandmother\'s advice.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱟᱹᱨᱤ ᱞᱮᱠᱟᱛᱮ ᱥᱟᱱᱟᱢ ᱯᱚᱨᱚᱵ ᱞᱮ ᱢᱟᱱᱟᱣᱟ',
            textLatin:
                'Atu ari lekate sanam porob le manawa – We celebrate all festivals according to the village customs.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ ᱫᱟᱲᱮ ᱜᱮ ᱥᱟᱱᱛᱟᱲ ᱥᱚᱢᱟᱡᱽ ᱨᱮᱭᱟᱜ ᱢᱟᱨᱟᱝ ᱛᱷᱟᱹᱭ ᱠᱟᱱᱟ',
            textLatin:
                'Jumid dare ge Santal somaj reyag marang thay kana – Unity is the great pillar of the Santal society.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱥᱮᱨᱮᱧ ᱟᱸᱡᱚᱢ ᱠᱟᱛᱮ ᱡᱤᱣᱤ ᱨᱟᱹᱥᱠᱟᱹ ᱛᱮ ᱯᱮᱨᱮᱡᱚᱜᱼᱟ',
            textLatin:
                'Sohrae serenj anjom kate jiwi raska te perejoga – Listening to Sohrae songs fills the soul with joy.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱥᱟᱠᱟᱢ ᱨᱮ ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱫᱚᱦᱚ ᱠᱟᱛᱮ ᱞᱮ ᱵᱚᱸᱜᱟᱭᱟ',
            textLatin:
                'Baha sakam re sarjom baha doho kate le bongaya – We worship by keeping Sal flowers on Baha leaves.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱩᱢᱩᱞ ᱨᱮ ᱟᱞᱮ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱱᱟᱯᱟᱭ ᱛᱮ ᱞᱮ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin:
                'Jaher umul re ale do sanam hor napay te le tahena – Under the protection of the sacred grove, we all live peacefully.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱵᱤᱪᱟᱹᱨ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱠᱚ ᱢᱟᱱᱟᱣ ᱵᱟᱛᱟᱣᱟ',
            textLatin:
                'Manjhi bicar do sanam hor ko manaw batawa – Everyone respects and accepts the headman\'s judgment.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱫᱷᱚᱨᱚᱢ ᱞᱮᱠᱟᱛᱮ ᱡᱤᱣᱤ ᱠᱷᱟᱸᱰᱟᱣ ᱜᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱨ ᱠᱟᱱᱟ',
            textLatin:
                'Hor dhorom lekate jiwi khandaw ge sari hor kana – Living life according to the Santal way is the true path.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ ᱜᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱤᱣᱤ ᱨᱮ ᱫᱚᱦᱚ ᱞᱟᱹᱠᱛᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Sirjon dular ge abo sanam hor jiwi re doho lakti kana – It is necessary for all of us to keep love for nature in our lives.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_folk_2',
        'titleLatin': 'Cultural Proverbs & Wisdom II',
        'titleOlChiki': 'ᱞᱟᱠᱪᱟᱨ ᱵᱮᱱᱛᱟ ᱣᱟᱠᱭ ᱒',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱛ ᱦᱟᱥᱟ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱡᱟᱱᱟᱢ ᱟᱭᱳ ᱠᱟᱱᱟ, ᱚᱱᱟ ᱫᱚ ᱥᱟᱨᱦᱟᱣ ᱢᱮ',
            textLatin:
                'Ot hasa do abowaak janam ayo kana, ona do sarhaw me – Land and soil are our birth mother; appreciate them.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱡᱟᱱᱣᱟᱨ ᱠᱚ ᱵᱟᱧᱪᱟᱣ ᱫᱚ ᱵᱤᱨ ᱨᱮᱭᱟᱜ ᱥᱩᱱᱫᱚᱨ ᱠᱟᱱᱟ',
            textLatin:
                'Bir janwar ko bancaw do bir reyag sundor kana – Protecting wild beasts is the beauty of the forest.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱟᱠᱟᱢ ᱛᱮ ᱟᱹᱛᱩ ᱦᱚᱲ ᱠᱚ ᱱᱟᱶᱟ ᱥᱟᱹᱜᱩᱱ ᱠᱚ ᱧᱟᱢᱟ',
            textLatin:
                'Sagun sakam te atu hor ko nawa sagun ko njama – Through the auspicious leaf, the villagers receive new good omens.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱟᱹᱱᱢᱤ ᱜᱮᱭᱟᱱ ᱛᱮ ᱱᱚᱶᱟ ᱫᱷᱟᱹᱨᱛᱤ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱛᱮ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Manmi geyan te nowa dharti adi napay te chalag kana – With human wisdom, this earth functions very beautifully.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱜᱤᱰᱤ ᱞᱮᱠᱟ ᱵᱟᱹᱲᱤᱡ ᱠᱟᱛᱷᱟ ᱫᱚ ᱢᱚᱱᱮ ᱠᱷᱚᱱ ᱜᱤᱰᱤ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Goj gidi leka barij katha do mone khon gidi kag me – Throw away bad thoughts from the heart like discarded waste.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱛᱚᱞ ᱠᱟᱛᱮ ᱡᱟᱦᱟᱸᱭ ᱠᱟᱹᱢᱤᱭᱟ, ᱩᱱᱤ ᱫᱚ ᱡᱤᱛᱠᱟᱹᱨ ᱜᱮᱭᱟᱭ',
            textLatin:
                'Jiwi tol kate jahay kamiya, uni do jitkar geyay – Whoever works with dedicated soul is victorious.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱛᱷᱟᱹᱭ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱢᱮ',
            textLatin:
                'Mone thay kate amaak geyan hor re lahag me – Advance on your path of knowledge with a firm decision.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱡᱚᱢ ᱠᱟᱛᱮ ᱦᱚᱲ ᱟᱞᱚᱢ ᱮᱲᱮ ᱠᱚᱣᱟ, ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱢᱮ',
            textLatin:
                'Luti jom kate hor alom ere kowa, sari katha ror me – Do not deceive people with false promises; speak the truth.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱩ ᱛᱮ ᱨᱟᱠᱟᱵ ᱞᱮᱠᱟ ᱨᱟᱸᱜᱟᱣ ᱫᱚ ᱢᱚᱱᱮ ᱵᱟᱹᱲᱤᱡᱟ, ᱥᱟᱱᱛ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
            textLatin:
                'Mu te rakab leka rangaw do mone barija, sant tahen me – Anger like flaring nostrils ruins the heart; remain calm.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱫᱷᱤᱨᱤ ᱞᱮᱠᱟ ᱢᱚᱱᱮ ᱫᱚ ᱟᱞᱚᱢ ᱠᱮᱴᱮᱡᱟ, ᱫᱟᱭᱟ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Dag dhiri leka mone do alom keteja, daya dohoy me – Do not harden your heart like a wet stone; keep kindness.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱫᱟᱨᱮ ᱞᱮᱠᱟ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱠᱮᱴᱮᱡ ᱛᱟᱦᱮᱸᱱ ᱞᱟᱹᱠᱛᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Bir dare leka abo sanam hor ketej tahen lakti kana – Like forest trees, we all need to stand strong.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱦᱟᱥᱟ ᱚᱲᱟᱜ ᱨᱮ ᱛᱟᱹᱦᱮᱱ ᱨᱮᱦᱚᱸ, ᱢᱚᱱᱮ ᱫᱚ ᱥᱚᱱᱟ ᱞᱮᱠᱟ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Hasa orag re tahen rehon, mone do sona leka dohoy me – Even though living in a mud house, keep the heart like gold.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱮᱨᱢᱟ ᱤᱯᱤᱞ ᱞᱮᱠᱟ ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱜᱮᱭᱟᱱ ᱮᱢᱟ ᱠᱚᱣᱟ',
            textLatin:
                'Serma ipil leka amaak jiwi do sanam hor geyan ema kowa – Like heavenly stars, let your life give knowledge to everyone.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ ᱩᱢᱩᱞ ᱞᱮᱠᱟ ᱵᱟᱹᱲᱤᱡ ᱚᱠᱛᱚ ᱦᱚᱸ ᱢᱤᱫ ᱫᱤᱱ ᱯᱟᱨᱚᱢᱚᱜ ᱜᱮᱭᱟ',
            textLatin:
                'Njida umul leka barij okto ho mid din paromog geya – Like the night shadow, bad times will also pass one day.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱥᱤᱛᱩᱝ ᱨᱮ ᱠᱟᱹᱢᱤ ᱠᱟᱛᱮ ᱦᱚᱸ ᱟᱹᱛᱩ ᱦᱚᱲ ᱫᱚ ᱠᱚ ᱞᱟᱸᱫᱟᱭᱟ',
            textLatin:
                'Singe situng re kami kate hon atu hor do ko landaya – Even working in the scorching sun, the villagers laugh.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱤᱢᱤᱞ ᱫᱟᱜ ᱛᱮ ᱚᱛ ᱦᱟᱥᱟ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱛᱮ ᱞᱚᱦᱚᱫᱚᱜᱼᱟ',
            textLatin:
                'Rimil dag te ot hasa do adi napay te lohodoga – With cloud rain, the soil gets beautifully soaked.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱨᱢᱚ ᱨᱮ ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱫᱚᱦᱚ ᱜᱮ ᱥᱟᱹᱨᱤ ᱢᱟᱹᱱᱢᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Hor hormo re sari mone doho ge sari manmi kana – Keeping an honest heart in the human body is being a true human.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱵᱤᱞ ᱥᱟᱹᱜᱟᱹᱭ ᱛᱮ ᱟᱹᱛᱩ ᱨᱤᱱ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱩᱢᱤᱫᱽ ᱢᱮᱱᱟᱜ ᱠᱚᱣᱟ',
            textLatin:
                'Sibil sagay te atu rin sanam hor jumid menag kowa – All the villagers are united with affectionate bonding.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱚᱱᱮ ᱠᱮᱴᱮᱡ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱨᱮᱭᱟᱜ ᱞᱟᱹᱲᱦᱟᱹᱭ ᱨᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱢᱮ',
            textLatin:
                'Mone ketej kate amaak jiwi reyag larhay re jitkar me – Win the battle of your life with a strong mind.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱨᱟᱲᱟ ᱠᱟᱛᱮ ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱥᱟᱶ ᱢᱤᱫ ᱢᱮᱱᱟᱜ ᱢᱮᱭᱟ',
            textLatin:
                'Jiwi rara kate sirjoniya saw mid menag meya – With liberated soul, you are one with the Creator.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱜᱟᱹᱰᱤ ᱞᱮᱠᱟ ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱫᱚ ᱫᱟᱭᱟ ᱛᱮ ᱯᱮᱨᱮᱡ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Dular gadi leka amaak jiwi do daya te perej kag me – Like a vehicle of love, fill your life with kindness.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱹᱨᱤ ᱜᱩᱨᱩ ᱣᱟᱜ ᱜᱮᱭᱟᱱ ᱫᱚ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱥᱟᱹᱨᱤ ᱦᱚᱨ ᱮ ᱩᱫᱩᱜ ᱟᱵᱚᱣᱟ',
            textLatin:
                'Sari guru waak geyan do abo sanam hor sari hor e udug abowa – The true teacher\'s knowledge shows all of us the path of truth.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱜᱮᱭᱟᱱ ᱫᱚᱨᱭᱟ ᱨᱮ ᱰᱩᱵᱩᱡ ᱠᱟᱛᱮ ᱥᱟᱹᱨᱤ ᱢᱟᱹᱱᱤᱠ ᱮᱢ ᱧᱟᱢ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Geyan dorya re dubuj kate sari manik em njam dareyaga – By diving into the ocean of knowledge, you can find the true pearl.',
          ),
        ],
      },
      {
        'id': 'lesson_sentences_folk_3',
        'titleLatin': 'Cultural Proverbs & Wisdom III',
        'titleOlChiki': 'ᱞᱟᱠᱪᱟᱨ ᱵᱮᱱᱛᱟ ᱣᱟᱠᱭ ᱓',
        'level': 'advanced',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ ᱦᱚᱨ ᱛᱮ ᱪᱟᱞᱟᱜ ᱜᱮ ᱥᱟᱱᱛᱟᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱹᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Lakchar hor te chalag ge Santal hopon aak man kana – Going on the cultural path is the honor of the Santal people.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱥᱟᱹᱨᱤ ᱛᱮ ᱡᱤᱣᱤ ᱠᱷᱟᱸᱰᱟᱣ ᱜᱮ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Ari sari te jiwi khandaw ge dhorom kana – Living life with pure traditions is righteousness.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱶᱦᱮᱫ ᱡᱤᱣᱤ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱫᱚ ᱵᱟᱧᱪᱟᱣ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Sawhet jiwi kana, onate Santali sawhet do bancaw dohoy me – Literature is the soul, therefore preserve Santali literature.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱷᱚᱨᱚᱢ ᱞᱮᱠᱟᱛᱮ ᱫᱟᱨᱮ ᱟᱨ ᱡᱟᱱᱣᱟᱨ ᱠᱚ ᱫᱩᱞᱟᱹᱲ ᱠᱚ ᱢᱮ',
            textLatin:
                'Sirjon dhorom lekate dare ar janwar ko dular ko me – According to the religion of nature, love the trees and animals.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱤᱥᱚᱢ ᱫᱟᱲᱮ ᱜᱮ ᱟᱵᱚᱣᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱟᱲᱮ ᱠᱟᱱᱟ, ᱚᱱᱟ ᱫᱚ ᱢᱟᱱᱟᱣ ᱢᱮ',
            textLatin:
                'Disom dare ge abowaak marang dare kana, ona do manaw me – The power of the land is our great strength; respect it.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱩᱛᱩᱢ ᱛᱮ ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱧᱩᱛᱩᱢ ᱡᱩᱞᱩᱜ ᱢᱮ',
            textLatin:
                'Sagun nyutum te amaak atu reyag nyutum julug me – Let the name of your village shine with your good name.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱟᱹᱱᱢᱤ ᱫᱷᱚᱨᱚᱢ ᱜᱮ ᱥᱟᱱᱟᱢ ᱠᱷᱚᱱ ᱢᱟᱨᱟᱝ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ, ᱦᱚᱲ ᱥᱮᱵᱟ ᱢᱮ',
            textLatin:
                'Manmi dhorom ge sanam khon marang dhorom kana, hor seba me – Humanity is the greatest religion of all; serve the people.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱥᱤᱵᱤᱞ ᱨᱚᱲ ᱛᱮ ᱟᱹᱛᱩ ᱨᱤᱱ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱢᱚᱱᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱢᱮ',
            textLatin:
                'Amaak sibil ror te atu rin sanam hor mone jitkar me – Win the hearts of all villagers with your sweet words.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱛᱮ ᱠᱟᱹᱢᱤ ᱞᱮᱠᱷᱟᱱ, ᱥᱟᱱᱟᱢ ᱠᱟᱹᱢᱤ ᱜᱮ ᱥᱟᱹᱜᱩᱱ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Sari mone te kami lekhan, sanam kami ge sagun huyuga – If worked with an honest heart, all work will be successful.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱞᱮ ᱚᱲᱟᱜ ᱨᱮ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱥᱤᱵᱤᱞ ᱡᱚᱢ ᱞᱮ ᱵᱮᱱᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Tehenj do ale orag re adi napay sibil jom le benaw akada – Today we have made very delicious food in our home.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱢᱟᱜ ᱜᱟᱛᱮ ᱠᱩᱲᱤ ᱫᱚ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱨᱮ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱮ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Amaak gate kuri do itun asra re adi napay e parhaag kana – Your female friend is studying very well in school.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱫᱤᱱᱟᱹᱢ ᱠᱟᱹᱢᱤ ᱠᱟᱛᱮ ᱦᱚᱲ ᱠᱚ ᱨᱟᱹᱥᱠᱟᱹ ᱛᱮ ᱠᱚ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin:
                'Ale atu re do dinam kami kate hor ko raska te ko tahena – In our village, people live with joy by doing daily chores.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱤᱱ ᱨᱮ ᱟᱢ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱤᱧ ᱟᱹᱰᱤᱧ ᱨᱟᱹᱥᱠᱟᱹ ᱮᱱᱟ',
            textLatin:
                'Sagun din re am saw njapam kate in adinj raska ena – I became very happy to meet you on this auspicious day.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱢᱚᱱᱮ ᱨᱟᱲᱟ ᱠᱟᱛᱮ ᱥᱟᱱᱟᱢ ᱫᱩᱠᱷ ᱫᱚ ᱦᱤᱲᱤᱧ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Amaak mone rara kate sanam dukh do hirinj kag me – Relieving your heart, forget all the sorrows.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱥᱟᱹᱜᱟᱹᱭ ᱜᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱩᱢᱤᱫᱽ ᱫᱚᱦᱚ ᱟᱵᱚᱣᱟ',
            textLatin:
                'Sibil sagay ge abo sanam hor jumid doho abowa – Affectionate bonding keeps all of us united.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱯᱩᱛᱤ ᱠᱟᱛᱷᱟ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱥᱟᱢᱟᱝ ᱨᱮ ᱟᱞᱚᱢ ᱨᱚᱲᱟ',
            textLatin:
                'Guputi katha do sanam hor samang re alom rora – Do not speak secret talks in front of everyone.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱚᱞ ᱞᱮᱠᱟ ᱜᱩᱨᱩ ᱣᱟᱜ ᱥᱮᱪᱮᱫ ᱫᱚ ᱡᱤᱣᱤ ᱨᱮ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Mone ol leka guru waak seched do jiwi re dohoy me – Keep the teacher\'s education in your soul like writing on the heart.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ ᱛᱮ ᱜᱚᱡ ᱞᱮᱠᱟ ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱞᱮ ᱞᱟᱸᱫᱟ ᱠᱮᱫᱟ',
            textLatin:
                'Landa te goj leka tehenj do adi le landa keda – Today we laughed so much as if dying of laughter.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱠᱟᱹᱢᱤ ᱜᱮ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱹᱢᱤ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱟᱢᱟᱜ ᱠᱟᱹᱢᱤ ᱫᱚ ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱛᱮ ᱢᱮ',
            textLatin:
                'Kami ge dhorom kami kana, onate amaak kami do sari mone te me – Work is worship, therefore do your work with an honest heart.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱩᱞᱟᱹᱲ ᱜᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱹᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Disom dular ge sari hor hopon aak man kana – Patriotism is the honor of a true Santal.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱛᱮ ᱟᱢ ᱫᱚ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱥᱟᱱᱛᱤ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Sari katha ror te am do jiwi re sari santi em njama – By speaking the truth, you will find true peace in life.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ ᱠᱟᱛᱮ ᱟᱞᱮ ᱚᱲᱟᱜ ᱨᱮ ᱫᱩᱲᱩᱵ ᱢᱮ ᱜᱟᱛᱮ',
            textLatin:
                'Sagun daram kate ale orag re durub me gate – Being welcomed, sit in our house friend.',
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱡᱤᱨᱟᱹᱣ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱢᱮ',
            textLatin:
                'Napay te jiraw kate amaak geyan hor re lahag me – Resting well, advance on your path of knowledge.',
          ),
        ],
      },
    ];

    for (int i = 0; i < sentenceLessons.length; i++) {
      final lesson = sentenceLessons[i];
      await addLessonIfNew(
        LessonModel(
          id: lesson['id'] as String,
          categoryId: actualSentencesId,
          titleOlChiki: lesson['titleOlChiki'] as String,
          titleLatin: lesson['titleLatin'] as String,
          level: lesson['level'] as String? ?? 'beginner',
          order: i,
          blocks: lesson['blocks'] as List<LessonBlockModel>,
        ),
      );
    }

    return actualSentencesId;
  }
}
