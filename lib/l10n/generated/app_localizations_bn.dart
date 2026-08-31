// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String helloUser(String userName) {
    return 'হ্যালো, $userName! 👋';
  }

  @override
  String get readyToLearn => 'আজ শিখতে প্রস্তুত?';

  @override
  String get dayStreak => 'দিনের স্ট্রিক';

  @override
  String get stars => 'তারকা';

  @override
  String get lessons => 'পাঠ';

  @override
  String get continueLearning => 'শেখা চালিয়ে যান';

  @override
  String get pickUpWhereLeftOff => 'যেখানে থেমেছিলেন সেখান থেকে শুরু করুন';

  @override
  String percentComplete(int percent) {
    return '$percent% সম্পূর্ণ';
  }

  @override
  String get dailyQuiz => 'দৈনিক কুইজ';

  @override
  String get practice => 'অনুশীলন';

  @override
  String get explore => 'ঘুরে দেখুন';

  @override
  String get chooseCategory => 'একটি বিভাগ বেছে নিন';

  @override
  String lessonsCount(int count) {
    return '$countটি পাঠ';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get customizeExperience => 'আপনার শেখার অভিজ্ঞতা কাস্টমাইজ করুন';

  @override
  String get appearance => 'চেহারা';

  @override
  String get darkMode => 'ডার্ক মোড';

  @override
  String get scriptDisplay => 'লিপি প্রদর্শন';

  @override
  String get scriptMode => 'লিপি মোড';

  @override
  String get appLanguage => 'অ্যাপের ভাষা';

  @override
  String get chooseLanguage => 'ভাষা বেছে নিন';

  @override
  String get english => 'ইংরেজি';

  @override
  String get languageChanged => 'ভাষা পরিবর্তন হয়েছে';

  @override
  String get sound => 'শব্দ';

  @override
  String get soundEffects => 'সাউন্ড ইফেক্ট';

  @override
  String get playSoundsForActions => 'কাজের জন্য শব্দ বাজান';

  @override
  String get dangerZone => 'ঝুঁকিপূর্ণ অঞ্চল';

  @override
  String get resetProgress => 'অগ্রগতি রিসেট করুন';

  @override
  String get clearAllLearningData => 'সব শেখার ডেটা মুছে ফেলুন';

  @override
  String get deleteAccount => 'অ্যাকাউন্ট মুছুন';

  @override
  String get deleteAccountSubtitle => 'আপনার অ্যাকাউন্ট স্থায়ীভাবে মুছুন';

  @override
  String get legal => 'আইনি';

  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get privacyPolicySubtitle =>
      'অ্যাকাউন্ট ও শেখার ডেটা কীভাবে ব্যবহৃত হয়';

  @override
  String get termsOfUse => 'ব্যবহারের শর্তাবলী';

  @override
  String get termsOfUseSubtitle => 'শিক্ষার্থী, অ্যাকাউন্ট ও কনটেন্টের নিয়ম';

  @override
  String get chooseTheme => 'থিম বেছে নিন';

  @override
  String get systemDefault => 'সিস্টেম ডিফল্ট';

  @override
  String get light => 'লাইট';

  @override
  String get dark => 'ডার্ক';

  @override
  String get olChikiOnly => 'শুধু ওলচিকি';

  @override
  String get latinOnly => 'শুধু ল্যাটিন';

  @override
  String get bothScripts => 'উভয় লিপি';

  @override
  String get cancel => 'বাতিল';

  @override
  String get reset => 'রিসেট';

  @override
  String get resetProgressWarning =>
      'এতে আপনার সব অগ্রগতি, তারকা ও স্ট্রিক মুছে যাবে। এই কাজটি আর ফেরানো যাবে না।';

  @override
  String get deleteAccountWarning =>
      'এতে আপনার অ্যাকাউন্ট ও সব সংশ্লিষ্ট ডেটা স্থায়ীভাবে মুছে যাবে। এই কাজটি আর ফেরানো যাবে না।\n\nআপনার অগ্রগতি, সেটিংস ও ব্যক্তিগত তথ্য স্থায়ীভাবে মুছে যাবে।';

  @override
  String get deletePermanently => 'স্থায়ীভাবে মুছুন';

  @override
  String failedToDeleteAccount(String message) {
    return 'অ্যাকাউন্ট মুছতে ব্যর্থ: $message';
  }

  @override
  String get signInWithEmail => 'ইমেল দিয়ে সাইন ইন করুন';

  @override
  String get magicCodeDescription =>
      'আপনার পরিচয় যাচাই করতে আমরা একটি ম্যাজিক কোড পাঠাব। পাসওয়ার্ড লাগবে না!';

  @override
  String get emailAddress => 'ইমেল ঠিকানা';

  @override
  String get emailHint => 'learner@example.com';

  @override
  String get sendCode => 'কোড পাঠান';

  @override
  String get continueWithoutAccount => 'অ্যাকাউন্ট ছাড়াই চালিয়ে যান';

  @override
  String get enterVerificationCode => 'যাচাইকরণ কোড লিখুন';

  @override
  String codeSentTo(String email) {
    return 'আমরা $email-এ একটি কোড পাঠিয়েছি';
  }

  @override
  String get verificationCode => 'যাচাইকরণ কোড';

  @override
  String get enterCodeFromEmail => 'ইমেল থেকে কোডটি লিখুন';

  @override
  String get verifyAndContinue => 'যাচাই করে এগিয়ে যান';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds সেকেন্ড পরে কোড আবার পাঠান';
  }

  @override
  String get resendCode => 'কোড আবার পাঠান';

  @override
  String get validEmailError => 'অনুগ্রহ করে একটি বৈধ ইমেল ঠিকানা দিন';

  @override
  String get enterCodeError => 'অনুগ্রহ করে যাচাইকরণ কোডটি লিখুন';

  @override
  String get sessionExpired =>
      'সেশন শেষ হয়ে গেছে। অনুগ্রহ করে কোড আবার পাঠান।';

  @override
  String get errorCopiedToClipboard => 'ত্রুটি ক্লিপবোর্ডে কপি হয়েছে';

  @override
  String get skip => 'এড়িয়ে যান';

  @override
  String get quiz => 'কুইজ';

  @override
  String get noQuestionsYet => 'এখনও কোনো প্রশ্ন নেই';

  @override
  String get goBack => 'ফিরে যান';

  @override
  String get continueButton => 'চালিয়ে যান';

  @override
  String get wellDone => 'চমৎকার!';

  @override
  String get keepPracticing => 'অনুশীলন চালিয়ে যান';

  @override
  String youScored(int score, int total) {
    return 'আপনি $total-এর মধ্যে $score পেয়েছেন';
  }

  @override
  String plusStars(int count) {
    return '+$count তারকা';
  }

  @override
  String get aboutThisLesson => 'এই পাঠ সম্পর্কে';

  @override
  String get completeLesson => 'পাঠ সম্পূর্ণ করুন';

  @override
  String get lettersToLearn => 'শেখার অক্ষরসমূহ';

  @override
  String get numbersToLearn => 'শেখার সংখ্যাগুলো';

  @override
  String get vocabulary => 'শব্দভান্ডার';

  @override
  String get commonPhrases => 'সাধারণ বাক্যাংশ';

  @override
  String get content => 'কনটেন্ট';

  @override
  String get takeAQuiz => 'কুইজ দিন';

  @override
  String get testYourKnowledge => 'এখনই আপনার জ্ঞান যাচাই করুন!';

  @override
  String get noLettersAvailable => 'এখনও কোনো অক্ষর নেই';

  @override
  String get noNumbersAvailable => 'এখনও কোনো সংখ্যা নেই';

  @override
  String get noWordsAvailable => 'এখনও কোনো শব্দ নেই';

  @override
  String get noSentencesAvailable => 'এখনও কোনো বাক্য নেই';

  @override
  String get noLessonsAvailable => 'কোনো পাঠ নেই';

  @override
  String joharUser(String userName) {
    return 'জোহার, $userName!';
  }

  @override
  String dailyProgressPercent(int percent) {
    return 'দৈনিক অগ্রগতি: $percent%';
  }

  @override
  String get milestones => 'মাইলফলক';

  @override
  String get learningTime => 'শেখার সময়';

  @override
  String get time => 'সময়';

  @override
  String get resumeJourney => 'যাত্রা চালিয়ে যান';

  @override
  String get testYourKnowledgeTitle => 'আপনার জ্ঞান\nযাচাই করুন!';

  @override
  String quizzesAvailable(int count) {
    return '$countটি কুইজ আছে';
  }

  @override
  String get start => 'শুরু';

  @override
  String get discover => 'আবিষ্কার';

  @override
  String get couldNotLoadPaths => 'শেখার পথ লোড করা যায়নি';

  @override
  String get yourStats => 'আপনার পরিসংখ্যান';

  @override
  String get skillsMastery => 'দক্ষতা আয়ত্ত';

  @override
  String get quizAnalysis => 'কুইজ বিশ্লেষণ';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get editName => 'নাম সম্পাদনা';

  @override
  String get share => 'শেয়ার';

  @override
  String get comingSoon => 'শীঘ্রই আসছে!';

  @override
  String get chooseYourAvatar => 'আপনার অবতার বেছে নিন';

  @override
  String get backgroundColor => 'পেছনের রং';

  @override
  String get avatarEmoji => 'অবতার ইমোজি';

  @override
  String get rhymes => 'বাখেড়';

  @override
  String get santali => 'সানতালি';

  @override
  String get unlockMagic => 'গল্প ও গানের জাদু আনলক করুন';

  @override
  String get all => 'সব';

  @override
  String get discoverMore => 'আরও আবিষ্কার';

  @override
  String get moreComing => 'আরও শীঘ্রই আসছে! ✨';

  @override
  String get couldNotLoadRhymes => 'বাখেড় লোড করা যায়নি';

  @override
  String get checkConnection => 'সংযোগ পরীক্ষা করে আবার চেষ্টা করুন';

  @override
  String get featured => 'বিশেষ';

  @override
  String get listenNow => 'এখনই শুনুন';

  @override
  String get pause => 'থামান';

  @override
  String get getStarted => 'শুরু করুন';

  @override
  String get loading => 'লোড হচ্ছে...';

  @override
  String get error => 'ত্রুটি';

  @override
  String get retry => 'আবার চেষ্টা';

  @override
  String get undo => 'পূর্বাবস্থা';

  @override
  String get clear => 'মুছুন';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get replayAnimation => 'অ্যানিমেশন আবার চালান';

  @override
  String get sentences => 'বাক্য';

  @override
  String get noSentencesFound => 'কোনো বাক্য পাওয়া যায়নি';

  @override
  String get noQuestionsFound => 'কোনো প্রশ্ন পাওয়া যায়নি।';

  @override
  String get streakActiveTitle => 'সাপ্তাহিক স্ট্রিক চালু';

  @override
  String get streakIdleTitle => 'আপনার স্ট্রিক শুরু করুন';

  @override
  String get streakActiveSubtitle => 'আপনার শিখা বাড়াতে শিখতে থাকুন!';

  @override
  String get streakIdleSubtitle =>
      'আপনার শিখা জ্বালাতে যেকোনো কাজ সম্পূর্ণ করুন!';

  @override
  String get streakStartLearning => 'শেখা শুরু করুন';

  @override
  String streakDaysBadge(int count) {
    return '$count দিন';
  }

  @override
  String streakFooterActive(int count, int total) {
    return 'এই সপ্তাহে আপনি $total দিনের মধ্যে $count দিন অনুশীলন করেছেন। চালিয়ে যান!';
  }

  @override
  String get streakFooterIdle =>
      'এই সপ্তাহে এখনও কোনো অনুশীলন হয়নি — শুরু করতে যেকোনো কাজ বেছে নিন!';

  @override
  String streakWeekSemantics(int count, int total) {
    return 'এই সপ্তাহ: $total দিনের মধ্যে $count দিন অনুশীলন করেছেন';
  }

  @override
  String get dayDetailNoActivity => 'কোনো কার্যকলাপ রেকর্ড হয়নি';

  @override
  String get dayDetailPracticeSession => 'অনুশীলন সেশন';

  @override
  String get dayDetailStreakDay => 'স্ট্রিক দিন';

  @override
  String get dayDetailQuiz => 'কুইজ';

  @override
  String get dayUpcoming => 'আসন্ন';

  @override
  String get dayPracticed => 'অনুশীলন করা হয়েছে';

  @override
  String get dayNotPracticed => 'অনুশীলন করা হয়নি';

  @override
  String milestoneLevelProgressCaption(String from, String to) {
    return 'লেভেল অগ্রগতি · $from → $to';
  }

  @override
  String get homeDiscover => 'আবিষ্কার';

  @override
  String get homeSwipeHint => 'সোয়াইপ করুন';

  @override
  String get homeExploreHint => 'ঘুরে দেখুন';

  @override
  String get guestSignInCta => 'আপনার অগ্রগতি বাঁচাতে সাইন ইন করুন';

  @override
  String get nbaBadgeStartHere => 'এখান থেকে শুরু';

  @override
  String get nbaTitleFirstLetters => 'আপনার প্রথম ওলচিকি অক্ষর শিখুন';

  @override
  String get nbaSubFirstLetters =>
      'মূল বর্ণমালা দিয়ে শুরু করে সানতালি লেখা আনলক করুন।';

  @override
  String get nbaCtaBeginLesson => 'পাঠ শুরু করুন';

  @override
  String get nbaBadgeNextStep => 'পরবর্তী ধাপ';

  @override
  String get nbaTitleNumbers => 'সানতালি সংখ্যা অনুশীলন করুন';

  @override
  String get nbaSubNumbers =>
      'প্রতিদিনের গণনা ও সংখ্যার শব্দে আত্মবিশ্বাস গড়ুন।';

  @override
  String get nbaCtaPracticeNumbers => 'সংখ্যা অনুশীলন করুন';

  @override
  String get nbaBadgeMistakes => 'অনুশীলন দরকার';

  @override
  String get nbaTitleMistakes => 'ভুলগুলোকে জ্ঞানে রূপান্তর করুন';

  @override
  String nbaSubMistakes(int count) {
    return 'আপনার পর্যালোচনা ও আয়ত্তের জন্য $countটি প্রশ্ন আছে।';
  }

  @override
  String get nbaCtaReviewMistakes => 'ভুলগুলো পর্যালোচনা করুন';

  @override
  String get nbaBadgeStreakRisk => 'স্ট্রিক ঝুঁকিতে';

  @override
  String get nbaTitleStreakRisk => 'আপনার দৈনিক গতি ধরে রাখুন';

  @override
  String nbaSubStreakRisk(int count) {
    return 'একটি দ্রুত কুইজ বা পাঠ আজ আপনার $count দিনের স্ট্রিক বাঁচাবে।';
  }

  @override
  String get nbaCtaQuickReview => 'দ্রুত পর্যালোচনা';

  @override
  String get nbaBadgeTryBakhed => 'বাখেড় চেষ্টা করুন';

  @override
  String get nbaTitleTryBakhed => 'একটি সাংস্কৃতিক ছড়া শুনুন';

  @override
  String get nbaSubTryBakhed =>
      '৩০ সেকেন্ডের জন্য সুন্দর সানতালি মৌখিক কবিতায় ডুবে যান।';

  @override
  String get nbaCtaListenNow => 'এখনই শুনুন';

  @override
  String get nbaBadgeAllDone => 'সব সম্পূর্ণ';

  @override
  String get nbaTitleAllDone => 'আপনি সব শেষ করেছেন — দারুণ!';

  @override
  String get nbaSubAllDone =>
      'নতুন পাঠ আসছে। যেকোনো সময় বাখেড় আবার দেখুন বা পর্যালোচনা করুন।';

  @override
  String get nbaCtaExploreBakhed => 'বাখেড় ঘুরে দেখুন';

  @override
  String get affirmationListen => 'শুনুন';

  @override
  String get affirmationStop => 'থামান';

  @override
  String get affirmationMarkRead => 'পঠিত হিসেবে চিহ্নিত করুন';

  @override
  String get affirmationRead => 'পড়ুন';

  @override
  String get todaysMissionTitle => 'আজকের মিশন';

  @override
  String missionsDoneCount(int done) {
    return '$done/4 সম্পন্ন';
  }

  @override
  String get hindi => 'হিন্দি';

  @override
  String get bengali => 'বাংলা';

  @override
  String get odia => 'ওড়িয়া';

  @override
  String get teachingLanguage => 'শেখার ভাষা';

  @override
  String get teachingLanguageSubtitle => 'অর্থ ও ব্যাখ্যার জন্য ব্যবহৃত হয়';

  @override
  String get lessonAudioMode => 'পাঠের অডিও';

  @override
  String get lessonAudioModeSubtitle =>
      'সানতালি ও অনুবাদ অডিও কীভাবে বাজবে বেছে নিন';

  @override
  String get onboardingStepLanguageTitle => 'আপনি কোন ভাষা সবচেয়ে ভালো বোঝেন?';

  @override
  String get onboardingStepProficiencyTitle => 'আপনি কতটা সানতালি জানেন?';

  @override
  String get onboardingStepGoalsTitle => 'আপনি কী অর্জন করতে চান?';

  @override
  String get onboardingStepGoalsSubtitle =>
      'এক বা একাধিক বেছে নিন — আমরা আপনার পথ ব্যক্তিগত করব।';

  @override
  String get onboardingStepAudioTitle => 'পাঠের অডিও কীভাবে চলবে?';

  @override
  String get onboardingStepReadyTitle => 'আপনি প্রায় প্রস্তুত!';

  @override
  String get proficiencyNone => 'আমি সানতালি জানি না';

  @override
  String get proficiencyUnderstandsSome => 'আমি কিছু সানতালি বুঝি';

  @override
  String get proficiencyFluentSpeaker => 'আমি সানতালি বলি';

  @override
  String get proficiencyBeginnerReader => 'আমি একটু ওলচিকি পড়তে পারি';

  @override
  String get proficiencyFluentReader => 'আমি ওলচিকি পড়তে জানি';

  @override
  String get goalSpeakSantali => 'সানতালি বলা';

  @override
  String get goalUnderstandSantali => 'সানতালি বোঝা';

  @override
  String get goalReadOlChiki => 'ওলচিকি পড়া';

  @override
  String get goalWriteOlChiki => 'ওলচিকি লেখা';

  @override
  String get goalLearnEverything => 'সব কিছু শেখা';

  @override
  String get goalHelpMyChild => 'আমার সন্তানকে শেখাতে সাহায্য করা';

  @override
  String get goalPrepareExam => 'স্কুল বা পরীক্ষার প্রস্তুতি';

  @override
  String get audioModeTargetOnly => 'শুধু সানতালি';

  @override
  String get audioModeBilingual => 'সানতালি, তারপর আমার ভাষা';

  @override
  String get audioModeTranslationOnDemand => 'শুধু ট্যাপ করলে অনুবাদ বাজাবে';

  @override
  String get dailyGoalLabel => 'দৈনিক লক্ষ্য';

  @override
  String minutesPerDay(int minutes) {
    return '$minutes মিনিট/দিন';
  }

  @override
  String get downloadStarterAudio => 'স্টার্টার অডিও ডাউনলোড করুন';

  @override
  String get downloadStarterAudioSubtitle => 'প্রথম দিন থেকেই অফলাইন শিখুন';

  @override
  String get backButton => 'পেছনে';
}
