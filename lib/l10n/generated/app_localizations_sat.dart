// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Santali (`sat`).
class AppLocalizationsSat extends AppLocalizations {
  AppLocalizationsSat([String locale = 'sat']) : super(locale);

  @override
  String helloUser(String userName) {
    return 'Johar, $userName! 👋';
  }

  @override
  String get readyToLearn => 'Tehin chet lagid em saprao-a?';

  @override
  String get dayStreak => 'Din Streak';

  @override
  String get stars => 'Stars';

  @override
  String get lessons => 'Path';

  @override
  String get continueLearning => 'Chet\' idime';

  @override
  String get pickUpWhereLeftOff => 'Jahan khon em bagiat-a';

  @override
  String percentComplete(int percent) {
    return '$percent% Chao';
  }

  @override
  String get dailyQuiz => 'Din-am Quiz';

  @override
  String get practice => 'Abhyas';

  @override
  String get explore => 'Sandhay me';

  @override
  String get chooseCategory => 'Thok bachao me';

  @override
  String lessonsCount(int count) {
    return '$count path';
  }

  @override
  String get settings => 'Settings';

  @override
  String get customizeExperience => 'Em chet\' anubhav badal me';

  @override
  String get appearance => 'Dekhaw';

  @override
  String get darkMode => 'Andhar Mode';

  @override
  String get scriptDisplay => 'Ol Dekhaw';

  @override
  String get scriptMode => 'Ol Mode';

  @override
  String get appLanguage => 'App Bhasa';

  @override
  String get chooseLanguage => 'Bhasa bachao me';

  @override
  String get english => 'English';

  @override
  String get languageChanged => 'Bhasa badal ena';

  @override
  String get sound => 'Sadam';

  @override
  String get soundEffects => 'Sadam Effects';

  @override
  String get playSoundsForActions => 'Kam lagid sadam bajao me';

  @override
  String get dangerZone => 'Khatra Jaega';

  @override
  String get resetProgress => 'Pragati Reset';

  @override
  String get clearAllLearningData => 'Joto chet data sapha me';

  @override
  String get deleteAccount => 'Account Mitao';

  @override
  String get deleteAccountSubtitle => 'Account hamesa lagid mitao me';

  @override
  String get legal => 'Ain';

  @override
  String get privacyPolicy => 'Gopaniyata Niti';

  @override
  String get privacyPolicySubtitle => 'Account ar chet data ok\'to horok kanam';

  @override
  String get termsOfUse => 'Niyam';

  @override
  String get termsOfUseSubtitle => 'Chetgir, account, ar bichaar lagid niyam';

  @override
  String get chooseTheme => 'Theme bachao me';

  @override
  String get systemDefault => 'System default';

  @override
  String get light => 'Chanana';

  @override
  String get dark => 'Andhar';

  @override
  String get olChikiOnly => 'Khaali Ol Chiki';

  @override
  String get latinOnly => 'Khaali Latin';

  @override
  String get bothScripts => 'Bariya ol';

  @override
  String get cancel => 'Band';

  @override
  String get reset => 'Reset';

  @override
  String get resetProgressWarning =>
      'Noa em joto pragati, stars, ar streaks sapha kate. Noa kam aar undo ba hoyok\'a.';

  @override
  String get deleteAccountWarning =>
      'Noa em account ar joto data hamesa lagid mitao kate. Noa kam aar undo ba hoyok\'a.\n\nEm pragati, settings, ar nijir tethay hamesa lagid udao kata.';

  @override
  String get deletePermanently => 'Hamesa lagid mitao';

  @override
  String failedToDeleteAccount(String message) {
    return 'Account mitao kat\' bango: $message';
  }

  @override
  String get signInWithEmail => 'Email ren sign in me';

  @override
  String get magicCodeDescription =>
      'Am inag mit jaadu code pathao-a em chinah lagid. Password lakat ba.';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailHint => 'chetgir@example.com';

  @override
  String get sendCode => 'Code pathao me';

  @override
  String get continueWithoutAccount => 'Account bagich idi me';

  @override
  String get enterVerificationCode => 'Chinah Code dohoy me';

  @override
  String codeSentTo(String email) {
    return 'Am $email re code pathao len-a';
  }

  @override
  String get verificationCode => 'Chinah Code';

  @override
  String get enterCodeFromEmail => 'Email khon code dohoy me';

  @override
  String get verifyAndContinue => 'Chinah ar idi me';

  @override
  String resendCodeIn(int seconds) {
    return '${seconds}s re code aar pathao me';
  }

