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

  @override
  String get joharLoading => 'জোহার... লোড হচ্ছে...';

  @override
  String get somethingWentWrong => 'কিছু একটা ভুল হয়েছে!';

  @override
  String get offlineMode => 'অফলাইন মোড। সংরক্ষিত কনটেন্ট দেখানো হচ্ছে।';

  @override
  String get offlineProgressCached =>
      'অফলাইন। অগ্রগতি ডিভাইসে সংরক্ষিত হয়েছে।';

  @override
  String get syncingProgress => 'অগ্রগতি সিঙ্ক হচ্ছে...';

  @override
  String get progressSynced => 'অগ্রগতি সিঙ্ক হয়েছে!';

  @override
  String get failedToSyncProgress => 'অগ্রগতি সিঙ্ক করা যায়নি।';

  @override
  String get processing => 'প্রসেস হচ্ছে...';

  @override
  String get pleaseLogInToPurchase => 'কোর্স কিনতে অনুগ্রহ করে লগ ইন করুন।';

  @override
  String get creatingSecureOrder => 'নিরাপদ সার্ভার অর্ডার তৈরি হচ্ছে...';

  @override
  String get openingPaymentGateway => 'পেমেন্ট গেটওয়ে খোলা হচ্ছে...';

  @override
  String get verifyingPayment => 'সার্ভারের সাথে পেমেন্ট যাচাই হচ্ছে...';

  @override
  String get courseUnlocked => 'কোর্স সফলভাবে আনলক হয়েছে!';

  @override
  String get failedToCreateOrder => 'পেমেন্ট অর্ডার তৈরি করা যায়নি';

  @override
  String get paymentVerificationFailed => 'পেমেন্ট যাচাই ব্যর্থ';

  @override
  String checkoutUnexpectedError(String error) {
    return 'চেকআউটে অপ্রত্যাশিত ত্রুটি: $error';
  }

  @override
  String unlockCourse(String amount) {
    return 'কোর্স আনলক করুন (₹$amount)';
  }

  @override
  String get trustBadgeSecureCheckout =>
      'Razorpay দিয়ে 256-bit এনক্রিপ্টেড চেকআউট • তাৎক্ষণিক অ্যাক্সেস';

  @override
  String get webMonetizationRestrictedTitle => 'ওয়েবে মনিটাইজেশন সীমাবদ্ধ';

  @override
  String get webMonetizationNotice =>
      'Razorpay চেকআউট এবং App Store রিভিউ শুধু Olitun মোবাইল অ্যাপে সমর্থিত। আনলক করতে Android/iOS-এ খুলুন।';

  @override
  String get aboutThisCourse => 'এই কোর্স সম্পর্কে';

  @override
  String get courseOutcome => 'কোর্সের ফলাফল';

  @override
  String get premiumCourseBadge => 'প্রিমিয়াম কোর্স';

  @override
  String get maranJauharTitle => 'মরন জোহার! 🎉';

  @override
  String get startLearning => 'শেখা শুরু করুন';

  @override
  String get paywallValueOfflineTitle => 'সম্পূর্ণ অফলাইন প্যাক অ্যাক্সেস';

  @override
  String get paywallValueOfflineSubtitle =>
      'যেকোনো সময় অফলাইনে শেখার জন্য পাঠ, উচ্চারণ অডিও এবং কুইজ ডাউনলোড করুন।';

  @override
  String get paywallValueAiTitle => 'আনলিমিটেড AI অনুবাদ';

  @override
  String get paywallValueAiSubtitle =>
      'কোনো ক্যোয়ারি সীমা ছাড়াই তাৎক্ষণিক ওলচিকি অনুবাদ এবং উচ্চারণ নির্দেশনা।';

  @override
  String get paywallValueAdFreeTitle => 'শূন্য বিজ্ঞাপন বাধা';

  @override
  String get paywallValueAdFreeSubtitle =>
      'সব মডিউলে 100% বিভ্রান্তিমুক্ত ভাষা অনুশীলন।';

  @override
  String get paywallValueLifetimeTitle => 'আজীবন অ্যাক্সেসের গ্যারান্টি';

  @override
  String get paywallValueLifetimeSubtitle =>
      'একবারই পরিশোধ — কোনো পুনরাবৃত্ত ফি, সাবস্ক্রিপশন বা লুকানো চার্জ নেই।';

  @override
  String get navLearn => 'শিখুন';

  @override
  String get navBakhed => 'বাখেড়';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String navTabSemantics(String label) {
    return '$label ট্যাব';
  }

  @override
  String navItemSemantics(String label) {
    return '$label নেভিগেশন আইটেম';
  }

  @override
  String get kudosMistake1 => 'ভুলগুলো পর্যালোচিত। এভাবেই দক্ষতা তৈরি হয়।';

  @override
  String get kudosMistake2 =>
      'দক্ষতা তৈরি হচ্ছে! আপনি ভুলগুলোকে জ্ঞানে রূপান্তর করেছেন।';

  @override
  String get kudosMistake3 => 'দারুণ! ভুল সংশোধনই সাবলীলতার রহস্য।';

  @override
  String get kudosMistake4 =>
      'চমৎকার পর্যালোচনা! ভুল শুধরে আপনি আরও দ্রুত শিখছেন।';

  @override
  String get reviewToday => 'আজকের রিভিউ';

  @override
  String get reviewLoading => 'আপনার রিভিউ লোড হচ্ছে…';

  @override
  String get reviewDueOne => '1টি রিভিউ বাকি';

  @override
  String reviewDueOther(int count) {
    return '$countটি রিভিউ বাকি';
  }

  @override
  String reviewDueSubtitle(int minutes) {
    return '~$minutes মিনিট · শুরু করা পাঠ থেকে';
  }

  @override
  String get reviewStart => 'রিভিউ শুরু করুন';

  @override
  String get reviewCaughtUp => 'সব শেষ।';

  @override
  String reviewCaughtUpRetained(int count) {
    return 'এ পর্যন্ত $countটি বিষয় মনে আছে। মনে রাখা চালিয়ে যান।';
  }

  @override
  String get reviewCaughtUpEmpty =>
      'নিচে একটি পাঠ শুরু করুন — যা শিখবেন তা এখানে রিভিউতে আসবে।';

  @override
  String get reviewContinueLearning => 'শেখা চালিয়ে যান';

  @override
  String get reviewLearnNew => 'নতুন কিছু শিখুন';

  @override
  String reviewRetained(int count) {
    return '$countটি মনে আছে';
  }

  @override
  String get reviewExit => 'রিভিউ থেকে বেরিয়ে যান';

  @override
  String reviewSessionTitle(int current, int total) {
    return 'আজকের রিভিউ $current / $total';
  }

  @override
  String get reviewSessionTitleBare => 'আজকের রিভিউ';

  @override
  String get reviewComplete => 'রিভিউ সম্পূর্ণ';

  @override
  String get reviewCorrectFeedback => 'সঠিক — ভালো মনে আছে।';

  @override
  String get reviewWrongFeedback => 'আরেকটু — এটা শীঘ্রই ফিরে আসবে।';

  @override
  String reviewCorrectAnswer(String answer) {
    return 'সঠিক উত্তর: $answer';
  }

  @override
  String get reviewHintTyping => 'ধীরে ধীরে প্রতিটি ধ্বনি লিখুন।';

  @override
  String get reviewHintListening => 'আবার শুনুন — ধ্বনির সঙ্গে অর্থ মেলান।';

  @override
  String get reviewHintRecognition => 'অল চিকি অক্ষর থেকে উচ্চারণ করুন।';

  @override
  String get reviewRepromptListen => 'শুনুন';

  @override
  String get reviewRepromptWrite => 'অল চিকিতে লিখুন';

  @override
  String get reviewRepromptMeaning => 'এর অর্থ কী?';

  @override
  String get reviewPlayAudio => 'অডিও চালান';

  @override
  String get reviewReplayAudio => 'আবার শুনুন';

  @override
  String get reviewCheck => 'যাচাই করুন';

  @override
  String get reviewFinish => 'রিভিউ শেষ করুন';

  @override
  String get reviewBackHome => 'হোমে ফিরুন';

  @override
  String get reviewDone => 'হয়ে গেছে';

  @override
  String get reviewCaughtUpShort =>
      'কিছু বাকি নেই। লুপ চালিয়ে যেতে নিচে নতুন কিছু শিখুন।';

  @override
  String reviewSummaryScore(int correct, int total, int accuracy) {
    return '$totalটির মধ্যে $correctটি সঠিক ($accuracy%)';
  }

  @override
  String reviewSummaryMastered(int mastered, int stars) {
    return '$masteredটি আয়ত্ত · +$stars স্টার';
  }

  @override
  String get reviewSummaryRecovery =>
      'বাদ পড়াগুলো শীঘ্রই ফিরে আসবে — এটাই সিস্টেমের কাজ, ব্যর্থতা নয়।';

  @override
  String get reviewLoadError => 'আপনার রিভিউ লোড করা যায়নি';

  @override
  String reviewLoadErrorBody(int count) {
    return 'আপনার $countটি বাকি রিভিউ নিরাপদ — পাঠের বিষয়বস্তু লোড হয়নি। সংযোগ দেখে আবার চেষ্টা করুন।';
  }

  @override
  String get notifReviewTitleOne => '1টি রিভিউ প্রস্তুত';

  @override
  String notifReviewTitleOther(int count) {
    return '$countটি রিভিউ প্রস্তুত';
  }

  @override
  String notifReviewBodyOne(int minutes) {
    return '1টি বিষয় রিভিউয়ের জন্য প্রস্তুত (~$minutes মিনিট)। সময় পেলে আজকের রিভিউ খুলুন।';
  }

  @override
  String notifReviewBodyOther(int count, int minutes) {
    return '$countটি বিষয় রিভিউয়ের জন্য প্রস্তুত (~$minutes মিনিট)। সময় পেলে আজকের রিভিউ খুলুন।';
  }

  @override
  String get notifStruggleTitle => 'কঠিনগুলো ফিরে এসেছে';

  @override
  String get notifStruggleBodyOne =>
      'যে শব্দটি কঠিন লেগেছিল, সেটা আবার বাকি — একবার চর্চা করলেই পাকা হবে।';

  @override
  String notifStruggleBodyOther(int count) {
    return '$countটি কঠিন শব্দ আবার বাকি — একবার চর্চা করলেই পাকা হবে।';
  }

  @override
  String get notifGentleTitle => 'আপনার সাঁওতালি অপেক্ষা করছে';

  @override
  String get notifGentleBody => 'ছোট্ট রিভিউ শেখাটা তাজা রাখে। তাড়া নেই।';

  @override
  String get santaliAiVoice => 'সাঁওতালি এআই ভয়েস';

  @override
  String get closeVoiceStudio => 'ভয়েস স্টুডিও বন্ধ করুন';

  @override
  String get createVoiceAction => 'ভয়েস তৈরি করুন';

  @override
  String get creatingVoiceProgress => 'ভয়েস তৈরি হচ্ছে...';

  @override
  String get voiceStatusWorking => 'আপনার কথায় সাঁওতালি কণ্ঠ দেওয়া হচ্ছে…';

  @override
  String get voiceStatusIdle => 'টাইপ করুন। শুনুন। শেয়ার করুন।';

  @override
  String voiceStatusPlaying(String voice) {
    return 'চলছে • $voice';
  }

  @override
  String get voiceStatusReady => 'প্রস্তুত • প্লে করতে ট্যাপ করুন';

  @override
  String get voiceStatusOpenPlayer => 'ভয়েস প্রস্তুত • নিচে প্লেয়ার খুলুন';

  @override
  String get voiceCacheTip =>
      'পরামর্শ: আগের অডিও তৎক্ষণাৎ এবং বিনামূল্যে প্লে হয় — এটি ক্যাশ থেকে বাজে।';

  @override
  String get voiceDownloadFailed => 'ডাউনলোড ব্যর্থ হয়েছে।';

  @override
  String get voiceInputHint => 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ? — অল চিকিতে লিখুন...';

  @override
  String get voicePlayerTab => 'প্লেয়ার';

  @override
  String get voiceCreatingBack => 'আপনার ভয়েস তৈরি করা হচ্ছে…';

  @override
  String get voiceEmptyBack => 'আপনার ভয়েস এখানে প্রদর্শিত হবে';

  @override
  String get voiceEditText => 'লেখা সম্পাদনা করুন';

  @override
  String get voiceDismiss => 'বাতিল করুন';

  @override
  String get voicePlaybackSpeed => 'প্লেব্যাকের গতি';

  @override
  String get voiceSaving => 'সংরক্ষণ করা হচ্ছে…';

  @override
  String get voiceDownload => 'ডাউনলোড';

  @override
  String get voiceRegenerate => 'পুনরায় তৈরি করুন';

  @override
  String get voicePickerHeader => 'ভয়েস  •  আড়াং';

  @override
  String get voiceStyleHeader => 'ধরন  •  রড়';

  @override
  String get voiceSignInUpper => 'সাইন ইন';

  @override
  String get voiceRetryUpper => 'আবার চেষ্টা করুন';

  @override
  String get aiStudioTitle => 'এআই স্টুডিও';

  @override
  String get aiStudioToolTranscribe => 'ট্রান্সক্রাইব';

  @override
  String get aiStudioToolTranslate => 'অনুবাদ';

  @override
  String get aiStudioToolScan => 'স্ক্যান';

  @override
  String get aiStudioHeadline =>
      'কাগজ বা কণ্ঠ থেকে\nব্যবহারযোগ্য কথায় রূপান্তর।';

  @override
  String get aiStudioSubhead =>
      'লেখা অনুবাদ করুন, সংক্ষিপ্ত রেকর্ডিং ট্রান্সক্রাইব করুন অথবা নথি স্ক্যান করুন। ব্যবহারের পূর্বে ফলাফলটি পর্যালোচনা করুন।';

  @override
  String get aiStudioStep1 => '১  ইনপুট যুক্ত করুন';

  @override
  String get aiStudioStep2 => '২  সম্মতি নিয়ে প্রক্রিয়া করুন';

  @override
  String get aiStudioStep3 => '৩  পর্যালোচনা ও ব্যবহার';

  @override
  String get aiStudioNotConfigured =>
      'এই সংস্করণে এআই প্রসেসিং উপলব্ধ নেই। আপনি এখানে পাঠ্য প্রস্তুত করতে পারেন অথবা নিচের বিনামূল্যের লিপি রূপান্তরকারী ব্যবহার করতে পারেন।';

  @override
  String get aiStudioYourText => 'আপনার লেখা';

  @override
  String get aiStudioYourAudio => 'আপনার অডিও';

  @override
  String get aiStudioYourDocument => 'আপনার নথি';

  @override
  String get aiStudioSourceLanguage => 'মূল ভাষা';

  @override
  String get aiStudioTranslateNote =>
      'সাঁওতালিতে (অল চিকি) অনুবাদ করুন। সর্বোচ্চ ২,০০০ অক্ষর।';

  @override
  String get aiStudioTextToTranslate => 'অনুবাদের লেখা';

  @override
  String get aiStudioTextPlaceholder => 'আপনার লেখা টাইপ বা পেস্ট করুন';

  @override
  String get aiStudioTextLimitError =>
      '২,০০০ বা তার কম অক্ষরের অংশ নির্বাচন করুন।';

  @override
  String get aiStudioSpeakNote =>
      'স্বাভাবিকভাবে কথা বলুন। ৩০ সেকেন্ডে রেকর্ডিং স্বয়ংক্রিয়ভাবে বন্ধ হবে। আপনি একটি WAV ফাইলও আপলোড করতে পারেন।';

  @override
  String get aiStudioRecordVoice => 'ভয়েস রেকর্ড করুন';

  @override
  String aiStudioStopRecording(String seconds) {
    return 'রেকর্ডিং থামান · $seconds সে';
  }

  @override
  String get aiStudioListening => 'শুনছি… শেষ হলে রেকর্ডিং থামান-এ ট্যাপ করুন।';

  @override
  String get aiStudioOrExistingRecording =>
      'অথবা আগের কোনো রেকর্ডিং ব্যবহার করুন';

  @override
  String get aiStudioUploadWav => 'WAV ফাইল আপলোড করুন';

  @override
  String get aiStudioReplaceRecording => 'রেকর্ডিং পরিবর্তন করুন';

  @override
  String get aiStudioOpening => 'খোলা হচ্ছে…';

  @override
  String get aiStudioDocNote =>
      'PDF, PNG বা JPG · ১০ এমবি এবং ১০ পৃষ্ঠা পর্যন্ত\nপঠনযোগ্য স্পষ্ট সোজা পৃষ্ঠা ব্যবহার করুন।';

  @override
  String get aiStudioChooseFile => 'ফাইল নির্বাচন করুন';

  @override
  String get aiStudioReplaceFile => 'ফাইল পরিবর্তন করুন';

  @override
  String get aiStudioCapturePage => 'পৃষ্ঠার ছবি তুলুন';

  @override
  String get aiStudioProcessing =>
      'প্রক্রিয়াকরণ চলছে… এই স্ক্রিনটি খোলা রাখুন।';

  @override
  String aiStudioProcessWithAi(String tool) {
    return 'এআই দিয়ে $tool';
  }

  @override
  String get aiStudioReviewAndUse => 'পর্যালোচনা ও ব্যবহার';

  @override
  String get aiStudioResultPlaceholder => 'আপনার ফলাফল এখানে প্রদর্শিত হবে।';

  @override
  String get aiStudioResultDisclaimer =>
      'কিছুই প্রকাশ বা শেয়ার করা হয়নি। লেখা প্রস্তুত হলে আপনি তা সংশোধন করতে পারেন, কপি করতে পারেন বা পরবর্তী ধাপের জন্য অংশ বেছে নিতে পারেন।';

  @override
  String get aiStudioReviewHelper =>
      'কপি বা শেয়ার করার আগে এআই লেখা পর্যালোচনা করুন।';

  @override
  String get aiStudioCopy => 'কপি করুন';

  @override
  String get aiStudioShare => 'শেয়ার করুন';

  @override
  String get aiStudioCopyToShare => 'শেয়ার করতে কপি করুন';

  @override
  String get aiStudioTranslateResult => 'ফলাফল অনুবাদ করুন';

  @override
  String get aiStudioSendToVoiceStudio => 'ভয়েস স্টুডিও';

  @override
  String get aiStudioAuto => 'অটো';

  @override
  String get aiStudioLive => 'লাইভ';

  @override
  String get aiStudioThinking => 'ভাবছে';

  @override
  String get aiStudioScanningLive =>
      'আপনার পৃষ্ঠা পড়া হচ্ছে — আপডেট এখানে লাইভ দেখা যাবে।';

  @override
  String get aiStudioLookingForConverter =>
      'বিনামূল্যে লিপি রূপান্তরকারী খুঁজছেন?';

  @override
  String get aiStudioDisclaimer =>
      'এআই ফলাফলে ভুল থাকতে পারে; ব্যবহারের পূর্বে নাম, সংখ্যা এবং বানান যাচাই করুন।';

  @override
  String aiStudioPassageNote(int limit) {
    return '$limit অক্ষর পর্যন্ত একটি অংশ বেছে নিন বা সম্পাদনা করুন। আপনার মূল ফলাফল অপরিবর্তিত থাকবে।';
  }

  @override
  String get aiStudioPassageToSend => 'পাঠানোর অংশ';

  @override
  String get aiStudioPassageLimitError =>
      'এগিয়ে যেতে অংশটি ছোট করুন। কোনো কিছুই নিজে থেকে কাটা হয়নি।';

  @override
  String get aiStudioUploadPrompt =>
      'আপনার ছবি আপলোড করুন বা ক্যামেরা দিয়ে স্ক্যান করুন';

  @override
  String get aiStudioUploadFormats => 'PDF, PNG বা JPG · সর্বোচ্চ ১০ MB';

  @override
  String aiStudioJobId(String id) {
    return 'Job: $id';
  }

  @override
  String get aiStudioCheckStatus => 'অবস্থা যাচাই করুন';

  @override
  String get aiStudioReplaceWithScan => 'স্ক্যান দিয়ে প্রতিস্থাপন করুন';

  @override
  String get aiStudioEditSource => 'উৎস সম্পাদনা করুন';

  @override
  String get olitun => 'Olitun';

  @override
  String get welcomeTagline => 'ওল চিকি লিপি শিখুন';

  @override
  String errorLoadingContent(String error) {
    return 'Error loading content: $error';
  }

  @override
  String get startQuiz2 => 'কুইজ শুরু করুন';

  @override
  String get practiceTyping => 'টাইপিং অভ্যাস করুন';

  @override
  String mediaDuration(int seconds) {
    return 'Duration: ${seconds}s';
  }

  @override
  String get noLearningContent => 'এখনো কোনো শেখার উপাদান নেই।';

  @override
  String errorLoadingDetails(String error) {
    return 'Error loading details: $error';
  }

  @override
  String get culturalNotesPreparing => 'সাংস্কৃতিক নোট প্রস্তুত করা হচ্ছে।';

  @override
  String culturalNoteSource(String source) {
    return 'Source: $source';
  }

  @override
  String get noVocabularyItems => 'কোনো শব্দভাণ্ডার আইটেম সংজ্ঞায়িত নেই।';

  @override
  String get lyricsBeingAdded => 'গানের কথা যোগ করা হচ্ছে';

  @override
  String get bakhedLabel => 'BAKHED';

  @override
  String get wordLabel => 'শব্দ';

  @override
  String get cancelLower => 'বাতিল করুন';

  @override
  String greetingDayPart(String part) {
    return 'ᱡᱚᱦᱟᱨ • $part';
  }

  @override
  String get homePickupSubtitle =>
      'যেখানে থেমেছিলেন সেখান থেকে শুরু — ছোট পা, প্রতিদিন।';

  @override
  String get aiTranslatorTitle => 'AI Translator';

  @override
  String get voiceSpeakWithConfidence => 'আত্মবিশ্বাসের সাথে কথা বলুন';

  @override
  String get aiStudioPromoBadge => 'NEW • AI STUDIO';

  @override
  String get aiStudioPromoSubtitle => 'আপনার স্বপ্নের ভাষা তৈরি করুন।';

  @override
  String get learnMore => 'আরও জানুন';

  @override
  String get instantTranslate => 'তাৎক্ষণিক অনুবাদ';

  @override
  String get anyLanguageToOlChiki => 'যেকোনো ভাষা থেকে ওল চিকি';

  @override
  String get aiBadge => 'AI';

  @override
  String get yourLearningPath => 'আপনার শেখার পথ';

  @override
  String stepOfPath(int step, int total) {
    return 'Step $step of $total: ';
  }

  @override
  String get learningPathSubtitle =>
      'আপনার সাঁওতালি স্তরের সাথে মিলে একটি নির্দেশিত পথ।';

  @override
  String get santaliOlChikiLabel => 'সাঁওতালি (ওল চিকি)';

  @override
  String get magicTranslatePrivacyNote =>
      'ম্যাজিক ট্রান্সলেট আপনার ছগুলি ডিভাইসেই প্রসেস করে এবং আপনার গোপনীয়তার সম্মান করে।';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get aiVoicePromoBadge => 'NEW • AI VOICE';

  @override
  String get aiVoiceTitle => 'AI Voice';

  @override
  String get aiVoicePromoSubtitle => 'যা খুশি টাইপ করুন — সাঁওতালিতে শুনুন।';

  @override
  String get tryNow => 'এখনই চেষ্টা করুন';

  @override
  String get k15Styles => 'ᱟᱲᱟᱝ • 15 styles';

  @override
  String get backToLearningPaths => 'শেখার পথে ফিরে যান';

  @override
  String get learningPathsHeader => 'শেখার পথ';

  @override
  String get chooseYourJourney => 'আপনার যাত্রা বেছে নিন';

  @override
  String get morePaths => 'আরও পথ';

  @override
  String get plusTenXp => '+10 XP';

  @override
  String get strokeOrderHint => 'স্ট্রোক ক্রম মনে রাখার চেষ্টা করুন';

  @override
  String traceAccuracy(String feedback, int percent) {
    return '$feedback  Accuracy: $percent%';
  }

  @override
  String get niceWork => 'চমৎকার!';

  @override
  String youScoredOutOf(int score, int total) {
    return 'You scored $score out of $total';
  }

  @override
  String percentFormat(int percent) {
    return '$percent%';
  }

  @override
  String get backLabel => 'পিছনে';

  @override
  String get quizKeyboardHint =>
      'তীর কী দিয়ে নেভিগেট করুন  •  1-4 দিয়ে বেছে নিন  •  Enter ↵ দিয়ে জমা দিন';

  @override
  String scoreOnly(int score) {
    return '$score';
  }

  @override
  String get pressEnter => 'Enter ↵';

  @override
  String get readyToTestYourself => 'আপনি নিজেকে পরীক্ষা দিতে প্রস্তুত?';

  @override
  String get takeTheQuiz => 'কুইজ নিন';

  @override
  String get skipForNow => 'এখন বাদ দিন';

  @override
  String get browseView => 'ব্রাউজ দৃশ্য';

  @override
  String get openDictionary => 'অভিধান খুলুন';

  @override
  String get learnLabel => 'শিখুন';

  @override
  String get doneLabel => 'হয়ে গেছে';

  @override
  String get lockedForNowTitle => 'অপেক্ষা করুন • এখনের জন্য লক';

  @override
  String completeBlockerFirst(String blocker) {
    return 'Complete “$blocker” first to crack it open.';
  }

  @override
  String get interactiveHtmlTitle => 'ইন্টারঅ্যাক্টিভ পাঠ অভিজ্ঞতা';

  @override
  String get interactiveHtmlBody =>
      'এই পাঠটি ইন্টারঅ্যাক্টিভ উপাদান সহ আসে। দেখতে নিচে স্ক্রল করুন।';

  @override
  String get openInteractiveContent => 'ইন্টারঅ্যাক্টিভ উপাদান খুলুন';

  @override
  String get recommendedLabel => 'সুপারিশকৃত';

  @override
  String get audioPlaybackHint => 'অডিও চালাতে ট্যাপ করুন';

  @override
  String get finishReviewing => 'পর্যালোচনা শেষ করুন';

  @override
  String get takeQuizNow => 'এখনই কুইজ নিন';

  @override
  String stepOfTotal(int step, int total) {
    return 'STEP $step OF $total';
  }

  @override
  String get checkConnectionPeriod =>
      'আপনার সংযোগ যাচাই করুন এবং আবার চেষ্টা করুন।';

  @override
  String sentencePronunciation(String pronunciation) {
    return 'Pronunciation: $pronunciation';
  }

  @override
  String get santaliLearner => 'সাঁওতালি শিক্ষার্থী';

  @override
  String get streakTip => 'স্ট্রিক বজায় রাখতে প্রতিদিন ৩টি পাঠ সম্পন্ন করুন।';

  @override
  String get continueLearningArrow => 'শেখা চালিয়ে যান →';

  @override
  String get olitun2 => 'Olitun';

  @override
  String get santaliOlChikiTag => 'SANTALI • OL CHIKI';

  @override
  String get menuLabel => 'মেনু';

  @override
  String get olitunPwaVersion => 'Olitun PWA • v2.4';

  @override
  String onboardingCounter(String current, String total) {
    return '$current · $total';
  }

  @override
  String get goalsTitle => 'লক্ষ্য';

  @override
  String get goalsSubtitle => 'শেখার আগে লক্ষ্য নির্ধারণ করুন।';

  @override
  String get requiredLabel => 'আবশ্যক';

  @override
  String get stepOneOfFive => 'ধাপ ৫-এর ১';

  @override
  String get languageSubtitle => 'ভাষা বেছে নিন এবং আপনার পছন্দ পরিবর্তন করুন';

  @override
  String get prefsSaveFailed =>
      'আপনার সেটিংস সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get selectMotherTongueToast =>
      'চালিয়ে যেতে অনুগ্রহ করে আপনার মাতৃভাষা / শিক্ষণ ভাষা নির্বাচন করুন।';

  @override
  String get onboardingHeadline => 'ওল চিকি শিখুন,\nএকসাথে এক ধাপ';

  @override
  String get familiarityTitle => 'পরিচিতির স্তর';

  @override
  String get familiaritySubtitle =>
      'আপনার পরিচিতির ভিত্তিতে শেখা অনুকূলন করুন।';

  @override
  String get displayTitle => 'আপনি উপাদান কীভাবে দেখতে চান?';

  @override
  String get displaySubtitle =>
      'আপনার পছন্দের লিপি প্রদর্শন বেছে নিন। আপনি যেকোনো সময় এটি পরিবর্তন করতে পারেন।';

  @override
  String get practiceGoalTitle => 'অভ্যাসের লক্ষ্য';

  @override
  String get practiceGoalSubtitle =>
      'অভ্যাসের লক্ষ্য নির্ধারণ করুন — প্রতিদিন কতগুলি পাঠ সম্পন্ন করতে হবে স্ট্রিক বজায় রাখতে।';

  @override
  String get olitunWordmark => 'OLITUN';

  @override
  String get learnOlChiki => 'ওল চিকি শিখুন';

  @override
  String get spaceKey => 'SPACE';

  @override
  String get practicedSuccessfully => 'সফলভাবে অভ্যাস করা হয়েছে';

  @override
  String get revealAndContinue => 'দেখান এবং চালিয়ে যান';

  @override
  String get systemDiagnosticsTitle => 'সিস্টেম ডায়াগনস্টিক ও রানটাইম';

  @override
  String get systemDiagnosticsSubtitle =>
      'বেনামী রানটাইম পারফরম্যান্স ও ডায়াগনস্টিক টেলিমেট্রি';

  @override
  String get diagnosticPayloadPreview => 'ডায়াগনস্টিক পেলোড প্রিভিউ';

  @override
  String get diagnosticPayloadCopied =>
      'ডায়াগনস্টিক পেলোড ক্লিপবোর্ডে কপি হয়েছে!';

  @override
  String get diagnosticsTileSubtitle =>
      'রানটাইম ডেটা, মেমরি ব্যবহার ও ক্র্যাশ ডায়াগনস্টিক দেখুন';

  @override
  String get deleteAllDownloadsTitle => 'সব ডাউনলোড মুছবেন?';

  @override
  String get deleteAllDownloadsBody =>
      'এটি এই ডিভাইস থেকে প্রতিটি অফলাইন গল্পের অডিও ক্লিপ মুছে ফেলে। আপনি যখন সেগুলি খুলবেন, গল্পগুলি আবার স্ট্রিম হবে।';

  @override
  String get editYourName => 'আপনার নাম সম্পাদনা করুন';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String get indigenousLanguagesTitle => 'স্বদেশী ভাষা প্ল্যাটফর্ম';

  @override
  String get indigenousLanguagesSubtitle =>
      'পূর্ব ভারতের স্বদেশী লিপি ও উপজাতীয় ভাষা অন্বেষণ করুন';

  @override
  String packsComingSoon(String name) {
    return '$name content & audio packs are coming soon!';
  }

  @override
  String learningLanguageSetTo(String name, String script) {
    return 'Learning language set to $name ($script)';
  }

  @override
  String get audioPack => 'অডিও প্যাক';

  @override
  String get offlineLessons => 'অফলাইন পাঠ';

  @override
  String lettersCount(int count) {
    return '$count letters';
  }

  @override
  String get demoLabel => 'DEMO';

  @override
  String masteryAccuracy(int percent) {
    return 'Accuracy: $percent%';
  }

  @override
  String get masteryProgression => 'আয়ত্তের অগ্রগতি';

  @override
  String get nextMilestone => 'পরবর্তী মাইলফলক';

  @override
  String roadToLevel(String level) {
    return 'Road to $level';
  }

  @override
  String badgeUnlockHint(String name, String target) {
    return 'To unlock the $name badge: $target';
  }

  @override
  String get closestBadge => 'নিকটতম ব্যাজ অর্জন';

  @override
  String unlockBadge(String name) {
    return 'Unlock the $name Badge';
  }

  @override
  String get reminderFrequency => 'রিমাইন্ডার পুনরাবৃত্তি';

  @override
  String get reminderFrequencySubtitle =>
      'ওল চিকি অভ্যাস করতে কতবার রিমাইন্ডার চান, বেছে নিন।';

  @override
  String get dailySchedulePreview => 'দৈনিক সূচি প্রিভিউ';

  @override
  String get sendTestNotification => 'পরীক্ষামূলক বিজ্ঞপ্তি পাঠান';

  @override
  String get chooseYourAvatarLower => 'আপনার অবতার বেছে নিন';

  @override
  String get avatarAnimationsFailed => 'অবতার অ্যানিমেশন লোড করা যায়নি।';

  @override
  String get tryAgainLower => 'আবার চেষ্টা করুন';

  @override
  String get avatarSaveFailed => 'অবতার সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String since(String date) {
    return 'Since $date';
  }

  @override
  String get overallProgress => 'সামগ্রিক অগ্রগতি';

  @override
  String get noBookingsFound => 'কোনো বুকিং পাওয়া যায়নি';

  @override
  String get bookingsEmptyHint =>
      'বখেদ ট্যাবের অধীনে আপনার অনুষ্ঠানের জন্য যাচাইকৃত আবৃত্তিকারী বুক করুন।';

  @override
  String get waitlistBookingsFailed => 'ওয়েটলিস্ট বুকিং লোড করা যায়নি।';

  @override
  String get assessmentScore => 'মূল্যায়ন স্কোর';

  @override
  String get avgLabel => 'গড়';

  @override
  String get adPrivacyRegionNote =>
      'আপনার অঞ্চলের জন্য বিজ্ঞাপন গোপনীয়তা সেটিংস প্রয়োজন নেই।';

  @override
  String get signOutConfirmBody =>
      'আপনি কি সত্যিই এই ডিভাইসে আপনার অ্যাকাউন্ট থেকে সাইন আউট করতে চান?';

  @override
  String get learningLanguageScript => 'শেখার ভাষা ও লিপি';

  @override
  String get mistakeReview => 'ভুল পর্যালোচনা';

  @override
  String get allCaughtUp => 'সব হয়ে গেছে!';

  @override
  String get noMistakesToReview =>
      'কোনো ভুল পর্যালোচনার প্রয়োজন নেই। আপনার সাঁওতালি শিকড় শক্ত!';

  @override
  String get mistakesMastered => 'ভুলগুলি আয়ত্ত হয়েছে!';

  @override
  String get moreQuizzes => 'আরও কুইজ';

  @override
  String get challengeYourself => 'নিজেকে চ্যালেঞ্জ করুন';

  @override
  String get chooseAQuiz => 'একটি কুইজ বেছে নিন';

  @override
  String get noQuizzesYet => 'এখনো কোনো কুইজ নেই!';

  @override
  String get completeLessonsFirst => 'আগে কয়েকটি পাঠ সম্পন্ন করুন';

  @override
  String get quizUnavailable => 'কুইজ অনুপলব্ধ';

  @override
  String get quizUnavailableDetail =>
      'কুইজ অনুপলব্ধ — এই পাঠে কুইজের জন্য পর্যাপ্ত প্রশ্ন নেই।';

  @override
  String get quizLoadFailed => 'কুইজ লোড করা যায়নি।';

  @override
  String translation(String text) {
    return 'Translation: \"$text\"';
  }

  @override
  String get audioNotAvailable => 'এই প্রশ্নের জন্য অডিও উপলব্ধ নেই।';

  @override
  String get mistakeReviewBadge => 'ভুল পর্যালোচনা';

  @override
  String get takesTwoMin => '২ মিনিট লাগে';

  @override
  String get mistakesQuote =>
      '“ভুলগুলি শেখার একটি অংশ — গুলি পুনরাবৃত্তি এড়িয়ে চলুন।”';

  @override
  String get quizKeyboardHintAlt =>
      '↑ / ↓ নেভিগেট  •  1-4 বেছে নিন  •  Enter ↵ জমা দিন';

  @override
  String get watchAdBonusStars => '+৫০ বোনাস তারার জন্য বিজ্ঞাপন দেখুন';

  @override
  String get shareAchievement => 'অর্জন শেয়ার করুন';

  @override
  String get bonusStarsEarned => '৫০ বোনাস তারা অর্জিত! ⭐';

  @override
  String get rewardedAdCooldown =>
      'রিওয়ার্ডেড বিজ্ঞাপন ঠান্ডা হচ্ছে। পরে আবার চেষ্টা করুন।';

  @override
  String get scoreLabel => 'স্কোর';

  @override
  String get accuracyLabel => 'নির্ভুলতা';

  @override
  String get starsEarned => 'অর্জিত তারা';

  @override
  String get maxCombo => 'সর্বোচ্চ কম্বো';

  @override
  String get reviewMistakes => 'ভুলগুলি পর্যালোচনা করুন';

  @override
  String get reviewMistakesSubtitle =>
      'আপনার আয়ত্ত গড়তে যা ভুল হয়েছে তা পর্যালোচনা করুন! লহা সে!';

  @override
  String get correctColon => 'সঠিক উত্তর:';

  @override
  String get correctAnswerColon => 'সঠিক উত্তর:';

  @override
  String get insightGuidance => 'অন্তর্দৃষ্টি ও নির্দেশনা:';

  @override
  String get selectMissingWord => 'হারানো শব্দ নির্বাচন করুন:';

  @override
  String questionsWithLevel(int count, String level) {
    return '$count questions • $level';
  }

  @override
  String get startQuiz => 'কুইজ শুরু করুন';

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String get outOfHearts => 'হৃদয় শেষ!';

  @override
  String outOfHeartsSummary(int score, int total, int stars) {
    return 'আপনি $score/$total সঠিক উত্তর দিয়েছেন এবং এ পর্যন্ত $stars তারা অর্জন করেছেন। অভ্যাস চালিয়ে যান।';
  }

  @override
  String get watchAdRefillHearts =>
      'হৃদয় পূরণ করতে বিজ্ঞাপন দেখুন (বিনামূল্যে)';

  @override
  String get backToQuizzes => 'কুইজে ফিরে যান';

  @override
  String get heartsRefilled => 'হৃদয় পূর্ণ হয়েছে! ❤️❤️❤️';

  @override
  String get rewardedAdCooldownReset =>
      'রিওয়ার্ডেড বিজ্ঞাপন ঠান্ডা হচ্ছে। অনুগ্রহ করে নিয়মিত রিসেট চেষ্টা করুন।';

  @override
  String currentOfTotal(int current, int total) {
    return '$current/$total';
  }

  @override
  String get rhymesEndNote => 'এখানে বাকি সব — নতুন বখেদ শীঘ্রই আসছে!';

  @override
  String get rhymesLoadFailed => 'সুরকথা লোড করা যায়নি।';

  @override
  String get bakhedPreparing => 'বখেদ প্রস্তুত করা হচ্ছে';

  @override
  String get bakhedPreparingSubtitle =>
      'প্রকাশের পরে নতুন শ্রব্য গল্প এখানে দেখা যাবে।';

  @override
  String failedToJoinWaitlist(String error) {
    return 'Failed to join waitlist: $error';
  }

  @override
  String get waitlistJoined => 'ওয়েটলিস্টে যোগ দিয়েছেন! 🎉';

  @override
  String get waitlistJoinedBody =>
      'আপনি তালিকায় যোগ দিয়েছেন! পাওয়া গেলে আমরা আপনাকে জানাব।';

  @override
  String get great => 'দারুণ';

  @override
  String get joinBintiGuruWaitlist => 'বিন্দি গুরু ওয়েটলিস্টে যোগ দিন';

  @override
  String get bintiGuruFormSubtitle =>
      'আপনার অনুষ্ঠান সম্পর্কে আমাদের জানান। আমরা উপলব্ধ প্রমাণিত আবৃত্তিকারী খুঁজব।';

  @override
  String get submitWaitlistEntry => 'এন্ট্রি জমা দিন';

  @override
  String get bookVerifiedBintiGuru => 'যাচাইকৃত বিন্দি গুরু বুক করুন';

  @override
  String get bintiGuruLandingBody =>
      'বিন্দি সাঁওতালি আবৃত্তির পবিত্র কাজ। করম, সোহরাই, বাহা, বিয়ে, শ্রাদ্ধ বা অন্য যে কোনো অনুষ্ঠানের জন্য — প্রমাণিত আবৃত্তিকারী খুঁজুন।';

  @override
  String get joinWaitlistNow => 'এখনই ওয়েটলিস্টে যোগ দিন';

  @override
  String get howItWorks => 'এটি যেভাবে কাজ করে';

  @override
  String get newBadge => 'নতুন';

  @override
  String get ctrlEnterCreate => 'Ctrl+Enter ↵ to create';

  @override
  String charCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get svgLoadFailed => 'SVG অ্যানিমেশন লোড করা যায়নি';

  @override
  String get signIn => 'সাইন ইন';

  @override
  String get shareCardTagline => 'OLITUN • ᱚᱞ ᱪᱤᱠᱤ';

  @override
  String get shareCardFooter => 'Learn Santali (Ol Chiki) • olitun.app';

  @override
  String get shareTextCopied => 'শেয়ারের টেক্সট ক্লিপবোর্ডে কপি হয়েছে। 📋';

  @override
  String tracingPracticeGlyph(String glyph) {
    return 'Tracing practice — $glyph';
  }

  @override
  String mastery(int current, int required) {
    return 'Mastery: $current/$required';
  }

  @override
  String get onboardingStepsBody =>
      'অক্ষর দিয়ে শুরু করুন, শব্দ গড়ুন, কুইজ দিয়ে অভ্যাস করুন, এবং আপনার সাঁওতালি শেখার যাত্রা চালিয়ে যান।';

  @override
  String practiceModeLabel(String mode) {
    return 'Practice • $mode';
  }

  @override
  String greatJobTakeQuiz(String title) {
    return 'Great job! Take “$title” now to test your knowledge.';
  }

  @override
  String wordsNeedPractice(int count) {
    return '$count word(s) need(s) practice';
  }

  @override
  String voiceClipMeta(String voice, String style, String instant) {
    return '$voice • $style$instant';
  }

  @override
  String get continueWithEmail => 'ইমেল দিয়ে চালিয়ে যান';

  @override
  String get exploreAsGuest => 'অতিথি হিসেবে দেখুন';

  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get guestSessionFailed =>
      'অতিথি সেশন শুরু করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get couldNotLoadLessons => 'পাঠ লোড করা যায়নি';

  @override
  String get shareMessageCopied => 'শেয়ার বার্তা ক্লিপবোর্ডে কপি হয়েছে! 📋';

  @override
  String get shareMilestoneTitle => 'আপনার মাইলফলক শেয়ার করুন';

  @override
  String get shareMilestoneSubtitle =>
      'সাঁওতালি ও ওল চিকি শেখার জন্য অন্যদের অনুপ্রাণিত করুন';

  @override
  String get copyTextSummary => 'লেখার সারাংশ কপি করুন';

  @override
  String get traceGuidelines => 'অক্ষরের নির্দেশিকা নির্ভুলভাবে ট্রেস করুন';

  @override
  String get showExample => 'উদাহরণ দেখান';

  @override
  String get signOut => 'সাইন আউট করুন';

  @override
  String get delete => 'মুছুন';

  @override
  String get finishLesson => 'পাঠ শেষ করুন';

  @override
  String get couldNotOpenShareSheet => 'শেয়ার শিট খোলা যায়নি';

  @override
  String get couldNotClearDownloads => 'ডাউনলোড পরিষ্কার করা যায়নি';

  @override
  String get progressLoadFailed =>
      'আপনার সংরক্ষিত অগ্রগতি এখনো নিরাপদে আছে। অনুগ্রহ করে এই দৃশ্য রিফ্রেশ করুন।';

  @override
  String get couldNotLoadProgress => 'অগ্রগতি লোড করা যায়নি';

  @override
  String get couldNotLoadQuizzes => 'কুইজ লোড করা যায়নি';

  @override
  String get contentLoadFailed =>
      'কন্টেন্ট লোড করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';
}
