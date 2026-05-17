// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String helloUser(String userName) {
    return 'Hello, $userName! 👋';
  }

  @override
  String get readyToLearn => 'Ready to learn today?';

  @override
  String get dayStreak => 'Day Streak';

  @override
  String get stars => 'Stars';

  @override
  String get lessons => 'Lessons';

  @override
  String get continueLearning => 'Continue Learning';

  @override
  String get pickUpWhereLeftOff => 'Pick up where you left off';

  @override
  String percentComplete(int percent) {
    return '$percent% Complete';
  }

  @override
  String get dailyQuiz => 'Daily Quiz';

  @override
  String get practice => 'Practice';

  @override
  String get explore => 'Explore';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String lessonsCount(int count) {
    return '$count lessons';
  }

  @override
  String get settings => 'Settings';

  @override
  String get customizeExperience => 'Customize your learning experience';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get scriptDisplay => 'Script Display';

  @override
  String get scriptMode => 'Script Mode';

  @override
  String get appLanguage => 'App Language';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get english => 'English';

  @override
  String get languageChanged => 'Language updated';

  @override
  String get sound => 'Sound';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get playSoundsForActions => 'Play sounds for actions';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get resetProgress => 'Reset Progress';

  @override
  String get clearAllLearningData => 'Clear all learning data';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountSubtitle => 'Permanently delete your account';

  @override
  String get legal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle =>
      'How account and learning data are handled';

  @override
  String get termsOfUse => 'Terms Of Use';

  @override
  String get termsOfUseSubtitle => 'Rules for learners, accounts, and content';

  @override
  String get chooseTheme => 'Choose Theme';

  @override
  String get systemDefault => 'System default';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get olChikiOnly => 'Ol Chiki only';

  @override
  String get latinOnly => 'Latin only';

  @override
  String get bothScripts => 'Both scripts';

  @override
  String get cancel => 'Cancel';

  @override
  String get reset => 'Reset';

  @override
  String get resetProgressWarning =>
      'This will clear all your progress, stars, and streaks. This action cannot be undone.';

  @override
  String get deleteAccountWarning =>
      'This will permanently delete your account and all associated data. This action cannot be undone.\n\nYour progress, settings, and personal information will be permanently removed.';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String failedToDeleteAccount(String message) {
    return 'Failed to delete account: $message';
  }

  @override
  String get signInWithEmail => 'Sign In with Email';

  @override
  String get magicCodeDescription =>
      'We\'ll send you a magic code to verify your identity. No password needed!';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailHint => 'learner@example.com';

  @override
  String get sendCode => 'Send Code';

  @override
  String get continueWithoutAccount => 'Continue without an account';

  @override
  String get enterVerificationCode => 'Enter Verification Code';

  @override
  String codeSentTo(String email) {
    return 'We sent a code to $email';
  }

  @override
  String get verificationCode => 'Verification Code';

  @override
  String get enterCodeFromEmail => 'Enter code from email';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get resendCode => 'Resend code';

  @override
  String get validEmailError => 'Please enter a valid email address';

  @override
  String get enterCodeError => 'Please enter the verification code';

  @override
  String get sessionExpired => 'Session expired. Please resend the code.';

  @override
  String get errorCopiedToClipboard => 'Error copied to clipboard';

  @override
  String get skip => 'Skip';

  @override
  String get quiz => 'Quiz';

  @override
  String get noQuestionsYet => 'No questions yet';

  @override
  String get goBack => 'Go Back';

  @override
  String get continueButton => 'Continue';

  @override
  String get wellDone => 'Well Done!';

  @override
  String get keepPracticing => 'Keep Practicing';

  @override
  String youScored(int score, int total) {
    return 'You scored $score out of $total';
  }

  @override
  String plusStars(int count) {
    return '+$count Stars';
  }

  @override
  String get aboutThisLesson => 'About this lesson';

  @override
  String get completeLesson => 'Complete Lesson';

  @override
  String get lettersToLearn => 'Letters to Learn';

  @override
  String get numbersToLearn => 'Numbers to Learn';

  @override
  String get vocabulary => 'Vocabulary';

  @override
  String get commonPhrases => 'Common Phrases';

  @override
  String get content => 'Content';

  @override
  String get takeAQuiz => 'Take a Quiz';

  @override
  String get testYourKnowledge => 'Test your knowledge now!';

  @override
  String get noLettersAvailable => 'No letters available yet';

  @override
  String get noNumbersAvailable => 'No numbers available yet';

  @override
  String get noWordsAvailable => 'No words available yet';

  @override
  String get noSentencesAvailable => 'No sentences available yet';

  @override
  String get noLessonsAvailable => 'No lessons available';

  @override
  String joharUser(String userName) {
    return 'Johar, $userName!';
  }

  @override
  String dailyProgressPercent(int percent) {
    return 'Daily Progress: $percent%';
  }

  @override
  String get milestones => 'Milestones';

  @override
  String get learningTime => 'Learning Time';

  @override
  String get time => 'Time';

  @override
  String get resumeJourney => 'RESUME JOURNEY';

  @override
  String get testYourKnowledgeTitle => 'Test Your\nKnowledge!';

  @override
  String quizzesAvailable(int count) {
    return '$count Quizzes Available';
  }

  @override
  String get start => 'START';

  @override
  String get discover => 'DISCOVER';

  @override
  String get couldNotLoadPaths => 'Could not load learning paths';

  @override
  String get yourStats => 'YOUR STATS';

  @override
  String get skillsMastery => 'SKILLS MASTERY';

  @override
  String get quizAnalysis => 'QUIZ ANALYSIS';

  @override
  String get account => 'ACCOUNT';

  @override
  String get editName => 'Edit Name';

  @override
  String get share => 'Share';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get chooseYourAvatar => 'Choose Your Avatar';

  @override
  String get backgroundColor => 'Background Color';

  @override
  String get avatarEmoji => 'Avatar Emoji';

  @override
  String get rhymes => 'Bakhed';

  @override
  String get santali => 'Santali';

  @override
  String get unlockMagic => 'Unlock the magic of stories & songs';

  @override
  String get all => 'All';

  @override
  String get discoverMore => 'DISCOVER MORE';

  @override
  String get moreComing => 'More coming soon! ✨';

  @override
  String get couldNotLoadRhymes => 'Could not load bakhed';

  @override
  String get checkConnection => 'Check your connection and try again';

  @override
  String get featured => 'FEATURED';

  @override
  String get listenNow => 'LISTEN NOW';

  @override
  String get pause => 'PAUSE';

  @override
  String get getStarted => 'Get Started';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get undo => 'Undo';

  @override
  String get clear => 'Clear';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get replayAnimation => 'Replay Animation';

  @override
  String get sentences => 'Sentences';

  @override
  String get noSentencesFound => 'No sentences found';

  @override
  String get noQuestionsFound => 'No questions found.';
}
