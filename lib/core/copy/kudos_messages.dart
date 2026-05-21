import 'dart:math';

class KudosMessages {
  static const List<String> lessonKudos = [
    'Johar! Lesson complete. One step closer to Ol Chiki confidence.',
    'Small steps, strong roots. Your Santali is growing!',
    'Wonderful! You are keeping the beautiful Santali language alive.',
    'Superb progress! Your dedication is truly inspiring.',
  ];

  static const List<String> quizKudos = [
    'Nice! Your Santali ear is getting sharper.',
    'Brilliant! You mastered that quiz with flying colors.',
    'Incredible focus! Keep scaling your language skills.',
    'Johar! Your knowledge is shining bright today.',
  ];

  static const List<String> bakhedKudos = [
    'You kept the culture alive today.',
    'Beautiful. Listening to Bakhed connects us to our ancestors.',
    'Thank you for listening! Cultural roots build stronger futures.',
    'Stunning progress. Every rhyme heard is a story preserved.',
  ];

  static const List<String> mistakeKudos = [
    "Mistakes reviewed. That's how mastery is built.",
    'Mastery in progress! You transformed mistakes into wisdom.',
    'Fantastic! Correcting mistakes is the secret to fluency.',
    'Brilliant review! You are learning faster by refining errors.',
  ];

  static const List<String> streakSavedKudos = [
    'Streak saved. Small steps, strong roots.',
    'Phew! Streak saved. Consistency is key!',
    'Streak rescued! Keep up this incredible momentum.',
    'Awesome. Your learning streak remains unbroken!',
  ];

  static String getRandomKudos(List<String> list) {
    if (list.isEmpty) return 'Johar!';
    final random = Random();
    return list[random.nextInt(list.length)];
  }
}