  @override
  String get resendCode => 'Code aar pathao me';

  @override
  String get validEmailError => 'Mit bhalo email address dohoy me';

  @override
  String get enterCodeError => 'Chinah code dohoy me';

  @override
  String get sessionExpired => 'Session khatam. Code aar pathao me.';

  @override
  String get errorCopiedToClipboard => 'Bhul clipboard re copy hoena';

  @override
  String get skip => 'Bagich';

  @override
  String get quiz => 'Quiz';

  @override
  String get noQuestionsYet => 'Abo tak kudchhi ba';

  @override
  String get goBack => 'Pichhe me';

  @override
  String get continueButton => 'Idi me';

  @override
  String get wellDone => 'Bhalo hoena!';

  @override
  String get keepPracticing => 'Abhyas idi me';

  @override
  String youScored(int score, int total) {
    return 'Em $total khon $score paolen-a';
  }

  @override
  String plusStars(int count) {
    return '+$count Stars';
  }

  @override
  String get aboutThisLesson => 'Noa path babot';

  @override
  String get completeLesson => 'Path chao me';

  @override
  String get lettersToLearn => 'Ol chetlagid';

  @override
  String get numbersToLearn => 'Ginti chetlagid';

  @override
  String get vocabulary => 'Ror';

  @override
  String get commonPhrases => 'Chalit Baat';

  @override
  String get content => 'Bichaar';

  @override
  String get takeAQuiz => 'Quiz me';

  @override
  String get testYourKnowledge => 'Em gyaan jaanch me!';

  @override
  String get noLettersAvailable => 'Abo tak ol ba';

  @override
  String get noNumbersAvailable => 'Abo tak ginti ba';

  @override
  String get noWordsAvailable => 'Abo tak ror ba';

  @override
  String get noSentencesAvailable => 'Abo tak baat ba';

  @override
  String get noLessonsAvailable => 'Abo tak path ba';

  @override
  String joharUser(String userName) {
    return 'Johar, $userName!';
  }

  @override
  String dailyProgressPercent(int percent) {
    return 'Din Pragati: $percent%';
  }

  @override
  String get milestones => 'Miitpatthar';

  @override
  String get learningTime => 'Chet Samay';

  @override
  String get time => 'Samay';

  @override
  String get resumeJourney => 'YATRA IDI ME';

  @override
  String get testYourKnowledgeTitle => 'Em Gyaan\nJaanch me!';

  @override
  String quizzesAvailable(int count) {
    return '$count Quiz menag-a';
  }

  @override
  String get start => 'SURU';

  @override
  String get discover => 'SANDHAY';

  @override
  String get couldNotLoadPaths => 'Chet path load bango';

  @override
  String get yourStats => 'EM STATS';

  @override
  String get skillsMastery => 'KAUSAL MASTER';

  @override
  String get quizAnalysis => 'QUIZ BISHLESHAN';

  @override
  String get account => 'ACCOUNT';

  @override
  String get editName => 'Nut\' badal';

  @override
  String get share => 'Adik';

  @override
  String get comingSoon => 'Nawa ased!';

  @override
  String get chooseYourAvatar => 'Em Avatar bachao me';

  @override
  String get backgroundColor => 'Rang';

  @override
  String get avatarEmoji => 'Avatar Emoji';

  @override
  String get rhymes => 'ᱵᱟᱠᱷᱮᱬ';

  @override
  String get santali => 'Santali';

  @override
  String get unlockMagic => 'Katha ar enger jaadu khul me';

  @override
  String get all => 'Joto';

  @override
  String get discoverMore => 'AAR SANDHAY';

  @override
  String get moreComing => 'Aar ased! ✨';

  @override
  String get couldNotLoadRhymes => 'ᱵᱟᱠᱷᱮᱬ load ᱵᱟᱝᱜᱚ';

  @override
  String get checkConnection => 'Em connection dekhao ar aar try me';

  @override
  String get featured => 'BISESH';

  @override
  String get listenNow => 'ABO AYUM';

  @override
  String get pause => 'THAM';

  @override
  String get getStarted => 'Suru me';

  @override
  String get loading => 'Load hoyog...';

  @override
  String get error => 'Bhul';

  @override
  String get retry => 'Aar try me';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Sapha';

  @override
  String get tryAgain => 'Aar try me';

  @override
  String get replayAnimation => 'Animation aar dekhao';

  @override
  String get sentences => 'Baat';

  @override
  String get noSentencesFound => 'Baat ba sedaena';

  @override
  String get noQuestionsFound => 'Kudchhi ba sedaena.';
}
