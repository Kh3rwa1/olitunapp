import 'package:itun/core/logging/app_logger.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/appwrite_db_service.dart';
import '../models/content_models.dart';

@Deprecated('Use contentListProvider. Will be removed in v1.4.0')
final sentencesProvider =
    StateNotifierProvider<SentencesNotifier, AsyncValue<List<SentenceModel>>>(
      SentencesNotifier.new,
    );

class SentencesNotifier extends StateNotifier<AsyncValue<List<SentenceModel>>> {
  SentencesNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSentences();
  }

  final Ref ref;

  static final List<SentenceModel> _seedSentences = [
    // ── Basics (basics) ──
    SentenceModel(
      id: 's1',
      sentenceOlChiki: 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱪᱮᱫ?',
      sentenceLatin: 'Amaak nyutum ced?',
      meaning: 'What is your name?',
      pronunciation: 'A-maag nyu-tum ched?',
      category: 'basics',
      order: 1,
    ),
    SentenceModel(
      id: 's2',
      sentenceOlChiki: 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱥᱟᱱᱛᱷᱟᱞ',
      sentenceLatin: 'Injaak nyutum do Santhal',
      meaning: 'My name is Santhal',
      pronunciation: 'In-jaag nyu-tum do San-thal',
      category: 'basics',
      order: 2,
    ),
    SentenceModel(
      id: 's3',
      sentenceOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱛᱮᱢ ᱪᱟᱞᱟᱜ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Am do okatem chalag kana?',
      meaning: 'Where are you going?',
      pronunciation: 'Am do o-ka-tem cha-lag ka-na?',
      category: 'basics',
      order: 3,
    ),
    SentenceModel(
      id: 's4',
      sentenceOlChiki: 'ᱟᱢ ᱫᱚ ᱚᱠᱟᱨᱮᱢ ᱛᱟᱦᱮᱸᱱᱟ?',
      sentenceLatin: 'Am do okarem tahena?',
      meaning: 'Where do you live?',
      pronunciation: 'Am do o-ka-rem ta-hen-a?',
      category: 'basics',
      order: 4,
    ),
    SentenceModel(
      id: 's5',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱱᱚᱸᱰᱮᱧ ᱛᱟᱦᱮᱸᱱᱟ',
      sentenceLatin: 'In do nondenj tahena',
      meaning: 'I live here',
      pronunciation: 'In do non-denj ta-hen-a',
      category: 'basics',
      order: 5,
    ),
    SentenceModel(
      id: 's24',
      sentenceOlChiki: 'ᱟᱢ ᱚᱠᱚᱭ ᱠᱟᱱᱟᱢ?',
      sentenceLatin: 'Am okoy kanam?',
      meaning: 'Who are you?',
      pronunciation: 'Am o-koy ka-nam?',
      category: 'basics',
      order: 6,
    ),
    SentenceModel(
      id: 's25',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱢᱤᱫ ᱪᱮᱛᱮᱫᱤᱭᱟᱹ ᱠᱟᱹᱱᱟᱹᱧ',
      sentenceLatin: 'In do mid cetediya kananj',
      meaning: 'I am a student',
      pronunciation: 'In do mid che-te-di-ya ka-nanj',
      category: 'basics',
      order: 7,
    ),
    SentenceModel(
      id: 's26',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱪᱮᱫ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Nowa ced kana?',
      meaning: 'What is this?',
      pronunciation: 'No-wa ched ka-na?',
      category: 'basics',
      order: 8,
    ),
    SentenceModel(
      id: 's27',
      sentenceOlChiki: 'ᱚᱱᱟ ᱫᱚ ᱢᱤᱫ ᱯᱩᱛᱷᱤ ᱠᱟᱱᱟ',
      sentenceLatin: 'Ona do mid puthi kana',
      meaning: 'That is a book',
      pronunciation: 'O-na do mid pu-thi ka-na',
      category: 'basics',
      order: 9,
    ),
    SentenceModel(
      id: 's28',
      sentenceOlChiki: 'ᱟᱢ ᱥᱟᱱᱛᱟᱲᱤ ᱮᱢ ᱨᱚᱲ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ?',
      sentenceLatin: 'Am Santali em ror dareyag-a?',
      meaning: 'Can you speak Santali?',
      pronunciation: 'Am San-ta-ri em ror da-rey-ag-a?',
      category: 'basics',
      order: 10,
    ),
    SentenceModel(
      id: 's29',
      sentenceOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱠᱟᱹᱡᱼᱠᱟᱹᱡ ᱤᱧ ᱨᱚᱲ ᱫᱟᱲᱮᱭᱟᱜᱼᱟ',
      sentenceLatin: 'Hẽ, inj kaj-kaj inj ror dareyag-a',
      meaning: 'Yes, I can speak a little',
      pronunciation: 'Hẽ, inj kaj-kaj inj ror da-rey-ag-a',
      category: 'basics',
      order: 11,
    ),
    SentenceModel(
      id: 's30',
      sentenceOlChiki: 'ᱱᱩᱭ ᱫᱚ ᱤᱧᱤᱡ ᱜᱟᱛᱮ ᱠᱟᱱᱟᱭ',
      sentenceLatin: 'Nuy do inij gate kanay',
      meaning: 'This is my friend',
      pronunciation: 'Nuy do i-nij ga-te ka-nay',
      category: 'basics',
      order: 12,
    ),
    SentenceModel(
      id: 's31',
      sentenceOlChiki: 'ᱟᱢᱟᱜ ᱩᱢᱮᱨ ᱛᱤᱱᱟᱹᱜ?',
      sentenceLatin: 'Amaak umer tinag?',
      meaning: 'How old are you?',
      pronunciation: 'A-maag u-mer ti-nag?',
      category: 'basics',
      order: 13,
    ),
    SentenceModel(
      id: 's32',
      sentenceOlChiki: 'ᱤᱧᱟᱜ ᱩᱢᱮᱨ ᱫᱚ ᱵᱟᱨᱜᱮᱞ ᱥᱮᱨᱢᱟ',
      sentenceLatin: 'Injaak umer do bargel serma',
      meaning: 'I am twenty years old',
      pronunciation: 'In-jaag u-mer do bar-gel ser-ma',
      category: 'basics',
      order: 14,
    ),
    SentenceModel(
      id: 's33',
      sentenceOlChiki: 'ᱟᱢ ᱚᱠᱟ ᱠᱷᱚᱱᱮᱢ ᱦᱮᱡ ᱟᱠᱟᱱᱟ?',
      sentenceLatin: 'Am oka khonem hej akana?',
      meaning: 'Where are you from?',
      pronunciation: 'Am o-ka kho-nem hej a-ka-na?',
      category: 'basics',
      order: 15,
    ),
    SentenceModel(
      id: 's34',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱡᱷᱟᱨᱠᱷᱚᱸᱰ ᱠᱷᱚᱱᱤᱧ ᱦᱮᱡ ᱟᱠᱟᱱᱟ',
      sentenceLatin: 'In do Jharkhand khoninj hej akana',
      meaning: 'I am from Jharkhand',
      pronunciation: 'In do Jhar-khond kho-ninj hej a-ka-na',
      category: 'basics',
      order: 16,
    ),
    SentenceModel(
      id: 's35',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱤᱧᱟᱜ ᱚᱲᱟᱜ ᱠᱟᱱᱟ',
      sentenceLatin: 'Nowa do injaak orag kana',
      meaning: 'This is my house',
      pronunciation: 'No-wa do in-jaag o-rag ka-na',
      category: 'basics',
      order: 17,
    ),
    SentenceModel(
      id: 's36',
      sentenceOlChiki: 'ᱟᱢ ᱚᱠᱟᱨᱮᱢ ᱠᱟᱹᱢᱤᱭᱟ?',
      sentenceLatin: 'Am okarem kamiya?',
      meaning: 'Where do you work?',
      pronunciation: 'Am o-ka-rem ka-mi-ya?',
      category: 'basics',
      order: 18,
    ),
    SentenceModel(
      id: 's37',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱤᱛᱩᱱ ᱟᱥᱲᱟ ᱨᱮᱧ ᱠᱟᱹᱢᱤᱭᱟ',
      sentenceLatin: 'In do itun asra renj kamiya',
      meaning: 'I work at a school',
      pronunciation: 'In do i-tun as-ra renj ka-mi-ya',
      category: 'basics',
      order: 19,
    ),
    SentenceModel(
      id: 's38',
      sentenceOlChiki: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
      sentenceLatin: 'Am ced em kusiyag-a?',
      meaning: 'What do you like?',
      pronunciation: 'Am ched em ku-si-yag-a?',
      category: 'basics',
      order: 20,
    ),

    // ── Daily Conversations (conversations) ──
    SentenceModel(
      id: 's6',
      sentenceOlChiki: 'ᱤᱧ ᱨᱮᱸᱜᱮᱡ ᱮᱫ ᱤᱧᱟ',
      sentenceLatin: 'In rengej ed inja',
      meaning: 'I am hungry',
      pronunciation: 'In ren-gej ed in-ja',
      category: 'conversations',
      order: 21,
    ),
    SentenceModel(
      id: 's7',
      sentenceOlChiki: 'ᱫᱟᱠᱟ ᱡᱚᱢ ᱢᱮ',
      sentenceLatin: 'Daka jom me',
      meaning: 'Please eat food',
      pronunciation: 'Da-ka jom me',
      category: 'conversations',
      order: 22,
    ),
    SentenceModel(
      id: 's8',
      sentenceOlChiki: 'ᱫᱟᱜ ᱧᱩ ᱢᱮ',
      sentenceLatin: 'Dag nju me',
      meaning: 'Please drink water',
      pronunciation: 'Dag nyu me',
      category: 'conversations',
      order: 23,
    ),
    SentenceModel(
      id: 's9',
      sentenceOlChiki: 'ᱤᱧ ᱯᱟᱲᱦᱟᱜ ᱠᱟᱱᱟᱧ',
      sentenceLatin: 'In parhaag kananj',
      meaning: 'I am studying',
      pronunciation: 'In par-haag ka-nanj',
      category: 'conversations',
      order: 24,
    ),
    SentenceModel(
      id: 's10',
      sentenceOlChiki: 'ᱟᱢ ᱪᱮᱫ ᱮᱢ ᱪᱤᱠᱟᱹᱭᱮᱫᱟ?',
      sentenceLatin: 'Am ced em cikayeda?',
      meaning: 'What are you doing?',
      pronunciation: 'Am ched em chi-kay-e-da?',
      category: 'conversations',
      order: 25,
    ),
    SentenceModel(
      id: 's11',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱧ',
      sentenceLatin: 'In do kamiyedanj',
      meaning: 'I am working',
      pronunciation: 'In do ka-mi-yed-anj',
      category: 'conversations',
      order: 26,
    ),
    SentenceModel(
      id: 's39',
      sentenceOlChiki: 'ᱫᱮᱞᱟ ᱵᱚᱱ ᱪᱟᱞᱟᱜᱼᱟ',
      sentenceLatin: 'Dela bon chalag-a',
      meaning: 'Let\'s go',
      pronunciation: 'De-la bon cha-lag-a',
      category: 'conversations',
      order: 27,
    ),
    SentenceModel(
      id: 's40',
      sentenceOlChiki: 'ᱦᱟᱹᱡᱩᱜ ᱢᱮ ᱱᱚᱸᱰᱮ',
      sentenceLatin: 'Hajug me nonde',
      meaning: 'Come here',
      pronunciation: 'Ha-jug me non-de',
      category: 'conversations',
      order: 28,
    ),
    SentenceModel(
      id: 's41',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚᱧ ᱡᱟᱹᱯᱤᱫ ᱞᱟᱹᱜᱤᱫ',
      sentenceLatin: 'In donj japid lagid',
      meaning: 'I am going to sleep',
      pronunciation: 'In donj ja-pid la-gid',
      category: 'conversations',
      order: 29,
    ),
    SentenceModel(
      id: 's42',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚᱢ ᱟᱹᱰᱤ ᱵᱤᱡᱤ ᱜᱮᱭᱟ?',
      sentenceLatin: 'Tehenj dom adi biji geya?',
      meaning: 'Are you very busy today?',
      pronunciation: 'Te-henj dom a-di bi-ji ge-ya?',
      category: 'conversations',
      order: 30,
    ),
    SentenceModel(
      id: 's43',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱵᱟᱹᱧ ᱵᱤᱡᱤ ᱜᱮᱭᱟ',
      sentenceLatin: 'In do banj biji geya',
      meaning: 'I am not busy',
      pronunciation: 'In do banj bi-ji ge-ya',
      category: 'conversations',
      order: 31,
    ),
    SentenceModel(
      id: 's44',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱟᱥᱮ ᱛᱟᱺᱜᱤᱧ ᱢᱮ',
      sentenceLatin: 'Daya kate nase tanginj me',
      meaning: 'Please wait for me a little',
      pronunciation: 'Da-ya ka-te na-se tan-ginj me',
      category: 'conversations',
      order: 32,
    ),
    SentenceModel(
      id: 's45',
      sentenceOlChiki: 'ᱟᱢ ᱥᱮᱨᱮᱧ ᱮᱢ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ?',
      sentenceLatin: 'Am serenj em kusiyag-a?',
      meaning: 'Do you like singing?',
      pronunciation: 'Am se-renj em ku-si-yag-a?',
      category: 'conversations',
      order: 33,
    ),
    SentenceModel(
      id: 's46',
      sentenceOlChiki: 'ᱦᱮᱸ, ᱤᱧ ᱥᱮᱨᱮᱧ ᱟᱹᱰᱤᱧ ᱠᱩᱥᱤᱭᱟᱜᱼᱟ',
      sentenceLatin: 'Hẽ, inj serenj adinj kusiyag-a',
      meaning: 'Yes, I like singing very much',
      pronunciation: 'Hẽ, inj se-renj a-dinj ku-si-yag-a',
      category: 'conversations',
      order: 34,
    ),
    SentenceModel(
      id: 's47',
      sentenceOlChiki: 'ᱪᱮᱫ ᱠᱷᱚᱵᱚᱨ?',
      sentenceLatin: 'Ced khobor?',
      meaning: 'What\'s the news?',
      pronunciation: 'Ched kho-bor?',
      category: 'conversations',
      order: 35,
    ),
    SentenceModel(
      id: 's48',
      sentenceOlChiki: 'ᱡᱷᱚᱛᱚᱣᱟᱜ ᱱᱟᱯᱟᱭ ᱜᱮᱭᱟ',
      sentenceLatin: 'Jhotowag napay geya',
      meaning: 'Everything is fine',
      pronunciation: 'Jho-to-wag na-pay ge-ya',
      category: 'conversations',
      order: 36,
    ),
    SentenceModel(
      id: 's49',
      sentenceOlChiki: 'ᱟᱢ ᱛᱤᱥ ᱮᱢ ᱨᱩᱣᱟᱹᱲᱟ?',
      sentenceLatin: 'Am tis em ruwara?',
      meaning: 'When will you return?',
      pronunciation: 'Am tis em ru-wa-ra?',
      category: 'conversations',
      order: 37,
    ),
    SentenceModel(
      id: 's50',
      sentenceOlChiki: 'ᱤᱧ ᱫᱚ ᱜᱟᱯᱟᱧ ᱨᱩᱣᱟᱹᱲᱟ',
      sentenceLatin: 'In do gapanj ruwara',
      meaning: 'I will return tomorrow',
      pronunciation: 'In do ga-panj ru-wa-ra',
      category: 'conversations',
      order: 38,
    ),
    SentenceModel(
      id: 's51',
      sentenceOlChiki: 'ᱫᱮᱞᱟ ᱵᱚᱱ ᱫᱟᱠᱟ ᱵᱚᱱ ᱡᱚᱢᱼᱟ',
      sentenceLatin: 'Dela bon daka bon jom-a',
      meaning: 'Come, let\'s eat food',
      pronunciation: 'De-la bon da-ka bon jom-a',
      category: 'conversations',
      order: 39,
    ),
    SentenceModel(
      id: 's52',
      sentenceOlChiki: 'ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱼᱟ',
      sentenceLatin: 'Adi raskanj bujhaw ked-a',
      meaning: 'I felt very happy',
      pronunciation: 'A-di ras-kanj bu-jhaw ked-a',
      category: 'conversations',
      order: 40,
    ),

    // ── Greetings & Politeness (polite) ──
    SentenceModel(
      id: 's12',
      sentenceOlChiki: 'ᱟᱢ ᱪᱮᱞᱮᱠᱟ ᱢᱮᱱᱟᱢᱟ?',
      sentenceLatin: 'Am celeka menama?',
      meaning: 'Hello, how are you?',
      pronunciation: 'Am che-le-ka me-na-ma?',
      category: 'polite',
      order: 41,
    ),
    SentenceModel(
      id: 's13',
      sentenceOlChiki: 'ᱤᱧ ᱱᱟᱯᱟᱭ ᱜᱮ ᱢᱮᱱᱟᱧᱟ',
      sentenceLatin: 'In napay ge menanja',
      meaning: 'I am fine',
      pronunciation: 'In na-pay ge me-nan-ja',
      category: 'polite',
      order: 42,
    ),
    SentenceModel(
      id: 's14',
      sentenceOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱥᱮᱛᱟᱜ',
      sentenceLatin: 'Sagun setag',
      meaning: 'Good morning',
      pronunciation: 'Sa-gun se-tag',
      category: 'polite',
      order: 43,
    ),
    SentenceModel(
      id: 's15',
      sentenceOlChiki: 'ᱥᱟᱹᱜᱩᱱ ᱧᱤᱫᱟᱹ',
      sentenceLatin: 'Sagun njida',
      meaning: 'Good night',
      pronunciation: 'Sa-gun nyi-da',
      category: 'polite',
      order: 44,
    ),
    SentenceModel(
      id: 's16',
      sentenceOlChiki: 'ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
      sentenceLatin: 'Ika kanj me',
      meaning: 'Excuse me / Sorry',
      pronunciation: 'I-ka kanj me',
      category: 'polite',
      order: 45,
    ),
    SentenceModel(
      id: 's17',
      sentenceOlChiki: 'ᱱᱟᱯᱟᱭ ᱛᱮ ᱛᱟᱦᱮᱸᱱ ᱢᱮ',
      sentenceLatin: 'Napay te tahen me',
      meaning: 'Take care',
      pronunciation: 'Na-pay te ta-hen me',
      category: 'polite',
      order: 46,
    ),
    SentenceModel(
      id: 's18',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱫᱩᱲᱩᱵ ᱢᱮ',
      sentenceLatin: 'Daya kate durub me',
      meaning: 'Please sit down',
      pronunciation: 'Da-ya ka-te du-rub me',
      category: 'polite',
      order: 47,
    ),
    SentenceModel(
      id: 's53',
      sentenceOlChiki: 'ᱟᱹᱰᱤ ᱟᱹᱰᱤ ᱥᱟᱨᱦᱟᱣ',
      sentenceLatin: 'Adi adi sarhaw',
      meaning: 'Thank you very much',
      pronunciation: 'A-di a-di sar-haw',
      category: 'polite',
      order: 48,
    ),
    SentenceModel(
      id: 's54',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ ᱜᱮ ᱢᱟᱨᱟᱝ ᱵᱟᱵᱟ',
      sentenceLatin: 'Johar ge marang baba',
      meaning: 'Greetings, respected uncle',
      pronunciation: 'Jo-har ge ma-rang ba-ba',
      category: 'polite',
      order: 49,
    ),
    SentenceModel(
      id: 's55',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ ᱜᱮ ᱢᱟᱨᱟᱝ ᱟᱭᱳ',
      sentenceLatin: 'Johar ge marang ayo',
      meaning: 'Greetings, respected aunt',
      pronunciation: 'Jo-har ge ma-rang a-yo',
      category: 'polite',
      order: 50,
    ),
    SentenceModel(
      id: 's56',
      sentenceOlChiki: 'ᱟᱢ ᱥᱟᱶ ᱧᱟᱯᱟᱢ ᱠᱟᱛᱮ ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹᱧ ᱵᱩᱡᱷᱟᱹᱣ ᱠᱮᱫᱼᱟ',
      sentenceLatin: 'Am saw njapam kate adi raskanj bujhaw ked-a',
      meaning: 'Nice to meet you',
      pronunciation: 'Am saw nya-pam ka-te a-di ras-kanj bu-jhaw ked-a',
      category: 'polite',
      order: 51,
    ),
    SentenceModel(
      id: 's57',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱤᱧᱟᱜ ᱠᱩᱥᱤ ᱠᱟᱱᱟ',
      sentenceLatin: 'Nowa do injaak kusi kana',
      meaning: 'It\'s my pleasure',
      pronunciation: 'No-wa do in-jaag ku-si ka-na',
      category: 'polite',
      order: 52,
    ),
    SentenceModel(
      id: 's58',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱚᱶᱟ ᱮᱢᱟᱧ ᱢᱮ',
      sentenceLatin: 'Daya kate nowa emanj me',
      meaning: 'Please give me this',
      pronunciation: 'Da-ya ka-te no-wa e-manj me',
      category: 'polite',
      order: 53,
    ),
    SentenceModel(
      id: 's59',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ, ᱢᱟ ᱛᱚᱵᱮ ᱤᱧᱤᱧ ᱥᱮᱱᱚᱜ ᱠᱟᱱᱟ',
      sentenceLatin: 'Johar, ma tobe injinj senog kana',
      meaning: 'Goodbye, I am leaving now',
      pronunciation: 'Jo-har, ma to-be in-jinj se-nog ka-na',
      category: 'polite',
      order: 54,
    ),
    SentenceModel(
      id: 's60',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱱᱟᱥᱮ ᱟᱸᱡᱚᱢ ᱢᱮ',
      sentenceLatin: 'Daya kate nase anjom me',
      meaning: 'Please listen for a moment',
      pronunciation: 'Da-ya ka-te na-se an-jom me',
      category: 'polite',
      order: 55,
    ),
    SentenceModel(
      id: 's61',
      sentenceOlChiki: 'ᱟᱞᱚᱢ ᱪᱤᱱᱛᱟᱹᱭᱟ, ᱡᱷᱚᱛᱚᱣᱟᱜ ᱴᱷᱤᱠ ᱜᱮᱭᱟ',
      sentenceLatin: 'Alom cintaya, jhotowag thik geya',
      meaning: 'Don\'t worry, everything is okay',
      pronunciation: 'A-lom chin-ta-ya, jho-to-wag thik ge-ya',
      category: 'polite',
      order: 56,
    ),
    SentenceModel(
      id: 's62',
      sentenceOlChiki: 'ᱟᱢᱟᱜ ᱫᱤᱱ ᱥᱟᱹᱜᱩᱱ ᱠᱚᱜ ᱢᱟ!',
      sentenceLatin: 'Amaak din sagun kog ma!',
      meaning: 'Have a good day!',
      pronunciation: 'A-maag din sa-gun kog ma!',
      category: 'polite',
      order: 57,
    ),
    SentenceModel(
      id: 's63',
      sentenceOlChiki: 'ᱟᱢᱟᱜ ᱜᱚᱲᱚ ᱞᱟᱹᱜᱤᱫ ᱥᱟᱨᱦᱟᱣ',
      sentenceLatin: 'Amaak goro lagid sarhaw',
      meaning: 'Thank you for your help',
      pronunciation: 'A-maag go-ro la-gid sar-haw',
      category: 'polite',
      order: 58,
    ),
    SentenceModel(
      id: 's64',
      sentenceOlChiki: 'ᱡᱚᱦᱟᱨ, ᱜᱟᱯᱟ ᱵᱚᱱ ᱧᱟᱯᱟᱢᱼᱟ',
      sentenceLatin: 'Johar, gapa bon njapam-a',
      meaning: 'Goodbye, see you tomorrow',
      pronunciation: 'Jo-har, ga-pa bon nya-pam-a',
      category: 'polite',
      order: 59,
    ),
    SentenceModel(
      id: 's65',
      sentenceOlChiki: 'ᱫᱟᱭᱟ ᱠᱟᱛᱮ ᱤᱧ ᱤᱠᱟᱹ ᱠᱟᱹᱧ ᱢᱮ',
      sentenceLatin: 'Daya kate inj ika kanj me',
      meaning: 'Please forgive me',
      pronunciation: 'Da-ya ka-te inj i-ka kanj me',
      category: 'polite',
      order: 60,
    ),

    // ── Time & Weather (time_weather) ──
    SentenceModel(
      id: 's19',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱫᱤᱱ ᱠᱟᱱᱟ',
      sentenceLatin: 'Tehenj do adi napay din kana',
      meaning: 'Today is a beautiful day',
      pronunciation: 'Te-henj do a-di na-pay din ka-na',
      category: 'time_weather',
      order: 61,
    ),
    SentenceModel(
      id: 's20',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱫᱚ ᱛᱤᱱᱟᱹᱜ ᱫᱟᱢ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Nowa do tinag dam kana?',
      meaning: 'How much is this?',
      pronunciation: 'No-wa do ti-nag dam ka-na?',
      category: 'time_weather',
      order: 62,
    ),
    SentenceModel(
      id: 's21',
      sentenceOlChiki: 'ᱫᱟᱜ ᱮ ᱡᱟᱹᱲᱤᱭᱮᱫᱟ',
      sentenceLatin: 'Dag e jariyeda',
      meaning: 'It is raining',
      pronunciation: 'Dag e ja-ri-ye-da',
      category: 'time_weather',
      order: 63,
    ),
    SentenceModel(
      id: 's22',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱥᱤᱛᱩᱝ ᱠᱟᱱᱟ',
      sentenceLatin: 'Tehenj do adi situng kana',
      meaning: 'It is very hot today',
      pronunciation: 'Te-henj do a-di si-tung ka-na',
      category: 'time_weather',
      order: 64,
    ),
    SentenceModel(
      id: 's23',
      sentenceOlChiki: 'ᱛᱤᱱᱟᱹᱜ ᱵᱟᱡᱟᱣ ᱮᱱᱟ?',
      sentenceLatin: 'Tinag bajaw ena?',
      meaning: 'What time is it?',
      pronunciation: 'Ti-nag ba-jaw e-na?',
      category: 'time_weather',
      order: 65,
    ),
    SentenceModel(
      id: 's66',
      sentenceOlChiki: 'ᱱᱤᱛᱚᱜ ᱫᱚ ᱮᱭᱟᱭ ᱵᱟᱡᱟᱣ ᱠᱟᱱᱟ',
      sentenceLatin: 'Nitog do eyay bajaw kana',
      meaning: 'It is seven o\'clock now',
      pronunciation: 'Ni-tog do ey-ay ba-jaw ka-na',
      category: 'time_weather',
      order: 66,
    ),
    SentenceModel(
      id: 's67',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱨᱟᱵᱟᱝ ᱠᱟᱱᱟ',
      sentenceLatin: 'Tehenj do adi rabang kana',
      meaning: 'It is very cold today',
      pronunciation: 'Te-henj do a-di ra-bang ka-na',
      category: 'time_weather',
      order: 67,
    ),
    SentenceModel(
      id: 's68',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱦᱚᱭ ᱮᱫᱼᱟᱭ',
      sentenceLatin: 'Tehenj do hoy ed-ay',
      meaning: 'It is windy today',
      pronunciation: 'Te-henj do hoy ed-ay',
      category: 'time_weather',
      order: 68,
    ),
    SentenceModel(
      id: 's69',
      sentenceOlChiki: 'ᱨᱤᱢᱤᱞ ᱮᱫᱼᱟᱭ ᱥᱮᱨᱢᱟ ᱨᱮ',
      sentenceLatin: 'Rimil ed-ay serma re',
      meaning: 'The sky is cloudy',
      pronunciation: 'Ri-mil ed-ay ser-ma re',
      category: 'time_weather',
      order: 69,
    ),
    SentenceModel(
      id: 's70',
      sentenceOlChiki: 'ᱜᱟᱯᱟ ᱫᱟᱜ ᱮ ᱡᱟᱹᱲᱤᱭᱟ ᱥᱮ?',
      sentenceLatin: 'Gapa dag e jariya se?',
      meaning: 'Will it rain tomorrow?',
      pronunciation: 'Ga-pa dag e ja-ri-ya se?',
      category: 'time_weather',
      order: 70,
    ),
    SentenceModel(
      id: 's71',
      sentenceOlChiki: 'ᱥᱤᱛᱩᱝ ᱨᱤᱛᱩ ᱫᱚ ᱤᱧᱟᱜ ᱠᱩᱥᱤ ᱨᱤᱛᱩ ᱠᱟᱱᱟ',
      sentenceLatin: 'Situng ritu do injaak kusi ritu kana',
      meaning: 'Summer is my favorite season',
      pronunciation: 'Si-tung ri-tu do in-jaag ku-si ri-tu ka-na',
      category: 'time_weather',
      order: 71,
    ),
    SentenceModel(
      id: 's72',
      sentenceOlChiki: 'ᱨᱟᱵᱟᱝ ᱨᱤᱛᱩ ᱨᱮ ᱟᱹᱰᱤ ᱨᱟᱵᱟᱝᱼᱟ',
      sentenceLatin: 'Rabang ritu re adi rabang-a',
      meaning: 'It is very cold in winter',
      pronunciation: 'Ra-bang ri-tu re a-di ra-bang-a',
      category: 'time_weather',
      order: 72,
    ),
    SentenceModel(
      id: 's73',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱚᱠᱟ ᱢᱟᱦᱟ ᱠᱟᱱᱟ?',
      sentenceLatin: 'Tehenj do oka maha kana?',
      meaning: 'What day is today?',
      pronunciation: 'Te-henj do o-ka ma-ha ka-na?',
      category: 'time_weather',
      order: 73,
    ),
    SentenceModel(
      id: 's74',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱥᱤᱸᱜᱮ ᱢᱟᱦᱟ ᱠᱟᱱᱟ',
      sentenceLatin: 'Tehenj do Singe maha kana',
      meaning: 'Today is Sunday',
      pronunciation: 'Te-henj do Sin-ge ma-ha ka-na',
      category: 'time_weather',
      order: 74,
    ),
    SentenceModel(
      id: 's75',
      sentenceOlChiki: 'ᱱᱤᱛᱚᱜ ᱥᱮᱛᱟᱜ ᱠᱟᱱᱟ',
      sentenceLatin: 'Nitog setag kana',
      meaning: 'Now it is morning',
      pronunciation: 'Ni-tog se-tag ka-na',
      category: 'time_weather',
      order: 75,
    ),
    SentenceModel(
      id: 's76',
      sentenceOlChiki: 'ᱟᱹᱭᱩᱵ ᱵᱮᱲᱟ ᱟᱹᱰᱤ ᱱᱟᱯᱟᱭ ᱜᱮᱭᱟ',
      sentenceLatin: 'Ayub bera adi napay geya',
      meaning: 'The evening time is very pleasant',
      pronunciation: 'A-yub be-ra a-di na-pay ge-ya',
      category: 'time_weather',
      order: 76,
    ),
    SentenceModel(
      id: 's77',
      sentenceOlChiki: 'ᱧᱤᱫᱟᱹ ᱵᱮᱲᱟ ᱤᱯᱤᱞ ᱠᱚ ᱡᱩᱞᱩᱜᱼᱟ',
      sentenceLatin: 'Njida bera ipil ko julug-a',
      meaning: 'Stars shine at night',
      pronunciation: 'Nyi-da be-ra i-pil ko ju-lug-a',
      category: 'time_weather',
      order: 77,
    ),
    SentenceModel(
      id: 's78',
      sentenceOlChiki: 'ᱱᱚᱶᱟ ᱥᱮᱨᱢᱟ ᱟᱹᱰᱤ ᱞᱚᱜᱚᱱ ᱯᱟᱨᱚᱢ ᱮᱱᱟ',
      sentenceLatin: 'Nowa serma adi logon parom ena',
      meaning: 'This year passed very quickly',
      pronunciation: 'No-wa ser-ma a-di lo-gon pa-rom e-na',
      category: 'time_weather',
      order: 78,
    ),
    SentenceModel(
      id: 's79',
      sentenceOlChiki: 'ᱜᱟᱯᱟ ᱥᱮᱛᱟᱜ ᱟᱞᱟᱝ ᱞᱟᱝ ᱧᱟᱯᱟᱢᱼᱟ',
      sentenceLatin: 'Gapa setag alang lang njapam-a',
      meaning: 'We will meet tomorrow morning',
      pronunciation: 'Ga-pa se-tag a-lang lang nya-pam-a',
      category: 'time_weather',
      order: 79,
    ),
    SentenceModel(
      id: 's80',
      sentenceOlChiki: 'ᱛᱮᱦᱮᱧ ᱫᱚ ᱟᱹᱰᱤ ᱞᱚᱞᱚ ᱜᱮᱭᱟ',
      sentenceLatin: 'Tehenj do adi lolo geya',
      meaning: 'Today is very warm',
      pronunciation: 'Te-henj do a-di lo-lo ge-ya',
      category: 'time_weather',
      order: 80,
    ),
  ];

  Future<void> _loadSentences() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = await db.listDocuments(
        'sentences',
        queries: [Query.orderAsc('order'), Query.limit(500)],
      );
      state = AsyncValue.data(data.map(SentenceModel.fromJson).toList());
    } catch (e) {
      state = AsyncValue.data(_seedSentences);
    }
  }

  Future<void> add(SentenceModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('sentences', item.id, item.toJson());
      await _loadSentences();
    } catch (e) {
      AppLogger.debug('❌ add sentence FAILED: $e');
      rethrow;
    }
  }

  Future<void> update(SentenceModel item) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.updateDocument('sentences', item.id, item.toJson());
      await _loadSentences();
    } catch (e) {
      AppLogger.debug('❌ update sentence FAILED: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.deleteDocument('sentences', id);
      await _loadSentences();
    } catch (e) {
      AppLogger.debug('❌ delete sentence FAILED: $e');
      rethrow;
    }
  }

  Future<void> seed() async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      // Fetch all existing documents in the sentences collection to completely clear legacy records
      final existingDocs = await db.listDocuments('sentences');
      AppLogger.debug(
        '🧹 Clearing ${existingDocs.length} existing sentences from database before seeding...',
      );
      for (final doc in existingDocs) {
        final docId = doc['id'] as String;
        try {
          await db.deleteDocument('sentences', docId);
        } catch (e) {
          AppLogger.debug('⚠️ Failed to delete sentence document $docId: $e');
        }
      }
    } catch (e) {
      AppLogger.debug('⚠️ Error clearing sentences collection: $e');
    }

    AppLogger.debug(
      '🌱 Seeding ${_seedSentences.length} clean sentences to database...',
    );
    for (final item in _seedSentences) {
      try {
        final db = ref.read(appwriteDbServiceProvider);
        await db.createDocument('sentences', item.id, item.toJson());
      } catch (e) {
        AppLogger.debug('⚠️ Error seeding sentence ${item.id}: $e');
      }
    }
    await _loadSentences();
  }
}
