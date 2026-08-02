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
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ',
            textLatin: 'Injaak nyutum do Santhal – My name is Santhal',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱛᱮᱢ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
            textLatin: 'Am do okatem chalag kana? – Where are you going?',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱨᱮᱢ ᱛᱟᱦᱮᱸᱱᱟ?',
            textLatin: 'Am do okarem tahena? – Where do you live?',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱚᱸᱰᱮᱧ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin: 'In do nondenj tahena – I live here',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin: 'Inj donj chalag kana – I am going',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'a young Santhal child classmate putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱭ ᱠᱟᱱᱟᱢ?',
            textLatin: 'Am do okoy kanam? – Who are you?',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱤᱧᱤᱡ ᱵᱚᱠᱚᱧ ᱠᱟᱱᱟᱭ',
            textLatin: 'Uni do injij bokonj kanay – He is my younger brother',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate gently guiding a younger brother by the hand, pointing out a colorful butterfly in the garden. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱩᱭ ᱫᱚ ᱤᱧᱤᱡ ᱜᱟᱛᱮ ᱠᱟᱱᱟᱭ',
            textLatin: 'Nuy do injij gate kanay – This is my friend',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟ ᱠᱷᱚᱱ ᱮᱢ ᱦᱮᱡ ᱮᱱᱟ?',
            textLatin: 'Am do oka khon em hej ena? – Where did you come from?',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱟᱹᱛᱩ ᱠᱷᱚᱱ ᱤᱧ ᱦᱮᱡ ᱮᱱᱟ',
            textLatin: 'Inj do atu khon inj hej ena – I came from the village',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ?',
            textLatin: 'Nowa do ced kana? – What is this?',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱫᱟᱨᱮ ᱠᱟᱱᱟ',
            textLatin: 'Nowa do dare kana – This is a tree',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱪᱮᱫ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin: 'Am do ced em kusiyaga? – What do you like?',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱲ ᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
            textLatin:
                'Inj do Santali ror inj kusiyaga – I like speaking Santali',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'a young Santhal child classmate stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'a young Santhal child classmate putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱟᱢ?',
            textLatin: 'Am do kamiyam? – Do you work?',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱟᱹᱧ',
            textLatin: 'Hẽ, inj do kamiyanj – Yes, I work',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱭᱟ?',
            textLatin: 'Uni do okare menaya? – Where is he/she?',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱚᱲᱟᱜ ᱨᱮ ᱢᱮᱱᱟᱭᱟ',
            textLatin: 'Uni do orag re menaya – He/she is at home',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱧᱮᱞᱮᱫ ᱟᱧᱟᱢ?',
            textLatin: 'Am do nyeled anyam? – Do you see me?',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'a young Santhal child classmate proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
            textLatin: 'Daka jom me – Please eat food',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱧᱩ ᱢᱮ',
            textLatin: 'Dag nju me – Please drink water',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟᱧ',
            textLatin: 'In parhaag kananj – I am studying',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?',
            textLatin: 'Am ced em cikayeda? – What are you doing?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱧ',
            textLatin: 'In do kamiyedanj – I am working',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱛᱩᱢᱫᱟᱜ ᱨᱩ ᱮᱢ ᱵᱟᱰᱟᱭᱟ?',
            textLatin:
                'Am tumdag ru em badaya? – Do you know how to play the drum?',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun laughing and running while balancing a spinning toy disk on a stick, feeling joyful. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱹᱧ ᱵᱟᱰᱟᱭᱟ',
            textLatin: 'Banj badaya – I do not know',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱪᱮᱫ ᱟᱹᱧ ᱢᱮ',
            textLatin: 'Daya kate chet anj me – Please teach me',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱜᱟᱯᱟᱧ ᱪᱮᱫ ᱟᱢᱟ',
            textLatin: 'Hẽ, gapanj chet ama – Yes, I will teach you tomorrow',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹ ᱫᱤᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do adi raska din kana – Today is a very joyful day',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ',
            textLatin: 'Ale orag te hijug me – Come to our house',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱜᱟᱯᱟ ᱱᱩ ᱦᱤᱡᱩᱜᱼᱟ',
            textLatin: 'Inj do gapa nu hijuga – I will come tomorrow',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'a young Santhal child classmate proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱞ ᱪᱤᱠᱤ ᱯᱩᱛᱷᱤ ᱮᱢᱟᱧ ᱢᱮ',
            textLatin:
                'Amaak Ol Chiki puthi emanj me – Give me your Ol Chiki book',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Helping Others',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱤᱧᱟᱜ ᱯᱩᱛᱷᱤ ᱠᱟᱱᱟ',
            textLatin: 'Nowa do injaak puthi kana – This is my book',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Building Confidence',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱤᱨᱭᱳ ᱚᱨᱚᱝ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin:
                'Am do tiryo orong em kusiyaga? – Do you like blowing the flute?',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱛᱤᱨᱭᱳ ᱚᱨᱚᱝ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱵᱤᱞ ᱜᱮᱭᱟ',
            textLatin:
                'Hẽ, tiryo orong do adi sibil geya – Yes, blowing the flute is very sweet',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'a young Santhal child classmate proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱞᱟᱸᱫᱟᱭᱮᱫᱟᱢ ᱪᱮᱫᱟᱜ?',
            textLatin: 'Am do landayedam cedag? – Why are you laughing?',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱨᱟᱹᱥᱠᱟᱹ ᱮᱱᱟᱧ ᱚᱱᱟᱛᱮ',
            textLatin: 'Inj do raska enanj onate – I became happy, that\'s why',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ, ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱟ',
            textLatin: 'Gate, gapa bon njapama – Friend, we will meet tomorrow',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
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
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱱᱟᱯᱟᱭ ᱜᱮ ᱢᱮᱱᱟᱧᱟ',
            textLatin: 'In napay ge menanja – I am fine',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
            textLatin: 'Sagun setag – Good morning',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ',
            textLatin: 'Sagun njida – Good night',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'a young Santhal child classmate kneels in a patch of wild flowers, looking at the colorful petals with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'a young Santhal child classmate demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
            textLatin: 'Ika kanj me – Excuse me / Sorry',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
            textLatin: 'Napay te tahen me – Take care',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'a young Santhal child classmate putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱩᱲᱩᱵ ᱢᱮ',
            textLatin: 'Daya kate durub me – Please sit down',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ, ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ',
            textLatin:
                'Sagun daram, orag te hijug me – Welcome, come inside the house',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'a young Santhal child classmate kneels in a patch of wild flowers, looking at the colorful petals with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱟᱹᱰᱤᱧ ᱨᱟᱹᱥᱠᱟᱹ ᱮᱱᱟ',
            textLatin:
                'Am njapam kate adinj raska ena – I am very happy to meet you',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'a young Santhal child classmate walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'a young Santhal child classmate putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱰᱤ ᱟᱹᱰᱤ ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Adi adi sarhaw – Thank you very much',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'a young Santhal child classmate demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱚᱢ ᱵᱷᱟᱵᱽᱱᱟᱜᱼᱟ, ᱥᱟᱱᱟᱢ ᱱᱟᱯᱟᱭ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Alom bhabnaga, sanam napay huyuga – Don\'t worry, everything will be fine',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱚᱶᱟ ᱠᱟᱹᱢᱤ ᱟᱹᱧ ᱢᱮ',
            textLatin:
                'Daya kate nowa kami anj me – Please help me with this work',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'a young Santhal child classmate carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'a young Santhal child classmate putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱹᱥᱤᱥ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin: 'Amaak asis dohoy me – Keep your blessings',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun playing a traditional hand-drum (tumdak) with an energetic, rhythmic posture and a wide smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱟᱢ ᱥᱟᱨᱦᱟᱣ ᱮᱫ ᱢᱮᱭᱟᱧ',
            textLatin: 'Inj do am sarhaw ed meyaj – I appreciate you',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱨᱚᱲ ᱢᱮ',
            textLatin: 'Daya kate ror me – Please speak',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱥᱮᱱᱚᱜ ᱢᱮ',
            textLatin: 'Napay te senog me – Go safely',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'a young Santhal child classmate kneels in a patch of wild flowers, looking at the colorful petals with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'a young Santhal child classmate demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱨᱟᱝ ᱦᱚᱲ ᱠᱚ ᱢᱟᱱ ᱮᱢᱟ ᱠᱚ ᱢᱮ',
            textLatin:
                'Marang hor ko man ema ko me – Give respect to the elders',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱨᱚᱲ ᱛᱮ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱢᱮ',
            textLatin:
                'Sibil ror te galmaraw me – Speak with gentle/sweet words',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'a young Santhal child classmate sits peacefully under a large shady tree, looking out over the village with a happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'a young Santhal child classmate putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱡᱚᱦᱟᱨ ᱦᱟᱛᱟᱣ ᱢᱮ',
            textLatin: 'Injaak johar hataw me – Accept my greetings',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱟᱹᱭᱩᱵ, ᱜᱟᱛᱮ ᱠᱚ',
            textLatin: 'Sagun ayub, gate ko – Good evening, friends',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'a young Santhal child classmate showing warmth, inclusion, and building a strong social bond.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱛᱤᱱᱟᱹᱜ ᱫᱟᱢ ᱠᱟᱱᱟ?',
            textLatin: 'Nowa do tinag dam kana? – How much is this?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱮ ᱡᱟᱹᱲᱤᱭᱮᱫᱟ',
            textLatin: 'Dag e jariyeda – It is raining',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun standing under a shelter, watching fresh raindrops fall on green leaves, smiling with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱛᱩᱝ ᱠᱟᱱᱟ',
            textLatin: 'Tehenj do adi situng kana – It is very hot today',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱤᱱᱟᱹᱜ ᱵᱟᱡᱟᱣ ᱮᱱᱟ?',
            textLatin: 'Tinag bajaw ena? – What time is it?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱤᱛᱚᱜ ᱫᱚ ᱥᱮᱛᱟᱜ ᱟᱠᱟᱱᱟ',
            textLatin: 'Nitog do setag akana – Now it is morning',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱯᱟ ᱫᱚ ᱨᱟᱵᱟᱝ ᱨᱤᱛᱩ ᱮᱦᱚᱵᱚᱜᱼᱟ',
            textLatin:
                'Gapa do rabang ritu ehoboga – Tomorrow winter season starts',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun lying on a straw mat under a clear night sky, pointing at a shooting star in wonder. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱧᱤᱫᱟᱹ ᱫᱚ ᱟᱹᱰᱤ ᱨᱟᱵᱟᱝ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj njida do adi rabang kana – Tonight it is very cold',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱢᱟ ᱨᱮ ᱨᱤᱢᱤᱞ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin: 'Sirma re rimil menaga – There are clouds in the sky',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ ᱟᱹᱰᱤ ᱡᱩᱨ ᱛᱮ ᱦᱤᱥᱤᱫ ᱠᱟᱱᱟ',
            textLatin:
                'Hoy adi jur te hisid kana – The wind is blowing very hard',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱚᱠᱟ ᱢᱟᱦᱟ ᱠᱟᱱᱟ?',
            textLatin: 'Tehenj do oka maha kana? – What day is today?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱥᱟᱹᱜᱩᱱ ᱢᱟᱦᱟ ᱠᱟᱱᱟ',
            textLatin: 'Tehenj do Sagun maha kana – Today is Wednesday',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱟᱸᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱯᱷᱟ ᱜᱮᱭᱟ',
            textLatin: 'Chando adi sapha geya – The moon is very clear',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun points up at the bright silver crescent moon in the night sky, eyes filled with wonder. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ ᱨᱮ ᱫᱟᱜ ᱛᱮᱛᱟᱝ ᱮᱫ ᱤᱧᱟ',
            textLatin:
                'Situng ritu re dag tetang ed inja – In the summer season, I feel thirsty',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ ᱨᱮ ᱫᱟᱨᱮ ᱠᱚ ᱦᱟᱹᱨᱭᱟᱹᱲᱚᱜᱼᱟ',
            textLatin:
                'Dag ritu re dare ko haryaroga – In the rainy season, the trees turn green',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a lush green rice field, looking around with arms spread wide, feeling connected to the earth. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱞᱟ ᱫᱚ ᱟᱹᱰᱤ ᱡᱩᱨ ᱮ ᱫᱟᱜ ᱠᱮᱫᱟ',
            textLatin:
                'Hola do adi jur e dag keda – Yesterday it rained heavily',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate standing under a shelter, watching fresh raindrops fall on green leaves, smiling with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱥᱮᱨᱢᱟ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱜᱮᱭᱟ',
            textLatin: 'Nowa serma do adi napay geya – This year is very good',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱴᱤᱠᱤᱱ ᱚᱠᱛᱚ ᱠᱟᱱᱟ',
            textLatin: 'Tehenj do tikin okto kana – Today it is noon time',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱭᱩᱵ ᱚᱠᱛᱚ ᱨᱮ ᱜᱟᱛᱮ ᱠᱚ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱢᱮ',
            textLatin:
                'Ayub okto re gate ko saw njapam me – Meet with friends in the evening time',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱠᱛᱚ ᱫᱚ ᱟᱹᱰᱤ ᱫᱟᱢᱟᱱ ᱜᱮᱭᱟ',
            textLatin: 'Okto do adi daman geya – Time is very precious',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱟᱯᱟᱭ ᱜᱮ ᱢᱮᱱᱟᱧᱟ, ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?',
            textLatin:
                'In do napay ge menanja, am ced em cikayeda? – I am doing well, what are you doing?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱚᱞ ᱪᱤᱠᱤ ᱯᱟᱹᱨᱥᱤᱧ ᱪᱮᱫᱚᱜ ᱠᱟᱱᱟ',
            textLatin:
                'In do Ol Chiki parsin chedog kana – I am learning the Ol Chiki language.',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate works carefully on a drawing page spread out on a wooden table, focused and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱠᱟᱛᱷᱟ ᱠᱟᱱᱟ, ᱥᱟᱨᱦᱟᱣ',
            textLatin:
                'Nowa do adi napay katha kana, sarhaw – This is very good news, thank you!',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱲᱟᱜ ᱫᱚ ᱚᱠᱟ ᱟᱹᱛᱩ ᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ?',
            textLatin:
                'Amaak orag do oka atu re menaga? – In which village is your home located?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱚᱲᱟᱜ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱟᱹᱛᱩ ᱨᱮ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Injaak orag do adi napay atu re menaga – My home is in a very beautiful village.',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱞᱚᱢ ᱠᱟᱹᱢᱤᱭᱟ, ᱡᱤᱨᱟᱹᱣ ᱢᱮ',
            textLatin:
                'Tehenj do alom kamiya, jiraw me – Do not work today, take rest.',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱚᱸᱰᱮ ᱦᱤᱡᱩᱜ ᱢᱮ, ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
            textLatin:
                'Daya kate nonde hijug me, daka jom me – Please come here and eat food.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate stands tall in a schoolyard, holding a new notebook and smiling with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱫᱟᱜ ᱧᱩ ᱥᱟᱱᱟᱧ ᱠᱟᱱᱟ, ᱫᱟᱜ ᱮᱢᱟᱧ ᱢᱮ',
            textLatin:
                'In do dag nju sananj kana, dag emanj me – I want to drink water, please give me water.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱦᱚᱨ ᱫᱚ ᱟᱹᱰᱤ ᱡᱤᱞᱤᱧ ᱜᱮᱭᱟ',
            textLatin:
                'Atu reyag hor do adi jilinj geya – The village road is very long.',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate points to a chalkboard showing simple diagrams, looking encouragingly toward classmates. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱭᱳ ᱟᱨ ᱵᱟᱵᱟ ᱫᱚ ᱚᱠᱟᱨᱮ ᱢᱮᱱᱟᱜ ᱠᱤᱱᱟ?',
            textLatin:
                'Amaak ayo ar baba do okare menag kina? – Where are your mother and father?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱠᱤᱱ ᱫᱚ ᱚᱲᱟᱜ ᱨᱮ ᱜᱮ ᱢᱮᱱᱟᱜ ᱠᱤᱱᱟ',
            textLatin:
                'Unkin do orag re ge menag kina – They are right at home.',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate pointing toward a balanced, hand-carved wooden scale, indicating fairness and justice. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱢᱤᱥᱮᱨᱟ ᱫᱚ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱛᱮ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Injaak misera do itun asra te chalag kana – My younger sister is going to school.',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate sitting beside a younger sister, helping her write a word on a clean sand board with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱥᱤᱸᱜᱮ ᱢᱟᱦᱟ ᱠᱟᱱᱟ, ᱪᱷᱩᱴᱤ ᱢᱟᱦᱟ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do Singe maha kana, chuti maha kana – Today is Sunday, it is a holiday.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate looking up at the warm morning sun rising over the hills, eyes filled with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱵᱤᱱ ᱫᱚ ᱚᱠᱟ ᱠᱷᱚᱱ ᱵᱤᱱ ᱦᱤᱡᱩᱜ ᱠᱟᱱᱟ?',
            textLatin:
                'Abin do oka khon bin hijug kana? – Where are you two coming from?',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱤᱨ ᱛᱮᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ, ᱥᱟᱦᱟᱱ ᱞᱟᱹᱜᱤᱫ',
            textLatin:
                'In do bir tenj chalag kana, sahan lagid – I am going to the forest for firewood.',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'a young Santhal child classmate looking at a crackling orange campfire, warm light reflecting on a happy, peaceful face. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱡᱷᱟᱹᱞᱤ ᱫᱟᱜ ᱨᱮᱭᱟᱜ ᱡᱷᱟᱨᱱᱟ ᱢᱮᱱᱟᱜᱼᱟ?',
            textLatin:
                'Amaak atu re do jhale dag reyag jharna menaga? – Is there a clean waterfall in your village?',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱟᱹᱰᱤ ᱥᱤᱵᱤᱞ ᱫᱟᱜ ᱡᱷᱟᱨᱱᱟ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, ale atu re adi sibil dag jharna menaga – Yes, there is a very sweet water spring in our village.',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'a young Santhal child classmate drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'a young Santhal child classmate taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱫᱚ ᱫᱟᱠᱟ ᱟᱨ ᱩᱛᱩ ᱡᱚᱢ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤ ᱛᱮᱧ ᱪᱟᱞᱟᱜᱼᱟ',
            textLatin:
                'Injaak do daka ar utu jom kate kami tenj chalaga – After eating rice and curry, I will go to my work.',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱠᱟᱹᱢᱤ ᱢᱮ ᱜᱟᱛᱮ, ᱥᱟᱹᱜᱩᱱ ᱫᱤᱱ ᱦᱩᱭᱩᱜ ᱛᱟᱢ',
            textLatin:
                'Napay te kami me gate, sagun din huyug tam – Work well friend, have an auspicious day.',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'a young Santhal child classmate exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
        ],
      },
      {
        'id': 'lesson_sentences_complex_intermed',
        'titleLatin': 'Village & Social Life',
        'titleOlChiki': 'ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱜᱟᱞᱢᱟᱨᱟᱣ',
        'level': 'intermediate',
        'blocks': const [
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱡᱟᱦᱮᱨ ᱛᱷᱟᱱ ᱨᱮ ᱠᱚ ᱡᱟᱣᱨᱟ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Atu rin hor do jaher than re ko jawra akana – The villagers have gathered at the sacred grove.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱦᱟᱲᱟᱢ ᱫᱚ ᱟᱹᱛᱩ ᱦᱚᱲ ᱥᱟᱶ ᱮ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱠᱟᱱᱟ',
            textLatin:
                'Manjhi haram do atu hor saw e galmaraw kana – The village headman is talking with the villagers.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱮᱨᱮᱧ ᱠᱚ ᱥᱮᱨᱮᱧ ᱮᱫᱟ',
            textLatin:
                'Tehenj do adi napay Santali serenj ko serenj eda – Today they are singing very beautiful Santali songs.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun playing a traditional hand-drum (tumdak) with an energetic, rhythmic posture and a wide smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱩᱢᱩᱞ ᱨᱮ ᱫᱩᱲᱩᱵ ᱠᱟᱛᱮ ᱩᱱᱠᱩ ᱠᱚ ᱡᱤᱨᱟᱹᱣ ᱠᱟᱱᱟ',
            textLatin:
                'Dare umul re durub kate unku ko jiraw kana – Sitting under the tree\'s shade, they are resting.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱩᱢᱫᱟᱜ ᱟᱨ ᱴᱟᱢᱟᱠ ᱨᱩ ᱮᱢ ᱵᱟᱰᱟᱭᱟ?',
            textLatin:
                'Am do tumdag ar tamak ru em badaya? – Do you know how to play the clay drum and kettle drum?',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Working Together',
              'growthValue': 'Creativity',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱛᱩᱢᱫᱟᱜ ᱨᱩ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱤᱧ ᱵᱟᱰᱟᱭᱟ',
            textLatin:
                'Hẽ, in do tumdag ru adi napay inj badaya – Yes, I know how to play the clay drum very well.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Working Together',
              'growthValue': 'Creativity',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱜᱽᱬᱮ ᱮᱱᱮᱡ ᱞᱟᱹᱜᱤᱫ ᱠᱩᱲᱤ ᱟᱨ ᱠᱚᱲᱟ ᱠᱚ ᱥᱟᱯᱲᱟᱣ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Lagne enej lagid kuri ar kora ko sapraw akana – The boys and girls are ready for the Lagne dance.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Working Together',
              'growthValue': 'Creativity',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱢᱟᱨᱟᱝ ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Ale atu re do adi marang Baha porob huyuga – A very grand Baha festival is celebrated in our village.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱛᱮ ᱠᱩᱲᱤ ᱠᱚ ᱵᱚᱦᱚᱜ ᱠᱚ ᱥᱟᱡᱟᱣ ᱮᱫᱟ',
            textLatin:
                'Sarjom baha te kuri ko bohog ko sajaw eda – The girls are decorating their hair with Sal flowers.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun holding a vibrant wild flower, smelling its scent with a happy, relaxed expression. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱟᱱᱟᱢ ᱨᱩ ᱟᱨ ᱛᱤᱨᱭᱳ ᱚᱨᱚᱝ ᱥᱟᱱᱟᱧ ᱠᱟᱱᱟ',
            textLatin:
                'In do banam ru ar tiryo orong sananj kana – I want to play the fiddle and blow the bamboo flute.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Working Together',
              'growthValue': 'Creativity',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate laughing and running while balancing a spinning toy disk on a stick, feeling joyful. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱮ ᱫᱟᱜ ᱨᱮᱭᱟᱜ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱡᱷᱟᱨᱱᱟ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Atu re dag reyag adi napay jharna menaga – There is a very beautiful water spring in the village.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱢᱚᱱᱮ ᱟᱞᱚᱢ ᱵᱟᱹᱲᱤᱡᱟ, ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱢᱮ',
            textLatin:
                'Amaak mone alom barija, sari katha ror me – Do not ruin your heart, speak the truth.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ ᱫᱚ ᱠᱟᱹᱢᱤ ᱞᱟᱹᱜᱤᱫ ᱴᱟᱺᱰᱤ ᱛᱮ ᱪᱟᱞᱟᱣ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Uni do kami lagid tandi te chalaw akana – He has gone to the field for work.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱹᱫᱷᱩ ᱟᱨ ᱱᱟᱯᱟᱭ ᱜᱮᱭᱟ ᱠᱚ',
            textLatin:
                'Atu rin hor do adi sadhu ar napay geya ko – The village people are very honest and kind.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱡᱩᱨ ᱥᱤᱛᱩᱝ ᱮ ᱮᱢᱟ',
            textLatin:
                'Situng ritu re do adi jur situng e ema – In the summer season, the sun shines very brightly.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun holding a shiny, polished brass plate that reflects the morning sunlight with brilliant rays. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ ᱨᱮ ᱫᱚ ᱜᱟᱰᱟ ᱫᱟᱜ ᱛᱮ ᱯᱮᱨᱮᱡᱚᱜᱼᱟ',
            textLatin:
                'Dag ritu re do gada dag te perejoga – In the rainy season, the river overflows with water.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱢᱟᱹᱧᱡᱷᱤ ᱛᱷᱟᱱ ᱨᱮ ᱡᱟᱣᱨᱟ ᱠᱟᱛᱮ ᱠᱚ ᱵᱤᱪᱟᱹᱨᱮᱫᱟ',
            textLatin:
                'Atu rin hor do Manjhi than re jawra kate bicareda ko – The villagers gather at the headman\'s altar and are discussing.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun playing a traditional hand-drum (tumdak) with an energetic, rhythmic posture and a wide smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ ᱨᱮ ᱠᱩᱲᱤ ᱦᱚᱯᱚᱱ ᱠᱚ ᱦᱟᱥᱟ ᱵᱷᱤᱛ ᱨᱮ ᱪᱤᱛᱟᱹᱨ ᱠᱚ ᱥᱟᱡᱟᱣ ᱮᱫᱟ',
            textLatin:
                'Sohrae porob re kuri hopon ko hasa bhit re citar ko sajaw eda – In the Sohrae festival, the women are decorating the clay walls with paintings.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱛᱩᱢᱫᱟᱜ ᱟᱨ ᱴᱟᱢᱟᱠ ᱨᱩ ᱟᱸᱡᱚᱢ ᱠᱟᱛᱮ ᱠᱚᱲᱟ ᱟᱨ ᱠᱩᱲᱤ ᱠᱚ ᱮᱱᱮᱡ ᱮᱫᱟ',
            textLatin:
                'Tumdag ar tamak ru anjom kate kora ar kuri ko enej eda – Hearing the clay drum and kettle drum, the boys and girls are dancing.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Working Together',
              'growthValue': 'Creativity',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱠᱩᱞᱦᱤ ᱫᱚ ᱥᱟᱹᱜᱩᱱ ᱥᱟᱠᱟᱢ ᱟᱨ ᱵᱟᱦᱟ ᱛᱮ ᱠᱚ ᱥᱟᱡᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Atu reyag kulhi do sagun sakam ar baha te ko sajaw akada – They have decorated the village street with auspicious leaves and flowers.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱦᱚᱲ ᱫᱚ ᱵᱟᱹᱠᱩ ᱨᱚᱲᱟ, ᱚᱱᱟᱛᱮ ᱦᱚᱞᱟ ᱠᱟᱛᱷᱟ ᱫᱚ ᱦᱤᱲᱤᱧ ᱢᱮ',
            textLatin:
                'Goj hor do baku rora, onate hola katha do hirinj me – Dead people do not speak, so forget about yesterday\'s matters.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱛᱩ ᱦᱚᱲ ᱜᱮ ᱫᱤᱥᱚᱢ ᱦᱚᱲ ᱠᱟᱱᱟ ᱠᱚ, ᱡᱩᱢᱤᱫᱽ ᱜᱮ ᱟᱵᱚᱣᱟᱜ ᱫᱟᱲᱮ ᱠᱟᱱᱟ',
            textLatin:
                'Atu hor ge disom hor kana ko, jumid ge abowaak dare kana – The villagers are the country\'s strength; unity is our power.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱟᱜ ᱨᱮ ᱡᱷᱟᱹᱞᱤ ᱵᱟᱹᱭᱥᱟᱹᱣ ᱞᱮᱠᱟ, ᱵᱟᱝ ᱦᱩᱭᱩᱜ ᱠᱟᱹᱢᱤ ᱨᱮ ᱚᱠᱛᱚ ᱟᱞᱚᱢ ᱱᱚᱥᱴᱚᱭᱟ',
            textLatin:
                'Dag re jhale baysaw leka, bang huyug kami re okto alom nostoya – Like setting a net in water, do not waste time on impossible tasks.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱮᱫ ᱞᱩᱴᱩᱨ ᱵᱮᱸᱜᱮᱫ ᱠᱟᱛᱮ ᱪᱟᱞᱟᱜ ᱢᱮ, ᱦᱚᱨ ᱨᱮ ᱟᱹᱰᱤ ᱫᱷᱤᱨᱤ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Med lutur benget kate chalag me, hor re adi dhiri menaga – Keep your eyes and ears open; there are many stones on the road.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱡᱟᱦᱟᱸ ᱞᱮᱠᱟᱢ ᱨᱚᱲᱟ, ᱟᱢ ᱥᱟᱶ ᱦᱚᱲ ᱦᱚᱸ ᱚᱱᱠᱟ ᱜᱮ ᱠᱚ ᱨᱚᱲᱟ',
            textLatin:
                'Am jaha lekam rora, am saw hor ho onka ge ko rora – As you speak, people will speak with you in the same way.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ ᱨᱮ ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱦᱤᱡᱩᱜ ᱢᱮ, ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Sohrae porob re ale orag te hijug me, adi napay huyuga – Come to our home during the Sohrae festival, it will be wonderful.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ ᱛᱮ ᱚᱞ ᱢᱮ, ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱢᱮ',
            textLatin:
                'Guru kolom te ol me, geyan hor re lahag me – Write with the Guru\'s pen, advance on the path of knowledge.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate writing clean Ol Chiki characters on a blackboard with chalk, standing tall with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ ᱟᱨ ᱞᱟᱠᱪᱟᱨ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱩᱯᱨᱩᱢ ᱠᱟᱱᱟ, ᱚᱱᱟ ᱫᱚ ᱵᱟᱧᱪᱟᱣ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Ari chali ar lakchar do abowaak uprum kana, ona do bancaw kag me – Customs and culture are our identity; protect them well.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱲᱮᱢ ᱨᱚᱲ ᱛᱮ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱢᱚᱱᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱢᱮ',
            textLatin:
                'Herem ror te sanam hor mone jitkar me – Win everyone\'s heart with sweet and fluent speech.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱫᱚ ᱱᱚᱶᱟ ᱫᱷᱟᱹᱨᱛᱤ ᱟᱹᱰᱤ ᱪᱮᱦᱨᱟ ᱛᱮ ᱥᱟᱡᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Sirjoniya do nowa dharti adi chehra te sajaw akada – The Creator has decorated this earth beautifully.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱡᱟᱞᱟ ᱨᱮ ᱫᱷᱤᱨᱚᱡᱽ ᱫᱚᱦᱚᱭ ᱢᱮ, ᱢᱤᱫ ᱫᱤᱱ ᱥᱟᱹᱨᱤ ᱜᱮ ᱱᱟᱯᱟᱭ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Amaak jiwi jala re dhiroj dohoy me, mid din sari ge napay huyuga – Keep patience in your life struggles; one day it will surely be good.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ ᱠᱟᱛᱮ ᱟᱹᱰᱤ ᱞᱮᱠᱟᱱ ᱜᱮᱭᱟᱱ ᱮᱢ ᱧᱟᱢ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Disom daran kate adi lekan geyan em njam dareyaga – By traveling the country, you can gain many kinds of knowledge.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱷᱚᱨᱚᱢ ᱠᱟᱹᱢᱤ ᱨᱮ ᱢᱚᱱᱮ ᱞᱟᱜᱟᱣ ᱢᱮ, ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱢᱟᱹᱱ ᱠᱚ ᱮᱢᱟᱢᱟ',
            textLatin:
                'Dhorom kami re mone lagaw me, sanam hor man ko emama – Engage in righteous deeds; everyone will respect you.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate pointing toward a balanced, hand-carved wooden scale, indicating fairness and justice. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱫᱚ ᱟᱹᱰᱤ ᱠᱤᱥᱟᱹᱬ ᱟᱨ ᱜᱟᱹᱦᱤᱨ ᱜᱮᱭᱟ',
            textLatin:
                'Santali sawhet do adi kisan ar gahir geya – Santali literature is very rich and deep.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱟᱨ ᱫᱤᱥᱚᱢ ᱨᱮᱭᱟᱜ ᱧᱩᱛᱩᱢ ᱩᱡᱽᱣᱟᱹᱞ ᱢᱮ',
            textLatin:
                'Olog parhaw kate amaak atu ar disom reyag nyutum ujlaw me – By studying well, brighten the name of your village and country.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate holding a shiny, polished brass plate that reflects the morning sunlight with brilliant rays. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱹᱨᱤ ᱜᱩᱨᱩ ᱣᱟᱜ ᱥᱮᱪᱮᱫ ᱛᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱥᱟᱹᱱᱛᱤ ᱵᱚᱱ ᱧᱟᱢᱟ',
            textLatin:
                'Sari guru waak seched te abo sanam hor jiwi re sari santi bon njama – With the true teacher\'s education, we all find true peace in our lives.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱜᱮᱭᱟᱱ ᱫᱚᱨᱭᱟ ᱨᱮ ᱰᱩᱵᱩᱡ ᱠᱟᱛᱮ ᱟᱢ ᱫᱚ ᱥᱟᱹᱨᱤ ᱫᱷᱚᱨᱚᱢ ᱨᱮᱭᱟᱜ ᱜᱟᱹᱦᱤᱨ ᱠᱟᱛᱷᱟᱢ ᱵᱟᱰᱟᱭ ᱧᱟᱢᱟ',
            textLatin:
                'Geyan dorya re dubuj kate am do sari dhorom reyag gahir katham baday njama – By diving into the ocean of knowledge, you will understand the deep truths of the true religion.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ ᱟᱨ ᱞᱟᱠᱪᱟᱨ ᱵᱟᱧᱪᱟᱣ ᱫᱚᱦᱚ ᱜᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Ari chali ar lakchar bancaw doho ge sari hor hopon aak marang dhorom kana – Preserving customs and culture is the great duty of a true Santal.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ ᱟᱨ ᱡᱩᱢᱤᱫᱽ ᱜᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱥᱩᱠᱷ ᱮ ᱮᱢᱟ ᱵᱚᱱᱟ',
            textLatin:
                'Sirjon dular ar jumid ge abo sanam hor jiwi re sari sukh e ema bona – Love for nature and unity give true happiness in our lives.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
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
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱫᱟᱠᱟ ᱟᱨ ᱡᱮᱞᱤᱧ ᱩᱛᱩᱧ ᱡᱚᱢ ᱠᱮᱫᱟ',
            textLatin:
                'In do daka ar jelinj utunj jom keda – I ate rice and fish curry.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱜᱟᱛᱮ ᱠᱚᱲᱟ ᱫᱚ ᱚᱠᱚᱭ ᱠᱟᱱᱟᱭ?',
            textLatin:
                'Amaak gate kora do okoy kanay? – Who is your male friend?',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱜᱟᱛᱮ ᱠᱚᱲᱟ ᱫᱚ ᱥᱟᱹᱜᱩᱱ ᱠᱟᱱᱟᱭ',
            textLatin:
                'Injaak gate kora do Sagun kanay – My male friend is Sagun.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱮᱦᱮᱧ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱮᱢ ᱪᱟᱞᱟᱣ ᱞᱮᱱᱟ?',
            textLatin:
                'Am do tehenj itun asra em chalaw lena? – Did you go to school today?',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun standing proudly in front of a bright, clean school building, gesturing toward the entrance. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱝ, ᱛᱮᱦᱮᱧ ᱫᱚ ᱪᱷᱩᱴᱤ ᱫᱤᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Bang, tehenj do chuti din kana – No, today is a holiday.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱨᱮ ᱛᱤᱱᱟᱹᱜ ᱚᱲᱟᱜ ᱢᱮᱱᱟᱜᱼᱟ?',
            textLatin:
                'Amaak atu re tinag orag menaga? – How many houses are there in your village?',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱸᱜᱮ ᱚᱲᱟᱜ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Ale atu re do adi sange orag menaga – There are many houses in our village.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱤᱧ ᱥᱟᱶ ᱮᱢ ᱜᱟᱞᱢᱟᱨᱟᱣᱟ?',
            textLatin: 'Am do in saw em galmarawa? – Will you speak with me?',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱟᱢ ᱥᱟᱶ ᱨᱚᱲ ᱟᱹᱰᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, in do am saw ror adinj kusiyaga – Yes, I really like to talk with you.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟ ᱠᱟᱹᱢᱤᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin: 'Am do oka kamim kusiyaga? – Which work do you like?',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱹᱢᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
            textLatin:
                'In do olog parhaw kaminj kusiyaga – I like the work of studying.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱥᱤᱛᱩᱝ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do adi napay situng kana – Today it is very pleasantly sunny.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun looking up at the warm morning sun rising over the hills, eyes filled with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱟᱜ ᱮᱢᱟᱧ ᱢᱮ, ᱤᱧ ᱛᱮᱛᱟᱝ ᱮᱫ ᱤᱧᱟ',
            textLatin:
                'Daya kate dag emanj me, in tetang ed inja – Please give me water, I am thirsty.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱫᱟᱜ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱟᱨ ᱥᱟᱯᱷᱟ ᱜᱮᱭᱟ',
            textLatin:
                'Nowa dag do adi napay ar sapha geya – This water is very good and clean.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱲᱟᱜ ᱨᱮ ᱚᱠᱚᱭ ᱠᱚ ᱢᱮᱱᱟᱜ ᱠᱚᱣᱟ?',
            textLatin:
                'Amaak orag re okoy ko menag kowa? – Who is at your home?',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧᱟᱜ ᱚᱲᱟᱜ ᱨᱮ ᱟᱭᱳ, ᱵᱟᱵᱟ ᱟᱨ ᱢᱤᱥᱮᱨᱟ ᱢᱮᱱᱟᱜ ᱠᱚᱣᱟ',
            textLatin:
                'Injaak orag re ayo, baba ar misera menag kowa – In my home are mother, father, and younger sister.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱛᱤᱥ ᱮᱢ ᱦᱤᱡᱩᱜᱼᱟ?',
            textLatin: 'Am do tis em hijuga? – When will you come?',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱜᱟᱯᱟ ᱥᱮᱛᱟᱜ ᱤᱧ ᱦᱤᱡᱩᱜᱼᱟ',
            textLatin:
                'In do gapa setag inj hijuga – I will come tomorrow morning.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands under the bright sun, showcasing a creative blueprint of a village development project with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱥᱤᱵᱤᱞ ᱨᱚᱲ ᱫᱚ ᱤᱧ ᱟᱹᱰᱤᱧ ᱠᱩᱥᱤᱭᱟᱫᱼᱟ',
            textLatin:
                'Amaak sibil ror do in adinj kusiyada – I really liked your sweet words.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ ᱜᱟᱛᱮ, ᱥᱟᱨᱦᱟᱣ',
            textLatin:
                'Napay te tahen me gate, sarhaw – Stay well friend, thank you.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ, ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱟ',
            textLatin:
                'Sagun njida, gapa bon njapama – Good night, we will meet tomorrow.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
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
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱨᱮᱭᱟᱜ ᱯᱩᱛᱷᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'In do Santali sawhet reyag puthinj parhaag kana – I am reading a book of Santali literature.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱚᱶᱟ ᱯᱩᱛᱷᱤ ᱨᱮ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱠᱟᱛᱷᱟ ᱚᱞ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Nowa puthi re do adi napay katha ol menaga – Very good things are written in this book.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱥᱟᱱᱛᱟᱲᱤ ᱚᱞ ᱪᱤᱠᱤᱢ ᱚᱞ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ?',
            textLatin:
                'Am do Santali Ol Chiki em ol dareyaga? – Can you write Santali Ol Chiki?',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun writing clean Ol Chiki characters on a blackboard with chalk, standing tall with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱚᱞ ᱪᱤᱠᱤᱧ ᱚᱞ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, in do adi napay Ol Chikinj ol dareyaga – Yes, I can write Ol Chiki very well.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate writing clean Ol Chiki characters on a blackboard with chalk, standing tall with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱚᱭ ᱪᱮᱫ ᱟᱫ ᱢᱮᱭᱟᱭ?',
            textLatin: 'Am do okoy chet ad meyay? – Who taught you?',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ ᱫᱚ ᱤᱧᱟᱜ ᱵᱟᱵᱟ ᱟᱨ ᱜᱩᱨᱩ ᱠᱤᱱ ᱪᱮᱫ ᱟᱫ ᱤᱧᱟ',
            textLatin:
                'In do injaak baba ar guru kin chet ad inja – My father and teacher taught me.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'A kind, tall Santhal father and a young Santhal child classmate standing side-by-side, sharing a warm moment as they look over a project. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱛᱩ ᱨᱮ ᱟᱹᱰᱤ ᱢᱟᱨᱟᱝ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱦᱩᱭᱩᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Tehenj do atu re adi marang galmaraw huyug kana – Today a very big discussion is happening in the village.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱱᱟ ᱜᱟᱞᱢᱟᱨᱟᱣ ᱛᱮᱢ ᱪᱟᱞᱟᱜᱼᱟ?',
            textLatin:
                'Am do ona galmaraw tem chalaga? – Will you go to that discussion?',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱥᱟᱶ ᱤᱧ ᱪᱟᱞᱟᱜᱼᱟ',
            textLatin:
                'Hẽ, in do atu rin hor saw inj chalaga – Yes, I will go with the villagers.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱦᱟᱲᱟᱢ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱵᱤᱪᱟᱹᱨ ᱮ ᱮᱢᱟ',
            textLatin:
                'Manjhi haram do adi napay bicar e ema – The village headman gives very good judgment.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱡᱟᱣᱨᱟ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤᱭᱟ ᱠᱚ',
            textLatin:
                'Ale atu rin hor do jawra kate kamiya ko – Our villagers gather and work together.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ ᱜᱮ ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱟᱲᱮ ᱠᱟᱱᱟ',
            textLatin:
                'Jumid ge ale atu reyag marang dare kana – Unity is the great strength of our village.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ ᱫᱚ ᱞᱟᱜᱽᱬᱮ ᱮᱱᱮᱡ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
            textLatin:
                'Am do Lagne enej em kusiyaga? – Do you like the Lagne dance?',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun performing a graceful, traditional dance movement, arms extended with elegance and joy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱞᱟᱜᱽᱬᱮ ᱮᱱᱮᱡ ᱟᱨ ᱥᱮᱨᱮᱧ ᱫᱚ ᱤᱧᱟᱜ ᱡᱤᱣᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Hẽ, Lagne enej ar serenj do injaak jiwi kana – Yes, Lagne dance and song are my life.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate performing a graceful, traditional dance movement, arms extended with elegance and joy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱩᱢᱫᱟᱜ ᱟᱨ ᱴᱟᱢᱟᱠ ᱨᱮᱭᱟᱜ ᱥᱟᱰᱮ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱵᱤᱞ ᱜᱮᱭᱟ',
            textLatin:
                'Tumdag ar tamak reyag sade do adi sibil geya – The sound of the clay drum and kettle drum is very sweet.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱚᱲᱟᱜ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱯᱷᱟ ᱟᱨ ᱪᱮᱦᱨᱟ ᱜᱮᱭᱟ',
            textLatin:
                'Amaak orag do adi sapha ar chehra geya – Your home is very clean and beautiful.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱭᱳ ᱫᱚ ᱫᱤᱱᱟᱹᱢ ᱚᱲᱟᱜ ᱮ ᱥᱟᱯᱷᱟᱭᱟ ᱟᱨ ᱫᱟᱠᱟᱭᱟ',
            textLatin:
                'Ayo do dinam orag e saphaya ar dakaya – Mother cleans the house and cooks rice every day.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps a young Santhal child classmate adjust a neat shoulder bag. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱵᱟ ᱫᱚ ᱴᱟᱺᱰᱤ ᱛᱮ ᱪᱟᱞᱟᱣ ᱟᱠᱟᱱᱟᱭ, ᱪᱟᱥ ᱠᱟᱹᱢᱤ ᱞᱟᱹᱜᱤᱫ',
            textLatin:
                'Baba do tandi te chalaw akanay, chas kami lagid – Father has gone to the field for farming.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱞᱮ ᱫᱚ ᱟᱹᱰᱤ ᱥᱟᱹᱫᱷᱩ ᱟᱨ ᱱᱟᱯᱟᱭ ᱡᱤᱣᱤ ᱞᱮ ᱠᱷᱟᱸᱰᱟᱣᱮᱫᱟ',
            textLatin:
                'Ale do adi sadhu ar napay jiwi le khandaweda – We live a very simple and peaceful life.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ ᱜᱮ ᱟᱞᱮᱭᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Sirjon dular ge aleyaak marang dhorom kana – Love for nature is our great religion.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱢᱮ, ᱡᱤᱣᱤ ᱨᱮ ᱥᱩᱠᱷ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Sari katha ror me, jiwi re sukh em njama – Speak the truth, you will find happiness in life.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
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
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱫᱚ ᱱᱟᱶᱟ ᱟᱹᱛᱩ ᱟᱨ ᱱᱟᱶᱟ ᱦᱚᱲ ᱧᱮᱞ ᱤᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Hẽ, in do nawa atu ar nawa hor njel inj chalag kana – Yes, I am going to see new villages and new people.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ ᱠᱟᱛᱮ ᱟᱹᱰᱤ ᱞᱮᱠᱟᱱ ᱜᱮᱭᱟᱱ ᱧᱟᱢᱚᱜᱼᱟ',
            textLatin:
                'Disom daran kate adi lekan geyan njamoga – Traveling the country brings many kinds of knowledge.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱡᱟᱞᱟ ᱨᱮ ᱫᱷᱤᱨᱚᱡᱽ ᱫᱚᱦᱚᱭ ᱢᱮ, ᱡᱤᱛᱠᱟᱹᱨ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Amaak jiwi jala re dhiroj dohoy me, jitkar em njama – Keep patience in your life struggles, you will achieve victory.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱮᱴᱮᱡ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤ ᱢᱮ, ᱫᱟᱲᱮ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Mone ketej kate kami me, dare em njama – Work with a strong mind, you will find strength.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱨᱤᱱ ᱦᱚᱲ ᱫᱚ ᱵᱤᱨ ᱫᱟᱨᱮ ᱞᱮᱠᱟ ᱠᱮᱴᱮᱡ ᱜᱮᱭᱟ ᱠᱚ',
            textLatin:
                'Atu rin hor do bir dare leka ketej geya ko – The village people are as strong as the forest trees.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱥᱟᱠᱟᱢ ᱛᱮ ᱟᱹᱰᱤ ᱞᱮᱠᱟᱱ ᱨᱟᱱ ᱵᱮᱱᱟᱣᱚᱜᱼᱟ',
            textLatin:
                'Dare sakam te adi lekan ran benawoga – Many kinds of medicines are made from tree leaves.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱵᱟᱧᱪᱟᱣ ᱞᱟᱹᱜᱤᱫ ᱟᱹᱛᱩ ᱦᱚᱲ ᱠᱚ ᱥᱟᱯᱲᱟᱣ ᱟᱠᱟᱱᱟ',
            textLatin:
                'Bir bancaw lagid atu hor ko sapraw akana – The villagers are ready to protect the forest.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ ᱨᱮ ᱟᱞᱮ ᱚᱲᱟᱜ ᱛᱮ ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ ᱢᱮᱱᱟᱜ ᱢᱮᱭᱟ',
            textLatin:
                'Sohrae porob re ale orag te sagun daram menag meya – You are welcome to our house during the Sohrae festival.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱞᱮ ᱚᱲᱟᱜ ᱨᱮ ᱫᱚ ᱦᱟᱥᱟ ᱨᱮᱭᱟᱜ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱵᱷᱤᱛ ᱪᱤᱛᱟᱹᱨ ᱢᱮᱱᱟᱜᱼᱟ',
            textLatin:
                'Ale orag re do hasa reyag adi napay bhit citar menaga – There are very beautiful clay wall paintings in our home.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱭᱳ ᱫᱚ ᱦᱟᱥᱟ ᱵᱷᱤᱛ ᱨᱮ ᱟᱹᱰᱤ ᱪᱮᱦᱨᱟ ᱪᱤᱛᱟᱹᱨ ᱮ ᱵᱮᱱᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Ayo do hasa bhit re adi chehra citar e benaw akada – Mother has drawn very beautiful paintings on the clay wall.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps Olitun adjust a neat shoulder bag. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵ ᱨᱮ ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱛᱮ ᱵᱚᱸᱜᱟ ᱛᱷᱟᱱ ᱞᱮ ᱥᱟᱡᱟᱣᱟ',
            textLatin:
                'Baha porob re sarjom baha te bonga than le sajawa – In the Baha festival, we decorate the place of worship with Sal flowers.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate holding a vibrant wild flower, smelling its scent with a happy, relaxed expression. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱞᱟᱹᱜᱤᱫ ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ ᱟᱹᱰᱤ ᱞᱟᱹᱠᱛᱤ ᱜᱮᱭᱟ',
            textLatin:
                'Geyan hor re lahag lagid olog parhaw adi lakti geya – Studying is very necessary to advance on the path of knowledge.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ ᱛᱮ ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱥᱮᱨᱢᱟ ᱨᱮ ᱚᱞ ᱢᱮ',
            textLatin:
                'Guru kolom te amaak nyutum serma re ol me – Write your name in the sky with the Guru\'s pen.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'a young Santhal child classmate writing clean Ol Chiki characters on a blackboard with chalk, standing tall with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'a young Santhal child classmate aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ ᱟᱨ ᱞᱟᱠᱪᱟᱨ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱢᱟᱨᱟᱝ ᱩᱯᱨᱩᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Ari chali ar lakchar do abowaak marang uprum kana – Customs and culture are our great identity.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱲᱮᱢ ᱨᱚᱲ ᱛᱮ ᱟᱹᱛᱩ ᱦᱚᱲ ᱢᱚᱱᱮ ᱨᱮ ᱡᱟᱭᱜᱟ ᱵᱮᱱᱟᱣ ᱢᱮ',
            textLatin:
                'Herem ror te atu hor mone re jayga benaw me – Make a place in the hearts of the villagers with sweet speech.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱛᱮ ᱱᱚᱶᱟ ᱫᱷᱟᱹᱨᱛᱤ ᱮ ᱥᱤᱨᱡᱚᱱ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Sirjoniya do adi napay te nowa dharti e sirjon akada – The Creator has created this earth very beautifully.',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱢᱟᱜ ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱛᱮ ᱠᱟᱹᱢᱤ ᱢᱮ, ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱟᱹᱥᱤᱥ ᱮ ᱮᱢᱟᱢᱟ',
            textLatin:
                'Amaak sari mone te kami me, sirjoniya asis e emama – Work with your honest heart, the Creator will bless you.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'a young Santhal child classmate carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱯᱟᱲᱦᱟᱣ ᱠᱟᱛᱮ ᱤᱧ ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹᱧ ᱧᱟᱢ ᱠᱮᱫᱟ',
            textLatin:
                'Santali sawhet parhaw kate in adi raskanj njam keda – I found great joy by reading Santali literature.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱵᱤᱱ ᱫᱚ ᱛᱮᱦᱮᱧ ᱚᱠᱟ ᱛᱮ ᱵᱤᱱ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
            textLatin:
                'Abin do tehenj oka te bin chalag kana? – Where are you two going today?',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱞᱤᱧ ᱫᱚ ᱵᱤᱨ ᱛᱮ ᱞᱤᱧ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ, ᱥᱟᱦᱟᱱ ᱞᱟᱹᱜᱤᱫ',
            textLatin:
                'Alinj do bir te linj chalag kana, sahan lagid – We two are going to the forest for firewood.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun looking at a crackling orange campfire, warm light reflecting on a happy, peaceful face. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱪᱟᱞᱟᱣ ᱠᱟᱛᱮ ᱨᱩᱣᱟᱹᱲ ᱦᱤᱡᱩᱜ ᱢᱮ, ᱡᱚᱦᱟᱨ',
            textLatin:
                'Napay te chalaw kate ruwar hijug me, johar – Go safely and return, greetings.',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands in a clean, modern learning space, gesturing toward a screen showing village success metrics. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'a young Santhal child classmate expressing optimism for progress, new opportunities, and future success.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱦᱚᱲ ᱨᱚᱲ ᱵᱩᱨᱩ ᱨᱚᱲ, ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱫᱚ ᱛᱤᱥᱦᱚᱸ ᱵᱟᱝ ᱵᱚᱫᱚᱞᱚᱜᱼᱟ',
            textLatin:
                'Hor ror buru ror, sari katha do tishon bang bodologa – Man\'s word is as firm as the hill; the truth never changes.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱮ ᱡᱟᱱᱟᱢ ᱞᱮᱠᱟ, ᱟᱢᱟᱜ ᱢᱚᱱᱮ ᱫᱚ ᱥᱟᱯᱷᱟ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Dag re janam leka, amaak mone do sapha dohoy me – Like being born in water, keep your heart clean.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱦᱚᱲᱢᱚ ᱫᱚ ᱢᱤᱫ ᱫᱤᱱ ᱦᱟᱥᱟ ᱨᱮ ᱜᱮ ᱢᱮᱥᱟᱜᱼᱟ',
            textLatin:
                'Hasa hormo do mid din hasa re ge mesaga – The clay body will one day mix into the clay.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱮᱸᱜᱮᱞ ᱡᱤᱣᱤ ᱛᱟᱹᱦᱮᱱ ᱠᱷᱟᱱ, ᱡᱟᱦᱟᱸ ᱠᱟᱹᱢᱤ ᱜᱮ ᱦᱩᱭ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Sengel jiwi tahen khan, jaha kami ge huy dareyaga – If there is a fiery soul, any work can be accomplished.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ ᱞᱮᱠᱟ ᱫᱟᱹᱲ ᱠᱟᱛᱮ ᱚᱠᱛᱚ ᱟᱞᱚᱢ ᱱᱚᱥᱴᱚᱭᱟ',
            textLatin:
                'Hoy leka dar kate okto alom nostoya – Do not waste time by running like the wind.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱩᱢᱩᱞ ᱨᱮ ᱫᱩᱲᱩᱵ ᱠᱟᱛᱮ ᱟᱹᱛᱩ ᱦᱚᱲ ᱠᱚ ᱡᱤᱨᱟᱹᱣ ᱠᱟᱱᱟ',
            textLatin:
                'Bir umul re durub kate atu hor ko jiraw kana – The villagers are resting by sitting under the forest\'s shade.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱥᱟᱠᱟᱢ ᱛᱮ ᱟᱹᱛᱩ ᱨᱟᱱ ᱵᱮᱱᱟᱣ ᱠᱟᱛᱮ ᱦᱚᱲ ᱠᱚ ᱵᱮᱥᱚᱜᱼᱟ',
            textLatin:
                'Dare sakam te atu ran benaw kate hor ko besoga – People get cured by making village medicines from tree leaves.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱡᱤᱣᱤ ᱡᱟᱹᱞᱤ ᱨᱮ ᱛᱟᱹᱦᱮᱱ ᱞᱮᱠᱟ, ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱩᱢᱤᱫᱽ ᱛᱟᱦᱮᱸᱱ ᱞᱟᱹᱠᱛᱤ ᱜᱮᱭᱟ',
            textLatin:
                'Jiwi jhale re tahen leka, abo sanam hor jumid tahen lakti geya – As if living in the web of life, it is necessary for all of us to remain united.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱥᱮᱨᱢᱟ ᱨᱮ ᱤᱯᱤᱞ ᱠᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱠᱚ ᱡᱩᱞᱩᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Sari serma re ipil ko adi napay ko julug kana – Stars shine very beautifully in the true heavens.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate lying on a straw mat under a clear night sky, pointing at a shooting star in wonder. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱠᱩᱫᱩᱢ ᱠᱟᱛᱷᱟ ᱛᱮ ᱟᱹᱛᱩ ᱦᱟᱲᱟᱢ ᱫᱚ ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ ᱜᱮᱭᱟᱱ ᱮ ᱮᱢᱟ ᱠᱚᱣᱟ',
            textLatin:
                'Kudum katha te atu haram do gidra ko geyan e ema kowa – The village elder gives knowledge to children through riddles.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱮᱱᱛᱟ ᱨᱚᱲ ᱛᱮ ᱟᱢᱟᱜ ᱠᱟᱛᱷᱟ ᱫᱚ ᱜᱟᱹᱦᱤᱨ ᱛᱮ ᱥᱚᱫᱚᱨ ᱢᱮ',
            textLatin:
                'Benta ror te amaak katha do gahir te sodor me – Present your words deeply with idiomatic speech.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱲᱟᱢ ᱠᱟᱛᱷᱟ ᱫᱚ ᱟᱵᱚᱣᱟᱜ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱨ ᱮ ᱩᱫᱩᱜᱼᱟ',
            textLatin:
                'Haram katha do abowaak jiwi re sari hor e uduga – Ancestral wisdom shows the true path in our lives.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱵᱩᱰᱷᱤ ᱩᱭᱦᱟᱹᱨ ᱛᱮ ᱚᱲᱟᱜ ᱨᱮᱭᱟᱜ ᱜᱷᱟᱨᱚᱸᱡᱽ ᱫᱚ ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin:
                'Budhi uyhar te orag reyag gharonj do napay te tahena – The household remains peaceful with the wise grandmother\'s advice.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps a young Santhal child classmate adjust a neat shoulder bag. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱟᱹᱨᱤ ᱞᱮᱠᱟᱛᱮ ᱥᱟᱱᱟᱢ ᱯᱚᱨᱚᱵ ᱞᱮ ᱢᱟᱱᱟᱣᱟ',
            textLatin:
                'Atu ari lekate sanam porob le manawa – We celebrate all festivals according to the village customs.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ ᱫᱟᱲᱮ ᱜᱮ ᱥᱟᱱᱛᱟᱲ ᱥᱚᱢᱟᱡᱽ ᱨᱮᱭᱟᱜ ᱢᱟᱨᱟᱝ ᱛᱷᱟᱹᱭ ᱠᱟᱱᱟ',
            textLatin:
                'Jumid dare ge Santal somaj reyag marang thay kana – Unity is the great pillar of the Santal society.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱥᱮᱨᱮᱧ ᱟᱸᱡᱚᱢ ᱠᱟᱛᱮ ᱡᱤᱣᱤ ᱨᱟᱹᱥᱠᱟᱹ ᱛᱮ ᱯᱮᱨᱮᱡᱚᱜᱼᱟ',
            textLatin:
                'Sohrae serenj anjom kate jiwi raska te perejoga – Listening to Sohrae songs fills the soul with joy.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱥᱟᱠᱟᱢ ᱨᱮ ᱥᱟᱨᱡᱚᱢ ᱵᱟᱦᱟ ᱫᱚᱦᱚ ᱠᱟᱛᱮ ᱞᱮ ᱵᱚᱸᱜᱟᱭᱟ',
            textLatin:
                'Baha sakam re sarjom baha doho kate le bongaya – We worship by keeping Sal flowers on Baha leaves.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate holding a vibrant wild flower, smelling its scent with a happy, relaxed expression. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱩᱢᱩᱞ ᱨᱮ ᱟᱞᱮ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱱᱟᱯᱟᱭ ᱛᱮ ᱞᱮ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin:
                'Jaher umul re ale do sanam hor napay te le tahena – Under the protection of the sacred grove, we all live peacefully.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱵᱤᱪᱟᱹᱨ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱠᱚ ᱢᱟᱱᱟᱣ ᱵᱟᱛᱟᱣᱟ',
            textLatin:
                'Manjhi bicar do sanam hor ko manaw batawa – Everyone respects and accepts the headman\'s judgment.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱫᱷᱚᱨᱚᱢ ᱞᱮᱠᱟᱛᱮ ᱡᱤᱣᱤ ᱠᱷᱟᱸᱰᱟᱣ ᱜᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱨ ᱠᱟᱱᱟ',
            textLatin:
                'Hor dhorom lekate jiwi khandaw ge sari hor kana – Living life according to the Santal way is the true path.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ ᱜᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱤᱣᱤ ᱨᱮ ᱫᱚᱦᱚ ᱞᱟᱹᱠᱛᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Sirjon dular ge abo sanam hor jiwi re doho lakti kana – It is necessary for all of us to keep love for nature in our lives.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps Olitun adjust a neat shoulder bag. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱡᱟᱱᱣᱟᱨ ᱠᱚ ᱵᱟᱧᱪᱟᱣ ᱫᱚ ᱵᱤᱨ ᱨᱮᱭᱟᱜ ᱥᱩᱱᱫᱚᱨ ᱠᱟᱱᱟ',
            textLatin:
                'Bir janwar ko bancaw do bir reyag sundor kana – Protecting wild beasts is the beauty of the forest.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱟᱠᱟᱢ ᱛᱮ ᱟᱹᱛᱩ ᱦᱚᱲ ᱠᱚ ᱱᱟᱶᱟ ᱥᱟᱹᱜᱩᱱ ᱠᱚ ᱧᱟᱢᱟ',
            textLatin:
                'Sagun sakam te atu hor ko nawa sagun ko njama – Through the auspicious leaf, the villagers receive new good omens.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun collecting fallen autumn leaves in a basket, helping to clean the yard with a smile. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱟᱹᱱᱢᱤ ᱜᱮᱭᱟᱱ ᱛᱮ ᱱᱚᱶᱟ ᱫᱷᱟᱹᱨᱛᱤ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱛᱮ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Manmi geyan te nowa dharti adi napay te chalag kana – With human wisdom, this earth functions very beautifully.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱜᱤᱰᱤ ᱞᱮᱠᱟ ᱵᱟᱹᱲᱤᱡ ᱠᱟᱛᱷᱟ ᱫᱚ ᱢᱚᱱᱮ ᱠᱷᱚᱱ ᱜᱤᱰᱤ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Goj gidi leka barij katha do mone khon gidi kag me – Throw away bad thoughts from the heart like discarded waste.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱛᱚᱞ ᱠᱟᱛᱮ ᱡᱟᱦᱟᱸᱭ ᱠᱟᱹᱢᱤᱭᱟ, ᱩᱱᱤ ᱫᱚ ᱡᱤᱛᱠᱟᱹᱨ ᱜᱮᱭᱟᱭ',
            textLatin:
                'Jiwi tol kate jahay kamiya, uni do jitkar geyay – Whoever works with dedicated soul is victorious.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱛᱷᱟᱹᱭ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱢᱮ',
            textLatin:
                'Mone thay kate amaak geyan hor re lahag me – Advance on your path of knowledge with a firm decision.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱡᱚᱢ ᱠᱟᱛᱮ ᱦᱚᱲ ᱟᱞᱚᱢ ᱮᱲᱮ ᱠᱚᱣᱟ, ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱢᱮ',
            textLatin:
                'Luti jom kate hor alom ere kowa, sari katha ror me – Do not deceive people with false promises; speak the truth.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱩ ᱛᱮ ᱨᱟᱠᱟᱵ ᱞᱮᱠᱟ ᱨᱟᱸᱜᱟᱣ ᱫᱚ ᱢᱚᱱᱮ ᱵᱟᱹᱲᱤᱡᱟ, ᱥᱟᱱᱛ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
            textLatin:
                'Mu te rakab leka rangaw do mone barija, sant tahen me – Anger like flaring nostrils ruins the heart; remain calm.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱫᱷᱤᱨᱤ ᱞᱮᱠᱟ ᱢᱚᱱᱮ ᱫᱚ ᱟᱞᱚᱢ ᱠᱮᱴᱮᱡᱟ, ᱫᱟᱭᱟ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Dag dhiri leka mone do alom keteja, daya dohoy me – Do not harden your heart like a wet stone; keep kindness.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱫᱟᱨᱮ ᱞᱮᱠᱟ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱠᱮᱴᱮᱡ ᱛᱟᱦᱮᱸᱱ ᱞᱟᱹᱠᱛᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Bir dare leka abo sanam hor ketej tahen lakti kana – Like forest trees, we all need to stand strong.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱦᱟᱥᱟ ᱚᱲᱟᱜ ᱨᱮ ᱛᱟᱹᱦᱮᱱ ᱨᱮᱦᱚᱸ, ᱢᱚᱱᱮ ᱫᱚ ᱥᱚᱱᱟ ᱞᱮᱠᱟ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Hasa orag re tahen rehon, mone do sona leka dohoy me – Even though living in a mud house, keep the heart like gold.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate works with rich brown clay, sculpting a small toy pot with focused, creative hands. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱮᱨᱢᱟ ᱤᱯᱤᱞ ᱞᱮᱠᱟ ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱜᱮᱭᱟᱱ ᱮᱢᱟ ᱠᱚᱣᱟ',
            textLatin:
                'Serma ipil leka amaak jiwi do sanam hor geyan ema kowa – Like heavenly stars, let your life give knowledge to everyone.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun lying on a straw mat under a clear night sky, pointing at a shooting star in wonder. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ ᱩᱢᱩᱞ ᱞᱮᱠᱟ ᱵᱟᱹᱲᱤᱡ ᱚᱠᱛᱚ ᱦᱚᱸ ᱢᱤᱫ ᱫᱤᱱ ᱯᱟᱨᱚᱢᱚᱜ ᱜᱮᱭᱟ',
            textLatin:
                'Njida umul leka barij okto ho mid din paromog geya – Like the night shadow, bad times will also pass one day.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱥᱤᱛᱩᱝ ᱨᱮ ᱠᱟᱹᱢᱤ ᱠᱟᱛᱮ ᱦᱚᱸ ᱟᱹᱛᱩ ᱦᱚᱲ ᱫᱚ ᱠᱚ ᱞᱟᱸᱫᱟᱭᱟ',
            textLatin:
                'Singe situng re kami kate hon atu hor do ko landaya – Even working in the scorching sun, the villagers laugh.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun looking up at the warm morning sun rising over the hills, eyes filled with hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱤᱢᱤᱞ ᱫᱟᱜ ᱛᱮ ᱚᱛ ᱦᱟᱥᱟ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱛᱮ ᱞᱚᱦᱚᱫᱚᱜᱼᱟ',
            textLatin:
                'Rimil dag te ot hasa do adi napay te lohodoga – With cloud rain, the soil gets beautifully soaked.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate standing under a shelter, watching fresh raindrops fall on green leaves, smiling with curiosity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱨᱢᱚ ᱨᱮ ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱫᱚᱦᱚ ᱜᱮ ᱥᱟᱹᱨᱤ ᱢᱟᱹᱱᱢᱤ ᱠᱟᱱᱟ',
            textLatin:
                'Hor hormo re sari mone doho ge sari manmi kana – Keeping an honest heart in the human body is being a true human.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱤᱵᱤᱞ ᱥᱟᱹᱜᱟᱹᱭ ᱛᱮ ᱟᱹᱛᱩ ᱨᱤᱱ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱩᱢᱤᱫᱽ ᱢᱮᱱᱟᱜ ᱠᱚᱣᱟ',
            textLatin:
                'Sibil sagay te atu rin sanam hor jumid menag kowa – All the villagers are united with affectionate bonding.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱚᱱᱮ ᱠᱮᱴᱮᱡ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱨᱮᱭᱟᱜ ᱞᱟᱹᱲᱦᱟᱹᱭ ᱨᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱢᱮ',
            textLatin:
                'Mone ketej kate amaak jiwi reyag larhay re jitkar me – Win the battle of your life with a strong mind.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱨᱟᱲᱟ ᱠᱟᱛᱮ ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ ᱥᱟᱶ ᱢᱤᱫ ᱢᱮᱱᱟᱜ ᱢᱮᱭᱟ',
            textLatin:
                'Jiwi rara kate sirjoniya saw mid menag meya – With liberated soul, you are one with the Creator.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱜᱟᱹᱰᱤ ᱞᱮᱠᱟ ᱟᱢᱟᱜ ᱡᱤᱣᱤ ᱫᱚ ᱫᱟᱭᱟ ᱛᱮ ᱯᱮᱨᱮᱡ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Dular gadi leka amaak jiwi do daya te perej kag me – Like a vehicle of love, fill your life with kindness.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱹᱨᱤ ᱜᱩᱨᱩ ᱣᱟᱜ ᱜᱮᱭᱟᱱ ᱫᱚ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱥᱟᱹᱨᱤ ᱦᱚᱨ ᱮ ᱩᱫᱩᱜ ᱟᱵᱚᱣᱟ',
            textLatin:
                'Sari guru waak geyan do abo sanam hor sari hor e udug abowa – The true teacher\'s knowledge shows all of us the path of truth.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱜᱮᱭᱟᱱ ᱫᱚᱨᱭᱟ ᱨᱮ ᱰᱩᱵᱩᱡ ᱠᱟᱛᱮ ᱥᱟᱹᱨᱤ ᱢᱟᱹᱱᱤᱠ ᱮᱢ ᱧᱟᱢ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
            textLatin:
                'Geyan dorya re dubuj kate sari manik em njam dareyaga – By diving into the ocean of knowledge, you can find the true pearl.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱥᱟᱹᱨᱤ ᱛᱮ ᱡᱤᱣᱤ ᱠᱷᱟᱸᱰᱟᱣ ᱜᱮ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ',
            textLatin:
                'Ari sari te jiwi khandaw ge dhorom kana – Living life with pure traditions is righteousness.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate pointing toward a balanced, hand-carved wooden scale, indicating fairness and justice. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱶᱦᱮᱫ ᱡᱤᱣᱤ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ ᱫᱚ ᱵᱟᱧᱪᱟᱣ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Sawhet jiwi kana, onate Santali sawhet do bancaw dohoy me – Literature is the soul, therefore preserve Santali literature.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱷᱚᱨᱚᱢ ᱞᱮᱠᱟᱛᱮ ᱫᱟᱨᱮ ᱟᱨ ᱡᱟᱱᱣᱟᱨ ᱠᱚ ᱫᱩᱞᱟᱹᱲ ᱠᱚ ᱢᱮ',
            textLatin:
                'Sirjon dhorom lekate dare ar janwar ko dular ko me – According to the religion of nature, love the trees and animals.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate planting a young green seedling in rich soil, showing care and responsibility for nature. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱫᱤᱥᱚᱢ ᱫᱟᱲᱮ ᱜᱮ ᱟᱵᱚᱣᱟᱜ ᱢᱟᱨᱟᱝ ᱫᱟᱲᱮ ᱠᱟᱱᱟ, ᱚᱱᱟ ᱫᱚ ᱢᱟᱱᱟᱣ ᱢᱮ',
            textLatin:
                'Disom dare ge abowaak marang dare kana, ona do manaw me – The power of the land is our great strength; respect it.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱩᱛᱩᱢ ᱛᱮ ᱟᱢᱟᱜ ᱟᱹᱛᱩ ᱨᱮᱭᱟᱜ ᱧᱩᱛᱩᱢ ᱡᱩᱞᱩᱜ ᱢᱮ',
            textLatin:
                'Sagun nyutum te amaak atu reyag nyutum julug me – Let the name of your village shine with your good name.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱢᱟᱹᱱᱢᱤ ᱫᱷᱚᱨᱚᱢ ᱜᱮ ᱥᱟᱱᱟᱢ ᱠᱷᱚᱱ ᱢᱟᱨᱟᱝ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱱᱟ, ᱦᱚᱲ ᱥᱮᱵᱟ ᱢᱮ',
            textLatin:
                'Manmi dhorom ge sanam khon marang dhorom kana, hor seba me – Humanity is the greatest religion of all; serve the people.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱥᱤᱵᱤᱞ ᱨᱚᱲ ᱛᱮ ᱟᱹᱛᱩ ᱨᱤᱱ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱢᱚᱱᱮ ᱡᱤᱛᱠᱟᱹᱨ ᱢᱮ',
            textLatin:
                'Amaak sibil ror te atu rin sanam hor mone jitkar me – Win the hearts of all villagers with your sweet words.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱛᱮ ᱠᱟᱹᱢᱤ ᱞᱮᱠᱷᱟᱱ, ᱥᱟᱱᱟᱢ ᱠᱟᱹᱢᱤ ᱜᱮ ᱥᱟᱹᱜᱩᱱ ᱦᱩᱭᱩᱜᱼᱟ',
            textLatin:
                'Sari mone te kami lekhan, sanam kami ge sagun huyuga – If worked with an honest heart, all work will be successful.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun looking forward toward a modern skyline in the distance, eyes filled with determination and hope. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱞᱮ ᱚᱲᱟᱜ ᱨᱮ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱥᱤᱵᱤᱞ ᱡᱚᱢ ᱞᱮ ᱵᱮᱱᱟᱣ ᱟᱠᱟᱫᱟ',
            textLatin:
                'Tehenj do ale orag re adi napay sibil jom le benaw akada – Today we have made very delicious food in our home.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱢᱟᱜ ᱜᱟᱛᱮ ᱠᱩᱲᱤ ᱫᱚ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱨᱮ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱮ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟ',
            textLatin:
                'Amaak gate kuri do itun asra re adi napay e parhaag kana – Your female friend is studying very well in school.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱟᱞᱮ ᱟᱹᱛᱩ ᱨᱮ ᱫᱚ ᱫᱤᱱᱟᱹᱢ ᱠᱟᱹᱢᱤ ᱠᱟᱛᱮ ᱦᱚᱲ ᱠᱚ ᱨᱟᱹᱥᱠᱟᱹ ᱛᱮ ᱠᱚ ᱛᱟᱦᱮᱸᱱᱟ',
            textLatin:
                'Ale atu re do dinam kami kate hor ko raska te ko tahena – In our village, people live with joy by doing daily chores.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱤᱱ ᱨᱮ ᱟᱢ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱤᱧ ᱟᱹᱰᱤᱧ ᱨᱟᱹᱥᱠᱟᱹ ᱮᱱᱟ',
            textLatin:
                'Sagun din re am saw njapam kate in adinj raska ena – I became very happy to meet you on this auspicious day.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢᱟᱜ ᱢᱚᱱᱮ ᱨᱟᱲᱟ ᱠᱟᱛᱮ ᱥᱟᱱᱟᱢ ᱫᱩᱠᱷ ᱫᱚ ᱦᱤᱲᱤᱧ ᱠᱟᱜ ᱢᱮ',
            textLatin:
                'Amaak mone rara kate sanam dukh do hirinj kag me – Relieving your heart, forget all the sorrows.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱥᱟᱹᱜᱟᱹᱭ ᱜᱮ ᱟᱵᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱡᱩᱢᱤᱫᱽ ᱫᱚᱦᱚ ᱟᱵᱚᱣᱟ',
            textLatin:
                'Sibil sagay ge abo sanam hor jumid doho abowa – Affectionate bonding keeps all of us united.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱯᱩᱛᱤ ᱠᱟᱛᱷᱟ ᱫᱚ ᱥᱟᱱᱟᱢ ᱦᱚᱲ ᱥᱟᱢᱟᱝ ᱨᱮ ᱟᱞᱚᱢ ᱨᱚᱲᱟ',
            textLatin:
                'Guputi katha do sanam hor samang re alom rora – Do not speak secret talks in front of everyone.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱚᱞ ᱞᱮᱠᱟ ᱜᱩᱨᱩ ᱣᱟᱜ ᱥᱮᱪᱮᱫ ᱫᱚ ᱡᱤᱣᱤ ᱨᱮ ᱫᱚᱦᱚᱭ ᱢᱮ',
            textLatin:
                'Mone ol leka guru waak seched do jiwi re dohoy me – Keep the teacher\'s education in your soul like writing on the heart.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ ᱛᱮ ᱜᱚᱡ ᱞᱮᱠᱟ ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱞᱮ ᱞᱟᱸᱫᱟ ᱠᱮᱫᱟ',
            textLatin:
                'Landa te goj leka tehenj do adi le landa keda – Today we laughed so much as if dying of laughter.',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'a young Santhal child classmate gestures toward a village map drawn on a board, explaining a plan to classmates with confidence. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'a young Santhal child classmate acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki:
                'ᱠᱟᱹᱢᱤ ᱜᱮ ᱫᱷᱚᱨᱚᱢ ᱠᱟᱹᱢᱤ ᱠᱟᱱᱟ, ᱚᱱᱟᱛᱮ ᱟᱢᱟᱜ ᱠᱟᱹᱢᱤ ᱫᱚ ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ ᱛᱮ ᱢᱮ',
            textLatin:
                'Kami ge dhorom kami kana, onate amaak kami do sari mone te me – Work is worship, therefore do your work with an honest heart.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱩᱞᱟᱹᱲ ᱜᱮ ᱥᱟᱹᱨᱤ ᱦᱚᱲ ᱦᱚᱯᱚᱱ ᱟᱜ ᱢᱟᱹᱱ ᱠᱟᱱᱟ',
            textLatin:
                'Disom dular ge sari hor hopon aak man kana – Patriotism is the honor of a true Santal.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'a young Santhal child classmate stands proudly at a crossroads in the village, pointing toward a path of opportunity. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'a young Santhal child classmate enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ ᱨᱚᱲ ᱛᱮ ᱟᱢ ᱫᱚ ᱡᱤᱣᱤ ᱨᱮ ᱥᱟᱹᱨᱤ ᱥᱟᱱᱛᱤ ᱮᱢ ᱧᱟᱢᱟ',
            textLatin:
                'Sari katha ror te am do jiwi re sari santi em njama – By speaking the truth, you will find true peace in life.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ ᱠᱟᱛᱮ ᱟᱞᱮ ᱚᱲᱟᱜ ᱨᱮ ᱫᱩᱲᱩᱵ ᱢᱮ ᱜᱟᱛᱮ',
            textLatin:
                'Sagun daram kate ale orag re durub me gate – Being welcomed, sit in our house friend.',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'a young Santhal child classmate smiling warmly while pointing happily toward the learner, conveying friendship and belonging. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'a young Santhal child classmate celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱡᱤᱨᱟᱹᱣ ᱠᱟᱛᱮ ᱟᱢᱟᱜ ᱜᱮᱭᱟᱱ ᱦᱚᱨ ᱨᱮ ᱞᱟᱦᱟᱜ ᱢᱮ',
            textLatin:
                'Napay te jiraw kate amaak geyan hor re lahag me – Resting well, advance on your path of knowledge.',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story. Show only the speaking character, never show both speakers in the same frame.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
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
