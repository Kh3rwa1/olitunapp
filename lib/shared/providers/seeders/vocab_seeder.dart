import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/categories/data/models/category_model.dart';
import '../../../features/lessons/data/models/lesson_model.dart';
import '../providers.dart';

class VocabSeeder {
  static Future<String> seed(
    WidgetRef ref,
    Future<String> Function(CategoryModel) addCategoryIfNew,
    Future<void> Function(LessonModel) addLessonIfNew,
  ) async {
    final wordsNotifier = ref.read(wordsProvider.notifier);

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
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Sarhaw – Thank you',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱸ',
            textLatin: 'Hẽ – Yes',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱝ',
            textLatin: 'Bang – No',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
            textLatin: 'Sagun Daram – Welcome',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱨᱟᱝ',
            textLatin: 'Marang – Big / Great',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱩᱰᱤᱧ',
            textLatin: 'Hudinj – Small',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ',
            textLatin: 'Sagun – Auspicious / Good',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱟᱯᱟᱭ',
            textLatin: 'Napay – Fine / Good',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱰᱤ',
            textLatin: 'Adi – Very',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱮᱞᱮᱠᱟ',
            textLatin: 'Celeka – How',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱩᱛᱩᱢ',
            textLatin: 'Nyutum – Name',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱧ',
            textLatin: 'Inj – I / Me',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱢ',
            textLatin: 'Am – You',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱩᱱᱤ',
            textLatin: 'Uni – He / She',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱱᱩᱭ',
            textLatin: 'Nuy – This person',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱠᱚᱭ',
            textLatin: 'Okoy – Who',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱮᱫ',
            textLatin: 'Ced – What',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱠᱟ',
            textLatin: 'Oka – Which',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ',
            textLatin: 'Jumid – Unity',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
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
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱭᱳ',
            textLatin: 'Ayo – Mother',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps Olitun adjust a neat shoulder bag.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱳᱲᱟᱜ ᱦᱚᱲ',
            textLatin: 'Orag hor – Spouse / Family member',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun standing proudly with a family member in front of a neat, decorated village home.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱫᱟ',
            textLatin: 'Dada – Elder brother',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'An older brother pointing toward the hills, explaining the weather patterns to Olitun with a confident smile.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱹᱭ',
            textLatin: 'Dai – Elder sister',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun and an older sister reading a storybook together, both looking at the pages with shared focus.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱚᱠᱚᱧ',
            textLatin: 'Bokonj – Younger brother',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun gently guiding a younger brother by the hand, pointing out a colorful butterfly in the garden.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱤᱥᱮᱨᱟ',
            textLatin: 'Misera – Younger sister',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun sitting beside a younger sister, helping her write a word on a clean sand board with pride.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱲᱚᱢ ᱦᱟᱲᱟᱢ',
            textLatin: 'Gorom haram – Grandfather',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱲᱚᱢ ᱵᱩᱰᱷᱤ',
            textLatin: 'Gorom budhi – Grandmother',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps Olitun adjust a neat shoulder bag.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱠᱟ',
            textLatin: 'Kaka – Uncle (father\'s younger brother)',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱠᱤ',
            textLatin: 'Kaki – Aunt (father\'s younger brother\'s wife)',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱢᱚ',
            textLatin: 'Mamo – Maternal Uncle',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun watching with interest as a kind uncle tunes a traditional stringed banam instrument.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱛᱚᱢ',
            textLatin: 'Hatom – Aunt (father\'s sister)',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱝᱜᱚ',
            textLatin: 'Gongo – Uncle (father\'s elder brother)',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'A kind, tall Santhal father and Olitun standing side-by-side, sharing a warm moment as they look over a project.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱹᱦᱩ',
            textLatin: 'Bahu – Wife / Daughter-in-law',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱶᱟᱭ',
            textLatin: 'Jaway – Husband / Son-in-law',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱮᱴᱟ',
            textLatin: 'Beta – Son',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱴᱤ',
            textLatin: 'Biti – Daughter',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ',
            textLatin: 'Gate – Friend',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱯᱚᱱ',
            textLatin: 'Hopon – Child / Son',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱠᱟ',
            textLatin: 'Daka – Cooked Rice / Food',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱳᱲᱟᱜ',
            textLatin: 'Orag – Home / House',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱤᱪᱨᱤᱡ',
            textLatin: 'Kicrij – Cloth',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱨ',
            textLatin: 'Hor – Path / Road',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ',
            textLatin: 'Atu – Village',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱴᱟᱠᱟ',
            textLatin: 'Taka – Money',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱢ',
            textLatin: 'Jom – Eat',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱩ',
            textLatin: 'Nju – Drink',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱤᱛᱤᱡ',
            textLatin: 'Gitij – Sleep',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱟᱞᱟᱜ',
            textLatin: 'Chalag – Go',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱤᱡᱩᱜ',
            textLatin: 'Hijug – Come',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱹᱢᱤ',
            textLatin: 'Kami – Work',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model, demonstrating capability and responsibility.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱲᱩᱵ',
            textLatin: 'Durub – Sit',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱸᱜᱚ',
            textLatin: 'Tengo – Stand',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱞ',
            textLatin: 'Ol – Write',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun writing clean Ol Chiki characters on a blackboard with chalk, standing tall with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱟᱲᱦᱟᱣ',
            textLatin: 'Parhaw – Read / Study',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ',
            textLatin: 'Ror – Speak / Language',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱱᱚᱜ',
            textLatin: 'Senog – Depart / Go',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ',
            textLatin: 'Landa – Laugh',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
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
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱥᱟᱝ',
            textLatin: 'Sasang – Yellow',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun holds up a bright yellow sunflower, smiling warmly under the bright sunlight of the field.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱹᱨᱭᱟᱹᱲ',
            textLatin: 'Haryar – Green',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands in a lush green rice field, looking around with arms spread wide, feeling connected to the earth.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱩᱸᱰ',
            textLatin: 'Pund – White',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun points happily to a pristine white jasmine flower blooming on a green bush in the garden.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱱᱫᱮ',
            textLatin: 'Hende – Black',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun looks at a glossy black obsidian stone found near the stream, holding it up to catch the light with wonder.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱤᱞ',
            textLatin: 'Lil – Blue',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun points to the deep blue sky dotted with fluffy white clouds, eyes shining with curiosity.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱢᱟᱹᱝ',
            textLatin: 'Lumang – Golden / Silk color',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun admires a strand of golden raw silk thread, holding it up to watch it shimmer in the sun.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱨᱚᱝ',
            textLatin: 'Hasa rong – Brown / Mud color',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun works with rich brown clay, sculpting a small toy pot with focused, creative hands.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱞᱟᱹᱯ',
            textLatin: 'Gulap – Pink',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun holding a soft pink lotus flower gently, smiling at its beautiful petals.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱮᱸᱜᱟᱲ',
            textLatin: 'Bengad – Purple / Eggplant color',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun harvesting a ripe, glossy purple eggplant from the garden, looking proud of the yield.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱭᱞᱟᱹ',
            textLatin: 'Kuyla – Charcoal / Deep black',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun holding a piece of black charcoal, sketching a clean drawing on a stone tablet with focus.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱟᱸᱫᱚ ᱨᱚᱝ',
            textLatin: 'Chando rong – Silver / Moon color',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun points up at the bright silver crescent moon in the night sky, eyes filled with wonder.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱸᱜᱮᱞ ᱨᱚᱝ',
            textLatin: 'Sengel rong – Orange / Fire color',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun looking at a crackling orange campfire, warm light reflecting on a happy, peaceful face.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱠᱟᱢ ᱨᱚᱝ',
            textLatin: 'Sakam rong – Leaf green',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun compares two different shades of green leaves, looking closely with curious eyes.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱢᱟ ᱨᱚᱝ',
            textLatin: 'Sirma rong – Sky blue',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits on a grassy hill, looking up at the vast sky-blue horizon with a hopeful expression.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱨᱚᱝ',
            textLatin: 'Med rong – Eye color',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱨ',
            textLatin: 'Lar – Indigo',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱚᱢᱠᱟᱣ',
            textLatin: 'Comkaw – Shiny / Bright',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun holding a shiny, polished brass plate that reflects the morning sunlight with brilliant rays.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱤᱞᱚᱱ',
            textLatin: 'Milon – Mixed color',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun mixing different colored clay on a wooden board, laughing with creative excitement.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱷᱟᱹᱱᱰᱤᱭᱟᱹ',
            textLatin: 'Khandiya – Dark shade / Grey',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun looking at a smooth grey river pebble, feeling its texture with a curious, calm expression.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
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
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱩᱥᱤ',
            textLatin: 'Pusi – Cat',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱨᱳᱢ',
            textLatin: 'Merom – Goat',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱹᱭ',
            textLatin: 'Gai – Cow',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱟᱹᱨᱩᱵ',
            textLatin: 'Tarub – Tiger',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱪᱮᱬᱮ',
            textLatin: 'Cene – Bird',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱹᱠᱩ',
            textLatin: 'Haku – Fish',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ',
            textLatin: 'Dare – Tree',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ',
            textLatin: 'Baha – Flower',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun holding a vibrant wild flower, smelling its scent with a happy, relaxed expression.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱹᱛᱤ',
            textLatin: 'Hati – Elephant',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱞ',
            textLatin: 'Kul – Lion',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱧ',
            textLatin: 'Binj – Snake',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱫᱚᱢ',
            textLatin: 'Sadom – Horse',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱷᱤᱰᱤ',
            textLatin: 'Bhidi – Sheep',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱰᱟ',
            textLatin: 'Kada – Buffalo',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱩᱠᱨᱤ',
            textLatin: 'Sukri – Pig',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱢ',
            textLatin: 'Sim – Chicken / Hen',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ',
            textLatin: 'Serma – Sky',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱯᱤᱞ',
            textLatin: 'Ipil – Star',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun lying on a straw mat under a clear night sky, pointing at a shooting star in wonder.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ',
            textLatin: 'Singe – Sun',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun looking up at the warm morning sun rising over the hills, eyes filled with hope.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱦᱟ',
            textLatin: 'Maha – Day',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱮᱦᱮᱧ',
            textLatin: 'Tehenj – Today',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱯᱟ',
            textLatin: 'Gapa – Tomorrow',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱞᱟ',
            textLatin: 'Hola – Yesterday',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ',
            textLatin: 'Situng ritu – Summer',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱤᱛᱩ',
            textLatin: 'Dag ritu – Rainy Season',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun standing under a shelter, watching fresh raindrops fall on green leaves, smiling with curiosity.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ',
            textLatin: 'Serma – Year',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱠᱛᱚ',
            textLatin: 'Okto – Time',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ',
            textLatin: 'Njida – Night',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱛᱟᱜ',
            textLatin: 'Setag – Morning',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱴᱤᱠᱤᱱ',
            textLatin: 'Tikin – Noon',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱭᱩᱵ',
            textLatin: 'Ayub – Evening',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱟᱵᱟᱝ ᱨᱤᱛᱩ',
            textLatin: 'Rabang ritu – Winter',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱢᱟᱦᱟ',
            textLatin: 'Singe maha – Sunday',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun looking up at the warm morning sun rising over the hills, eyes filled with hope.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱛᱮ ᱢᱟᱦᱟ',
            textLatin: 'Ote maha – Monday',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱞᱮ ᱢᱟᱦᱟ',
            textLatin: 'Bale maha – Tuesday',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱢᱟᱦᱟ',
            textLatin: 'Sagun maha – Wednesday',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱫᱤ ᱢᱟᱦᱟ',
            textLatin: 'Sardi maha – Thursday',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱹᱨᱩᱢ ᱢᱟᱦᱟ',
            textLatin: 'Jarum maha – Friday',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ',
            textLatin: 'Santali – Santali',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
            textLatin: 'Ol Chiki – Ol Chiki Script',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱯᱩᱛᱷᱤ',
            textLatin: 'Puthi – Book',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows slightly with colorful learning patterns.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱛᱩᱱ ᱟᱥᱲᱟ',
            textLatin: 'Itun asra – School',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun standing proudly in front of a bright, clean school building, gesturing toward the entrance as a symbol of opportunity and growth.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ',
            textLatin: 'Disom – Country',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ',
            textLatin: 'Hor – People',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ',
            textLatin: 'Guru kolom – Guru\'s Pen / Scholar',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ',
            textLatin: 'Lakchar – Culture',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱪᱮᱫ',
            textLatin: 'Seched – Education',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱶᱦᱮᱫ',
            textLatin: 'Sawhet – Literature',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱢᱟᱡᱽ',
            textLatin: 'Somaj – Society',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ',
            textLatin: 'Jumid – Unity',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ',
            textLatin: 'Ari chali – Customs',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱪᱟᱹᱨ',
            textLatin: 'Bicar – Justice / Discussion',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ ᱠᱚ',
            textLatin: 'Gate ko – Friends',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Sari dhorom – Truth path / Traditional religion',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱟᱹᱥᱠᱟᱹ',
            textLatin: 'Raska – Joy / Happiness',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱦᱟᱣ ᱠᱟᱛᱷᱟ',
            textLatin: 'Sarhaw katha – Words of appreciation',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱛᱷᱟᱱ',
            textLatin: 'Jaher than – Sacred grove',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
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
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱠᱟᱛᱷᱟ',
            textLatin: 'Sari katha – Truth / True words',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱨᱚᱲ',
            textLatin: 'Sibil ror – Gentle speech / Kind words',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱹᱢᱤ ᱜᱮ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Kami ge dhorom – Work is worship',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model, demonstrating capability and responsibility.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱩᱞᱟᱹᱲ',
            textLatin: 'Disom dular – Patriotism / Country love',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱟᱨᱟᱢ',
            textLatin: 'Sagun daram – Warm welcome',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱷᱤᱨᱤ',
            textLatin: 'Dhiri – Stone',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱤᱛᱤᱞ',
            textLatin: 'Gitil – Sand',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱸᱜᱮᱞ',
            textLatin: 'Sengel – Fire',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun looking at a crackling orange campfire, warm light reflecting on a happy, peaceful face.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ',
            textLatin: 'Hoy – Air / Wind',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱤᱢᱤᱞ',
            textLatin: 'Rimil – Cloud',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱤᱯᱤᱞ',
            textLatin: 'Ipil – Star',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun lying on a straw mat under a clear night sky, pointing at a shooting star in wonder.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ',
            textLatin: 'Njida – Night',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱢᱟᱦᱟ',
            textLatin: 'Singe maha – Sunday',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun looking up at the warm morning sun rising over the hills, eyes filled with hope.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱛ',
            textLatin: 'Ot – Earth / Ground',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ',
            textLatin: 'Serma – Sky / Year',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Making New Friend',
              'growthValue': 'Communication',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun kneels in a patch of wild flowers, looking at the colorful petals with curiosity.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ',
            textLatin: 'Bir – Forest',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Exploring Village',
              'growthValue': 'Confidence',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱩᱨᱩ',
            textLatin: 'Buru – Mountain / Hill',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun sits peacefully under a large shady tree, looking out over the village with a happy smile.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱰᱟ',
            textLatin: 'Gada – River',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun discovering a clear, flowing spring in the forest, pointing at the clean water.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱷᱟᱨᱱᱟ',
            textLatin: 'Jharna – Spring / Waterfall',
            data: {
              'emotion': 'Curiosity',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy.',
              'bodyLanguage':
                  'Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.',
              'learningMoment':
                  'Olitun demonstrating active observation and a love for finding out new things.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱦᱟᱱ',
            textLatin: 'Sahan – Firewood',
            data: {
              'emotion': 'Kindness',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Learning',
              'characterGoal': 'Explore nature',
              'imageDirection':
                  'Olitun looking at a crackling orange campfire, warm light reflecting on a happy, peaceful face.',
              'bodyLanguage':
                  'Gentle smile, soft eyes, hands offering help or gesturing politely with care.',
              'learningMoment':
                  'Olitun putting empathy into action, helping classmates or respecting elders.',
            },
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
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱞᱟᱰᱮ',
            textLatin: 'Mone lade – Discouraged / Dejected',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱡᱟᱞᱟ',
            textLatin: 'Jiwi jala – Life struggles',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱩᱢᱩᱞ ᱦᱚᱲ ᱩᱢᱩᱞ',
            textLatin:
                'Dare umul hor umul – Protection of elders / Family shelter',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun standing proudly with a family member in front of a neat, decorated village home.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱛᱟ ᱡᱷᱟᱹᱞᱤ ᱞᱮᱠᱟ',
            textLatin: 'Seta jhale leka – Entangled in trouble / Trapped',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱᱢᱤ ᱡᱤᱣᱤ',
            textLatin: 'Manmi jiwi – Human life',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱ ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Man sarhaw – Respect and praise',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱜᱽᱬᱮ',
            textLatin: 'Lagne – Traditional Santal dance',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun performing a graceful, traditional dance movement, arms extended with elegance and joy.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱚᱝ',
            textLatin: 'Dong – Marriage dance and song genre',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun performing a graceful, traditional dance movement, arms extended with elegance and joy.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱩᱢᱫᱟᱜ',
            textLatin: 'Tumdag – Clay drum / Madal',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱴᱟᱢᱟᱠ',
            textLatin: 'Tamak – Kettle drum',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun playing a traditional hand-drum (tumdak) with an energetic, rhythmic posture and a wide smile.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱱᱟᱢ',
            textLatin: 'Banam – Traditional single-stringed fiddle',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun playing a traditional hand-drum (tumdak) with an energetic, rhythmic posture and a wide smile.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱛᱤᱨᱭᱳ',
            textLatin: 'Tiryo – Bamboo flute',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱨᱡᱚᱢ',
            textLatin: 'Sarjom – Sal tree (sacred to Santals)',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱛᱠᱟᱹᱢ',
            textLatin: 'Matkam – Mahua flower/fruit',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun holding a vibrant wild flower, smelling its scent with a happy, relaxed expression.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱚᱦᱟᱨ ᱠᱟᱛᱷᱟ',
            textLatin: 'Johar katha – Welcoming words',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱞᱦᱤ',
            textLatin: 'Kulhi – Village street',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱛᱷᱟᱱ',
            textLatin: 'Jaher than – Sacred grove',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱛᱷᱟᱱ',
            textLatin: 'Manjhi than – Village headman\'s altar',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works carefully on a drawing page spread out on a wooden table, focused and happy.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱦᱚᱲ',
            textLatin: 'Atu hor – Villagers',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Helping Others',
              'growthValue': 'Confidence',
              'characterGoal': 'Help someone',
              'imageDirection':
                  'Olitun stands tall in a schoolyard, holding a new notebook and smiling with pride.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱲᱟᱢ ᱵᱩᱰᱷᱤ',
            textLatin: 'Haram budhi – Ancestors / Old couple',
            data: {
              'emotion': 'Responsibility',
              'storyArc': 'Building Confidence',
              'growthValue': 'Responsibility',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun proudly holds a hand-painted wooden sign, smiling warmly with confidence.',
              'bodyLanguage':
                  'Focused and attentive expression, steady hands working carefully, steady stance.',
              'learningMoment':
                  'Olitun taking charge of duties, caring for the environment or community.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱠᱟ ᱩᱛᱩ',
            textLatin: 'Daka utu – Rice and curry / Meal',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Learning New Things',
              'growthValue': 'Learning',
              'characterGoal': 'Practice communication',
              'imageDirection':
                  'Olitun points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱩ ᱛᱮ ᱦᱚᱭ ᱚᱰᱚᱠ',
            textLatin: 'Mu te hoy odok – Snorting in rage / Proud',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱮ ᱡᱷᱟᱹᱞᱤ ᱵᱟᱹᱭᱥᱟᱹᱣ',
            textLatin:
                'Dag re jhale baysaw – Chasing shadows / Setting net in water',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱜᱮ ᱡᱤᱣᱤ',
            textLatin: 'Dare ge jiwi – Trees are life / Environmental wisdom',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱚᱡ ᱦᱚᱲ ᱫᱚ ᱵᱟᱹᱠᱩ ᱨᱚᱲᱟ',
            textLatin:
                'Goj hor do baku rora – Dead people do not speak / Let bygones be bygones',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱦᱚᱲ ᱜᱮ ᱫᱤᱥᱚᱢ ᱦᱚᱲ',
            textLatin:
                'Atu hor ge disom hor – Village community is the country\'s strength',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱠᱷᱚᱱ ᱫᱟᱜ ᱡᱚᱨᱚ',
            textLatin: 'Med khon dag joro – Weeping bitterly / Deep grief',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱵᱟᱹᱲᱤᱡ',
            textLatin: 'Mone barij – Feel sad / Heart-broken',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱠᱟᱛᱷᱟ',
            textLatin: 'Dular katha – Loving words / Kind speech',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱫᱷᱚᱱ',
            textLatin: 'Jiwi dhon – Wealth of life / Beloved',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱨᱟᱱ',
            textLatin: 'Disom daran – Traveling / Exploring the land',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱷᱚᱨᱚᱢ ᱠᱟᱹᱢᱤ',
            textLatin: 'Dhorom kami – Righteous deed / Virtuous work',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model, demonstrating capability and responsibility.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱯᱚᱨᱚᱵ',
            textLatin: 'Sohrae porob – Harvest festival / Sohrae',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱯᱚᱨᱚᱵ',
            textLatin: 'Baha porob – Spring festival / Flower festival',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun holding a vibrant wild flower, smelling its scent with a happy, relaxed expression.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱥᱟᱶᱦᱮᱫ',
            textLatin: 'Santali sawhet – Santali literature',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱨᱩ ᱠᱚᱞᱚᱢ',
            textLatin: 'Guru kolom – The pen of the Guru / Education',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱞᱚᱜ ᱯᱟᱲᱦᱟᱣ',
            textLatin: 'Olog parhaw – Education / Learning',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱮᱭᱟᱱ ᱦᱚᱨ',
            textLatin: 'Geyan hor – Path of knowledge',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ',
            textLatin: 'Lakchar – Culture',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱪᱟᱹᱞᱤ',
            textLatin: 'Ari chali – Customs and traditions',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱮᱲᱮᱢ ᱨᱚᱲ',
            textLatin: 'Herem ror – Sweet words / Fluent speech',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱᱤᱭᱟᱹ',
            textLatin: 'Sirjoniya – Creator / Nature',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
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
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun laughing and running while balancing a spinning toy disk on a stick, feeling joyful.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱛᱮ ᱞᱟᱸᱫᱟ',
            textLatin: 'Ror te landa – Smiling through words / Sarcasm',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱡᱟᱹᱞᱤ',
            textLatin: 'Dular jhale – Love trap',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱥᱟᱢᱟᱝ',
            textLatin: 'Hor samang – Public / In front of people',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱞᱟᱲᱟᱣ',
            textLatin: 'Luti laraw – Chatting / Gossip',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱛᱷᱟ ᱠᱤᱨᱤᱧ',
            textLatin: 'Katha kirinj – Buying words / Accepting advice',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱞᱚ',
            textLatin: 'Jiwi lo – Heartburn / Jealousy',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱚᱞ',
            textLatin: 'Mone ol – Writing on heart / Deeply remembering',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱮᱫ ᱫᱟᱜ',
            textLatin: 'Med dag – Tears',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ ᱛᱮ ᱜᱚᱡ',
            textLatin: 'Landa te goj – Dying of laughter',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱲᱤ ᱦᱚᱯᱚᱱ',
            textLatin: 'Kuri hopon – Women / Girls',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱚᱲᱟ ᱦᱚᱯᱚᱱ',
            textLatin: 'Kora hopon – Men / Boys',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ ᱠᱩᱲᱤ',
            textLatin: 'Gate kuri – Female friend',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱟᱛᱮ ᱠᱚᱲᱟ',
            textLatin: 'Gate kora – Male friend',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱩᱯᱩᱛᱤ ᱠᱟᱛᱷᱟ',
            textLatin: 'Guputi katha – Secret talk / Whisper',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱟᱹᱥᱠᱟᱹ ᱢᱚᱱᱮ',
            textLatin: 'Raska mone – Joyful mind / Happy heart',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱠᱷ ᱡᱤᱣᱤ',
            textLatin: 'Dukh jiwi – Sorrowful life',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱢᱚᱱᱮ',
            textLatin: 'Hor mone – Public opinion / Human heart',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱡᱚᱢ',
            textLatin: 'Sibil jom – Delicious food',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱲᱮ ᱩᱫᱩᱜ',
            textLatin: 'Dare udug – Show of strength',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱴᱷᱟᱶ',
            textLatin: 'Mone thaw – Settled mind / Contentment',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱞᱟᱹᱱᱟᱹᱭ',
            textLatin: 'Ror lanay – Reply / Answer',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱠᱟᱹᱢᱤ',
            textLatin: 'Dinam kami – Daily chore',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱫᱤᱱ',
            textLatin: 'Sagun din – Auspicious day',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱢᱚᱱᱮ',
            textLatin: 'Sari mone – Honest heart',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
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
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun lying on a straw mat under a clear night sky, pointing at a shooting star in wonder.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱩᱨ ᱠᱷᱟᱲᱟ',
            textLatin: 'Lutur khara – Pricking ears / Listening intently',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱛᱷᱟ ᱨᱟᱹᱯᱩᱫ',
            textLatin: 'Katha rapud – Breaking words / Interrupting',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱦᱟᱹᱴᱤᱧ',
            textLatin: 'Mone hatinj – Sharing feelings / Divided mind',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱡᱩᱞ',
            textLatin: 'Jiwi jul – Burning life / Passionate / Angry',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱸᱫᱟ ᱛᱷᱚᱠ',
            textLatin: 'Landa thok – Weary of laughing',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱪᱮᱦᱨᱟ',
            textLatin: 'Ror chehra – Beautiful speech',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱫᱟᱲᱮ',
            textLatin: 'Mone dare – Willpower / Mental strength',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱟᱹᱭ ᱛᱚᱞ',
            textLatin: 'Sagay tol – Binding relationship / Making friends',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱛᱷᱟ ᱛᱚᱞ',
            textLatin: 'Katha tol – Finalizing a promise',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱨᱟᱲᱟ',
            textLatin: 'Mone rara – Relieved / Free mind',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱛᱟᱦᱮᱸᱱ',
            textLatin: 'Jiwi tahen – Staying alive / Living well',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱜᱟᱛᱮ',
            textLatin: 'Dular gate – Sweetheart / Dear friend',
            data: {
              'emotion': 'Friendship',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Make a new friend',
              'imageDirection':
                  'Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.',
              'bodyLanguage':
                  'Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.',
              'learningMoment':
                  'Olitun showing warmth, inclusion, and building a strong social bond.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱨ',
            textLatin: 'Hor hor – Human path / Way of life',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱥᱟᱨᱦᱟᱣ',
            textLatin: 'Sari sarhaw – True appreciation',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱚᱲ ᱞᱟᱹᱰᱩ',
            textLatin: 'Ror ladu – Sweet talks / Flattery',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱟᱹᱭ',
            textLatin: 'Mone kay – Sin of the heart / Guilty conscience',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱦᱟᱹᱞᱤ',
            textLatin: 'Jiwi hali – Lively spirit / Fresh energy',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱟᱹᱢᱤ ᱞᱟᱹᱜᱤᱫ',
            textLatin: 'Kami lagid – Ready to work',
            data: {
              'emotion': 'Confidence',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Complete a task',
              'imageDirection':
                  'Olitun carefully carrying out a task, like neatly filing books or designing a wooden model, demonstrating capability and responsibility.',
              'bodyLanguage':
                  'Standing tall, head held high, chest slightly out, a bright and self-assured smile.',
              'learningMoment':
                  'Olitun exhibiting self-reliance, readiness to learn, and pride in their capabilities.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱲ',
            textLatin: 'Santali ror – Speaking Santali',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱩᱭᱦᱟᱹᱨ',
            textLatin: 'Mone uyhar – Thoughts of the heart',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱱᱟᱹᱢ ᱫᱟᱠᱟ',
            textLatin: 'Dinam daka – Daily bread',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱮᱞ',
            textLatin: 'Sagun njel – Good vision / Omen',
            data: {
              'emotion': 'Ambition',
              'storyArc': 'Technology & Learning',
              'growthValue': 'Entrepreneurship',
              'characterGoal': 'Learn something new',
              'imageDirection':
                  'Olitun stands under the bright sun, showcasing a creative blueprint of a village development project with pride.',
              'bodyLanguage':
                  'Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.',
              'learningMoment':
                  'Olitun aiming high, showing aspiration for modern education and career path.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱫᱟᱲᱮ',
            textLatin: 'Hor dare – Collective human strength',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Future Success',
              'growthValue': 'Leadership',
              'characterGoal': 'Build confidence',
              'imageDirection':
                  'Olitun works together with classmates around a table filled with building blocks and tablets, smiling with ambition.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Sari dhorom – True religion / Path of truth',
            data: {
              'emotion': 'Hope',
              'storyArc': 'Modern World',
              'growthValue': 'Technology',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution.',
              'bodyLanguage':
                  'Looking upward and forward, eyes shining bright with positive expectation, smiling gently.',
              'learningMoment':
                  'Olitun expressing optimism for progress, new opportunities, and future success.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱨᱚᱲ ᱵᱩᱨᱩ ᱨᱚᱲ',
            textLatin: 'Hor ror buru ror – Man\'s word is as firm as the hill',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱨᱮ ᱡᱟᱱᱟᱢ',
            textLatin: 'Dag re janam – Born in water / Pure spirit',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun drinking cool, clean water from a traditional clay pot, looking refreshed and happy.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱦᱚᱲᱢᱚ',
            textLatin: 'Hasa hormo – Clay body / Mortal self',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱸᱜᱮᱞ ᱡᱤᱣᱤ',
            textLatin: 'Sengel jiwi – Fiery soul / Passionate spirit',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱭ ᱞᱮᱠᱟ ᱫᱟᱹᱲ',
            textLatin: 'Hoy leka dar – Running like the wind / Fleet-footed',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱩᱢᱩᱞ',
            textLatin: 'Bir umul – Shade of the forest / Nature\'s protection',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱨᱮ ᱥᱟᱠᱟᱢ',
            textLatin: 'Dare sakam – Tree leaves / Herbal cure',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱡᱟᱹᱞᱤ',
            textLatin: 'Jiwi jhale – Snare of life / Interconnected existence',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱥᱮᱨᱢᱟ',
            textLatin: 'Sari serma – True heavens / Cosmic order',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱠᱩᱫᱩᱢ ᱠᱟᱛᱷᱟ',
            textLatin: 'Kudum katha – Riddle talk / Figurative expression',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱮᱱᱛᱟ ᱨᱚᱲ',
            textLatin: 'Benta ror – Idiomatic speech / Indirect speech',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱲᱟᱢ ᱠᱟᱛᱷᱟ',
            textLatin: 'Haram katha – Ancestral wisdom / Sayings of elders',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱩᱰᱷᱤ ᱩᱭᱦᱟᱹᱨ',
            textLatin: 'Budhi uyhar – Wise grandmother\'s advice',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps Olitun adjust a neat shoulder bag.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱛᱩ ᱟᱹᱨᱤ',
            textLatin: 'Atu ari – Custom of the village',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱩᱢᱤᱫᱽ ᱫᱟᱲᱮ',
            textLatin: 'Jumid dare – Strength in unity',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱚᱦᱨᱟᱭ ᱥᱮᱨᱮᱧ',
            textLatin: 'Sohrae serenj – Traditional Sohrae harvest songs',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱟᱦᱟ ᱥᱟᱠᱟᱢ',
            textLatin: 'Baha sakam – Flower petals / Sacred offerings',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱟᱦᱮᱨ ᱩᱢᱩᱞ',
            textLatin: 'Jaher umul – Protection of the sacred grove',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱧᱡᱷᱤ ᱵᱤᱪᱟᱹᱨ',
            textLatin: 'Manjhi bicar – Headman\'s judgment / Local justice',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Hor dhorom – The way of the Santal / Righteousness',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun pointing toward a balanced, hand-carved wooden scale, indicating fairness and justice.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱩᱞᱟᱹᱲ',
            textLatin: 'Sirjon dular – Love for nature',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱚᱛ ᱦᱟᱥᱟ',
            textLatin: 'Ot hasa – Land and soil / Motherland',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'A gentle Santhal mother smiling warmly as she helps Olitun adjust a neat shoulder bag.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱡᱟᱱᱣᱟᱨ',
            textLatin: 'Bir janwar – Wild beasts / Forest fauna',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱟᱠᱟᱢ',
            textLatin: 'Sagun sakam – Auspicious leaf / Sacred message',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱᱢᱤ ᱜᱮᱭᱟᱱ',
            textLatin: 'Manmi geyan – Human wisdom',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
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
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱛᱚᱞ',
            textLatin: 'Jiwi tol – Mind bound / Dedication / Vow',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱛᱷᱟᱹᱭ',
            textLatin: 'Mone thay – Firm decision',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱩᱴᱤ ᱡᱚᱢ',
            textLatin: 'Luti jom – Eating through lips / False promises',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱩ ᱛᱮ ᱨᱟᱠᱟᱵ',
            textLatin: 'Mu te rakab – Boiling with anger / Nostril rage',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱟᱜ ᱫᱷᱤᱨᱤ',
            textLatin: 'Dag dhiri – Wet stone / Indifferent person',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱵᱤᱨ ᱫᱟᱨᱮ',
            textLatin: 'Bir dare – Forest trees / Native strength',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun planting a young green seedling in rich soil, showing care and responsibility for nature.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱟᱥᱟ ᱚᱲᱟᱜ',
            textLatin: 'Hasa orag – Mud house / Humble dwelling',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun works with rich brown clay, sculpting a small toy pot with focused, creative hands.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱮᱨᱢᱟ ᱤᱯᱤᱞ',
            textLatin: 'Serma ipil – Heavenly stars / Guide',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun lying on a straw mat under a clear night sky, pointing at a shooting star in wonder.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱧᱤᱫᱟᱹ ᱩᱢᱩᱞ',
            textLatin: 'Njida umul – Night shadow / Mysterious',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱸᱜᱮ ᱥᱤᱛᱩᱝ',
            textLatin: 'Singe situng – Scorching midday sun',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun looking up at the warm morning sun rising over the hills, eyes filled with hope.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱨᱤᱢᱤᱞ ᱫᱟᱜ',
            textLatin: 'Rimil dag – Cloud rain / Dynamic blessing',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun standing under a shelter, watching fresh raindrops fall on green leaves, smiling with curiosity.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱦᱚᱲ ᱦᱚᱨᱢᱚ',
            textLatin: 'Hor hormo – Santal body / Earthly vessel',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱵᱤᱞ ᱥᱟᱹᱜᱟᱹᱭ',
            textLatin:
                'Sibil sagay – Sweet relationship / Affectionate bonding',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱚᱱᱮ ᱠᱮᱴᱮᱡ',
            textLatin: 'Mone ketej – Strong mind / Brave heart',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱡᱤᱣᱤ ᱨᱟᱲᱟ',
            textLatin: 'Jiwi rara – Soul liberation / Ultimate peace',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱩᱞᱟᱹᱲ ᱜᱟᱹᱰᱤ',
            textLatin: 'Dular gadi – River of love',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun discovering a clear, flowing spring in the forest, pointing at the clean water.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱨᱤ ᱜᱩᱨᱩ',
            textLatin: 'Sari guru – True teacher / Master',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱜᱮᱭᱟᱱ ᱫᱚᱨᱭᱟ',
            textLatin: 'Geyan dorya – Ocean of knowledge',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱞᱟᱠᱪᱟᱨ ᱦᱚᱨ',
            textLatin: 'Lakchar hor – Cultural path',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱟᱹᱨᱤ ᱥᱟᱹᱨᱤ',
            textLatin: 'Ari sari – Pure traditions / Absolute truth',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Leadership',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun standing tall on a hill overlooking the village, looking forward with strong resolution.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱶᱦᱮᱫ ᱡᱤᱣᱤ',
            textLatin: 'Sawhet jiwi – Soul of literature',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱤᱨᱡᱚᱱ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Sirjon dhorom – Religion of nature',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱫᱤᱥᱚᱢ ᱫᱟᱲᱮ',
            textLatin: 'Disom dare – Power of the land',
            data: {
              'emotion': 'Gratitude',
              'storyArc': 'Dreaming Big',
              'growthValue': 'Problem Solving',
              'characterGoal': 'Create something useful',
              'imageDirection':
                  'Olitun stands proudly at a crossroads in the village, pointing toward a path of opportunity.',
              'bodyLanguage':
                  'Slightly bowed head, hands held together or offering a token of appreciation, warm smile.',
              'learningMoment':
                  'Olitun acknowledging and appreciating the kindness and efforts of others.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱩᱛᱩᱢ',
            textLatin: 'Sagun nyutum – Good name / Renown',
            data: {
              'emotion': 'Pride',
              'storyArc': 'Working Together',
              'growthValue': 'Leadership',
              'characterGoal': 'Solve a problem',
              'imageDirection':
                  'Olitun stands with hands on hips, looking out over the village from a scenic hill, representing leadership.',
              'bodyLanguage':
                  'Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.',
              'learningMoment':
                  'Olitun celebrating cultural identity, heritage, and personal achievements.',
            },
          ),
          LessonBlockModel(
            type: 'text',
            textOlChiki: 'ᱢᱟᱹᱱᱢᱤ ᱫᱷᱚᱨᱚᱢ',
            textLatin: 'Manmi dhorom – Humanity / Service to mankind',
            data: {
              'emotion': 'Achievement',
              'storyArc': 'Exploring Nature',
              'growthValue': 'Creativity',
              'characterGoal': 'Teach others',
              'imageDirection':
                  'Olitun gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.',
              'bodyLanguage':
                  'Cheerful smile, hands raised in a small celebration or showing a finished project.',
              'learningMoment':
                  'Olitun enjoying the reward of dedication, effort, and hard work.',
            },
          ),
        ],
      },
    ];

    for (int i = 0; i < vocabLessons.length; i++) {
      final lesson = vocabLessons[i];
      await addLessonIfNew(
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
