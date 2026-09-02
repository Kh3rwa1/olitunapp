// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String helloUser(String userName) {
    return 'नमस्ते, $userName! 👋';
  }

  @override
  String get readyToLearn => 'आज सीखने के लिए तैयार?';

  @override
  String get dayStreak => 'दिन की स्ट्रीक';

  @override
  String get stars => 'सितारे';

  @override
  String get lessons => 'पाठ';

  @override
  String get continueLearning => 'सीखना जारी रखें';

  @override
  String get pickUpWhereLeftOff => 'जहाँ छोड़ा था वहीं से शुरू करें';

  @override
  String percentComplete(int percent) {
    return '$percent% पूर्ण';
  }

  @override
  String get dailyQuiz => 'दैनिक क्विज़';

  @override
  String get practice => 'अभ्यास';

  @override
  String get explore => 'खोजें';

  @override
  String get chooseCategory => 'एक श्रेणी चुनें';

  @override
  String lessonsCount(int count) {
    return '$count पाठ';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get customizeExperience => 'अपना सीखने का अनुभव अनुकूलित करें';

  @override
  String get appearance => 'दिखावट';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get scriptDisplay => 'लिपि प्रदर्शन';

  @override
  String get scriptMode => 'लिपि मोड';

  @override
  String get appLanguage => 'ऐप भाषा';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get languageChanged => 'भाषा बदल दी गई';

  @override
  String get sound => 'ध्वनि';

  @override
  String get soundEffects => 'साउंड इफ़ेक्ट्स';

  @override
  String get playSoundsForActions => 'क्रियाओं के लिए ध्वनि चलाएँ';

  @override
  String get dangerZone => 'खतरनाक क्षेत्र';

  @override
  String get resetProgress => 'प्रगति रीसेट करें';

  @override
  String get clearAllLearningData => 'सारा सीखने का डेटा साफ़ करें';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountSubtitle => 'अपना खाता स्थायी रूप से हटाएँ';

  @override
  String get legal => 'कानूनी';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get privacyPolicySubtitle =>
      'खाता और सीखने का डेटा कैसे संभाला जाता है';

  @override
  String get termsOfUse => 'उपयोग की शर्तें';

  @override
  String get termsOfUseSubtitle => 'शिक्षार्थियों, खातों और सामग्री के नियम';

  @override
  String get chooseTheme => 'थीम चुनें';

  @override
  String get systemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get olChikiOnly => 'केवल ओलचिकी';

  @override
  String get latinOnly => 'केवल लैटिन';

  @override
  String get bothScripts => 'दोनों लिपियाँ';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get reset => 'रीसेट';

  @override
  String get resetProgressWarning =>
      'इससे आपकी सारी प्रगति, सितारे और स्ट्रीक मिट जाएँगे। यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get deleteAccountWarning =>
      'इससे आपका खाता और सारा संबंधित डेटा स्थायी रूप से हट जाएगा। यह क्रिया पूर्ववत नहीं की जा सकती।\n\nआपकी प्रगति, सेटिंग्स और व्यक्तिगत जानकारी स्थायी रूप से हटा दी जाएगी।';

  @override
  String get deletePermanently => 'स्थायी रूप से हटाएँ';

  @override
  String failedToDeleteAccount(String message) {
    return 'खाता हटाने में विफल: $message';
  }

  @override
  String get signInWithEmail => 'ईमेल से साइन इन करें';

  @override
  String get magicCodeDescription =>
      'हम आपकी पहचान सत्यापित करने के लिए एक जादुई कोड भेजेंगे। पासवर्ड की ज़रूरत नहीं!';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get emailHint => 'learner@example.com';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get continueWithoutAccount => 'बिना खाते के जारी रखें';

  @override
  String get enterVerificationCode => 'सत्यापन कोड दर्ज करें';

  @override
  String codeSentTo(String email) {
    return 'हमने $email पर एक कोड भेजा है';
  }

  @override
  String get verificationCode => 'सत्यापन कोड';

  @override
  String get enterCodeFromEmail => 'ईमेल से कोड दर्ज करें';

  @override
  String get verifyAndContinue => 'सत्यापित करें और जारी रखें';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंड में कोड फिर भेजें';
  }

  @override
  String get resendCode => 'कोड फिर भेजें';

  @override
  String get validEmailError => 'कृपया एक मान्य ईमेल पता दर्ज करें';

  @override
  String get enterCodeError => 'कृपया सत्यापन कोड दर्ज करें';

  @override
  String get sessionExpired => 'सत्र समाप्त हो गया। कृपया कोड फिर भेजें।';

  @override
  String get errorCopiedToClipboard => 'त्रुटि क्लिपबोर्ड पर कॉपी हुई';

  @override
  String get skip => 'छोड़ें';

  @override
  String get quiz => 'क्विज़';

  @override
  String get noQuestionsYet => 'अभी कोई प्रश्न नहीं';

  @override
  String get goBack => 'वापस जाएँ';

  @override
  String get continueButton => 'जारी रखें';

  @override
  String get wellDone => 'शाबाश!';

  @override
  String get keepPracticing => 'अभ्यास जारी रखें';

  @override
  String youScored(int score, int total) {
    return 'आपने $total में से $score अंक पाए';
  }

  @override
  String plusStars(int count) {
    return '+$count सितारे';
  }

  @override
  String get aboutThisLesson => 'इस पाठ के बारे में';

  @override
  String get completeLesson => 'पाठ पूरा करें';

  @override
  String get lettersToLearn => 'सीखने वाले अक्षर';

  @override
  String get numbersToLearn => 'सीखने वाली संख्याएँ';

  @override
  String get vocabulary => 'शब्दावली';

  @override
  String get commonPhrases => 'सामान्य वाक्यांश';

  @override
  String get content => 'सामग्री';

  @override
  String get takeAQuiz => 'क्विज़ लें';

  @override
  String get testYourKnowledge => 'अभी अपना ज्ञान परखें!';

  @override
  String get noLettersAvailable => 'अभी कोई अक्षर उपलब्ध नहीं';

  @override
  String get noNumbersAvailable => 'अभी कोई संख्या उपलब्ध नहीं';

  @override
  String get noWordsAvailable => 'अभी कोई शब्द उपलब्ध नहीं';

  @override
  String get noSentencesAvailable => 'अभी कोई वाक्य उपलब्ध नहीं';

  @override
  String get noLessonsAvailable => 'कोई पाठ उपलब्ध नहीं';

  @override
  String joharUser(String userName) {
    return 'जोहार, $userName!';
  }

  @override
  String dailyProgressPercent(int percent) {
    return 'दैनिक प्रगति: $percent%';
  }

  @override
  String get milestones => 'मील के पत्थर';

  @override
  String get learningTime => 'सीखने का समय';

  @override
  String get time => 'समय';

  @override
  String get resumeJourney => 'यात्रा जारी रखें';

  @override
  String get testYourKnowledgeTitle => 'अपना ज्ञान\nपरखें!';

  @override
  String quizzesAvailable(int count) {
    return '$count क्विज़ उपलब्ध';
  }

  @override
  String get start => 'शुरू';

  @override
  String get discover => 'खोजें';

  @override
  String get couldNotLoadPaths => 'सीखने के रास्ते लोड नहीं हो सके';

  @override
  String get yourStats => 'आपके आँकड़े';

  @override
  String get skillsMastery => 'कौशल निपुणता';

  @override
  String get quizAnalysis => 'क्विज़ विश्लेषण';

  @override
  String get account => 'खाता';

  @override
  String get editName => 'नाम बदलें';

  @override
  String get share => 'शेयर करें';

  @override
  String get comingSoon => 'जल्द आ रहा है!';

  @override
  String get chooseYourAvatar => 'अपना अवतार चुनें';

  @override
  String get backgroundColor => 'पृष्ठभूमि रंग';

  @override
  String get avatarEmoji => 'अवतार इमोजी';

  @override
  String get rhymes => 'बाखेड़';

  @override
  String get santali => 'संताली';

  @override
  String get unlockMagic => 'कहानियों और गीतों का जादू खोलें';

  @override
  String get all => 'सभी';

  @override
  String get discoverMore => 'और खोजें';

  @override
  String get moreComing => 'और जल्द आ रहा है! ✨';

  @override
  String get couldNotLoadRhymes => 'बाखेड़ लोड नहीं हो सके';

  @override
  String get checkConnection => 'अपना कनेक्शन जाँचें और फिर कोशिश करें';

  @override
  String get featured => 'विशेष';

  @override
  String get listenNow => 'अभी सुनें';

  @override
  String get pause => 'रोकें';

  @override
  String get getStarted => 'शुरू करें';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get error => 'त्रुटि';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get undo => 'पूर्ववत करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get replayAnimation => 'ऐनिमेशन फिर चलाएँ';

  @override
  String get sentences => 'वाक्य';

  @override
  String get noSentencesFound => 'कोई वाक्य नहीं मिला';

  @override
  String get noQuestionsFound => 'कोई प्रश्न नहीं मिला।';

  @override
  String get streakActiveTitle => 'साप्ताहिक स्ट्रीक सक्रिय';

  @override
  String get streakIdleTitle => 'अपनी स्ट्रीक शुरू करें';

  @override
  String get streakActiveSubtitle => 'अपनी लौ बढ़ाने के लिए सीखते रहें!';

  @override
  String get streakIdleSubtitle =>
      'अपनी लौ जलाने के लिए कोई भी गतिविधि पूरी करें!';

  @override
  String get streakStartLearning => 'सीखना शुरू करें';

  @override
  String streakDaysBadge(int count) {
    return '$count दिन';
  }

  @override
  String streakFooterActive(int count, int total) {
    return 'इस सप्ताह आपने $total में से $count दिन अभ्यास किया। जारी रखें!';
  }

  @override
  String get streakFooterIdle =>
      'इस सप्ताह अभी तक कोई अभ्यास नहीं — शुरू करने के लिए कोई गतिविधि चुनें!';

  @override
  String streakWeekSemantics(int count, int total) {
    return 'इस सप्ताह: $total में से $count दिन अभ्यास किया';
  }

  @override
  String get dayDetailNoActivity => 'कोई गतिविधि दर्ज नहीं';

  @override
  String get dayDetailPracticeSession => 'अभ्यास सत्र';

  @override
  String get dayDetailStreakDay => 'स्ट्रीक दिन';

  @override
  String get dayDetailQuiz => 'क्विज़';

  @override
  String get dayUpcoming => 'आगामी';

  @override
  String get dayPracticed => 'अभ्यास किया';

  @override
  String get dayNotPracticed => 'अभ्यास नहीं किया';

  @override
  String milestoneLevelProgressCaption(String from, String to) {
    return 'स्तर प्रगति · $from → $to';
  }

  @override
  String get homeDiscover => 'खोजें';

  @override
  String get homeSwipeHint => 'स्वाइप करें';

  @override
  String get homeExploreHint => 'खोजें';

  @override
  String get guestSignInCta => 'अपनी प्रगति सहेजने के लिए साइन इन करें';

  @override
  String get nbaBadgeStartHere => 'यहाँ से शुरू करें';

  @override
  String get nbaTitleFirstLetters => 'अपने पहले ओलचिकी अक्षर सीखें';

  @override
  String get nbaSubFirstLetters =>
      'मूल वर्णमाला से शुरू करें और संताली लेखन खोलें।';

  @override
  String get nbaCtaBeginLesson => 'पाठ शुरू करें';

  @override
  String get nbaBadgeNextStep => 'अगला कदम';

  @override
  String get nbaTitleNumbers => 'संताली संख्याओं का अभ्यास करें';

  @override
  String get nbaSubNumbers =>
      'रोज़मर्रा की गिनती और संख्या शब्दों में आत्मविश्वास बढ़ाएँ।';

  @override
  String get nbaCtaPracticeNumbers => 'संख्याओं का अभ्यास करें';

  @override
  String get nbaBadgeMistakes => 'अभ्यास ज़रूरी';

  @override
  String get nbaTitleMistakes => 'गलतियों को सीख में बदलें';

  @override
  String nbaSubMistakes(int count) {
    return 'आपके पास समीक्षा और निपुणता के लिए $count प्रश्न हैं।';
  }

  @override
  String get nbaCtaReviewMistakes => 'गलतियों की समीक्षा करें';

  @override
  String get nbaBadgeStreakRisk => 'स्ट्रीक खतरे में';

  @override
  String get nbaTitleStreakRisk => 'अपनी दैनिक गति बनाए रखें';

  @override
  String nbaSubStreakRisk(int count) {
    return 'एक त्वरित क्विज़ या पाठ आज आपकी $count दिन की स्ट्रीक सुरक्षित करेगा।';
  }

  @override
  String get nbaCtaQuickReview => 'त्वरित समीक्षा';

  @override
  String get nbaBadgeTryBakhed => 'बाखेड़ आज़माएँ';

  @override
  String get nbaTitleTryBakhed => 'एक सांस्कृतिक कविता सुनें';

  @override
  String get nbaSubTryBakhed =>
      '30 सेकंड के लिए सुंदर संताली मौखिक कविता में डूब जाएँ।';

  @override
  String get nbaCtaListenNow => 'अभी सुनें';

  @override
  String get nbaBadgeAllDone => 'सब पूर्ण';

  @override
  String get nbaTitleAllDone => 'आपने सब कुछ पूरा किया — शानदार!';

  @override
  String get nbaSubAllDone =>
      'नए पाठ रास्ते में हैं। कभी भी बाखेड़ दोबारा देखें या समीक्षा करें।';

  @override
  String get nbaCtaExploreBakhed => 'बाखेड़ खोजें';

  @override
  String get affirmationListen => 'सुनें';

  @override
  String get affirmationStop => 'रोकें';

  @override
  String get affirmationMarkRead => 'पढ़ा हुआ चिह्नित करें';

  @override
  String get affirmationRead => 'पढ़ें';

  @override
  String get todaysMissionTitle => 'आज का मिशन';

  @override
  String missionsDoneCount(int done) {
    return '$done/4 पूर्ण';
  }

  @override
  String get hindi => 'हिंदी';

  @override
  String get bengali => 'बांग्ला';

  @override
  String get odia => 'ओड़िया';

  @override
  String get teachingLanguage => 'शिक्षण भाषा';

  @override
  String get teachingLanguageSubtitle =>
      'अर्थ और व्याख्या के लिए उपयोग होती है';

  @override
  String get lessonAudioMode => 'पाठ ऑडियो';

  @override
  String get lessonAudioModeSubtitle =>
      'चुनें कि संताली और अनुवाद ऑडियो कैसे चले';

  @override
  String get onboardingStepLanguageTitle =>
      'आप कौन सी भाषा सबसे अच्छे से समझते हैं?';

  @override
  String get onboardingStepProficiencyTitle => 'आपको कितनी संताली आती है?';

  @override
  String get onboardingStepGoalsTitle => 'आप क्या हासिल करना चाहते हैं?';

  @override
  String get onboardingStepGoalsSubtitle =>
      'एक या अधिक चुनें — हम आपका रास्ता व्यक्तिगत बनाएंगे।';

  @override
  String get onboardingStepAudioTitle => 'पाठ का ऑडियो कैसे चलना चाहिए?';

  @override
  String get onboardingStepReadyTitle => 'आप लगभग तैयार हैं!';

  @override
  String get proficiencyNone => 'मुझे संताली नहीं आती';

  @override
  String get proficiencyUnderstandsSome => 'मुझे कुछ संताली समझ आती है';

  @override
  String get proficiencyFluentSpeaker => 'मुझे संताली बोलनी आती है';

  @override
  String get proficiencyBeginnerReader => 'मुझे थोड़ी ओलचिकी पढ़नी आती है';

  @override
  String get proficiencyFluentReader => 'मुझे ओलचिकी पढ़नी आती है';

  @override
  String get goalSpeakSantali => 'संताली बोलना';

  @override
  String get goalUnderstandSantali => 'संताली समझना';

  @override
  String get goalReadOlChiki => 'ओलचिकी पढ़ना';

  @override
  String get goalWriteOlChiki => 'ओलचिकी लिखना';

  @override
  String get goalLearnEverything => 'सब कुछ सीखना';

  @override
  String get goalHelpMyChild => 'अपने बच्चे को सिखाने में मदद करना';

  @override
  String get goalPrepareExam => 'स्कूल या परीक्षा की तैयारी';

  @override
  String get audioModeTargetOnly => 'केवल संताली';

  @override
  String get audioModeBilingual => 'संताली, फिर मेरी भाषा';

  @override
  String get audioModeTranslationOnDemand => 'अनुवाद केवल टैप करने पर चलाएँ';

  @override
  String get dailyGoalLabel => 'दैनिक लक्ष्य';

  @override
  String minutesPerDay(int minutes) {
    return '$minutes मिनट/दिन';
  }

  @override
  String get downloadStarterAudio => 'स्टार्टर ऑडियो डाउनलोड करें';

  @override
  String get downloadStarterAudioSubtitle => 'पहले दिन से ऑफ़लाइन सीखें';

  @override
  String get backButton => 'पीछे';

  @override
  String get joharLoading => 'जोहार... लोड हो रहा है...';

  @override
  String get somethingWentWrong => 'कुछ गलत हो गया!';

  @override
  String get offlineMode => 'ऑफ़लाइन मोड। सहेजा गया कंटेंट दिख रहा है।';

  @override
  String get offlineProgressCached => 'ऑफ़लाइन। प्रगति डिवाइस पर सहेजी गई।';

  @override
  String get syncingProgress => 'प्रगति सिंक हो रही है...';

  @override
  String get progressSynced => 'प्रगति सिंक हो गई!';

  @override
  String get failedToSyncProgress => 'प्रगति सिंक करने में विफल।';

  @override
  String get processing => 'प्रोसेस हो रहा है...';

  @override
  String get pleaseLogInToPurchase => 'कोर्स खरीदने के लिए कृपया लॉग इन करें।';

  @override
  String get creatingSecureOrder => 'सुरक्षित सर्वर ऑर्डर बनाया जा रहा है...';

  @override
  String get openingPaymentGateway => 'पेमेंट गेटवे खोला जा रहा है...';

  @override
  String get verifyingPayment => 'सर्वर से पेमेंट सत्यापित हो रहा है...';

  @override
  String get courseUnlocked => 'कोर्स सफलतापूर्वक अनलॉक हुआ!';

  @override
  String get failedToCreateOrder => 'पेमेंट ऑर्डर बनाने में विफल';

  @override
  String get paymentVerificationFailed => 'पेमेंट सत्यापन विफल';

  @override
  String checkoutUnexpectedError(String error) {
    return 'चेकआउट में अनपेक्षित त्रुटि: $error';
  }

  @override
  String unlockCourse(String amount) {
    return 'कोर्स अनलॉक करें (₹$amount)';
  }

  @override
  String get trustBadgeSecureCheckout =>
      'Razorpay द्वारा 256-bit एन्क्रिप्टेड चेकआउट • तुरंत एक्सेस';

  @override
  String get webMonetizationRestrictedTitle => 'वेब पर मॉनेटाइज़ेशन प्रतिबंधित';

  @override
  String get webMonetizationNotice =>
      'Razorpay चेकआउट और App Store समीक्षाएँ केवल Olitun मोबाइल ऐप पर समर्थित हैं। अनलॉक करने के लिए इसे Android/iOS पर खोलें।';

  @override
  String get aboutThisCourse => 'इस कोर्स के बारे में';

  @override
  String get courseOutcome => 'कोर्स परिणाम';

  @override
  String get premiumCourseBadge => 'प्रीमियम कोर्स';

  @override
  String get maranJauharTitle => 'मरन जोहार! 🎉';

  @override
  String get startLearning => 'सीखना शुरू करें';

  @override
  String get paywallValueOfflineTitle => 'पूरा ऑफ़लाइन पैक एक्सेस';

  @override
  String get paywallValueOfflineSubtitle =>
      'कभी भी ऑफ़लाइन सीखने के लिए पाठ, उच्चारण ऑडियो और क्विज़ डाउनलोड करें।';

  @override
  String get paywallValueAiTitle => 'असीमित AI अनुवाद';

  @override
  String get paywallValueAiSubtitle =>
      'बिना क्वेरी सीमा के तुरंत ओलचिकी अनुवाद और उच्चारण मार्गदर्शन।';

  @override
  String get paywallValueAdFreeTitle => 'शून्य विज्ञापन रुकावट';

  @override
  String get paywallValueAdFreeSubtitle =>
      'सभी मॉड्यूल में 100% बिना ध्यान भटकाने वाला भाषा अभ्यास।';

  @override
  String get paywallValueLifetimeTitle => 'आजीवन एक्सेस गारंटी';

  @override
  String get paywallValueLifetimeSubtitle =>
      'एक बार भुगतान — कोई आवर्ती शुल्क, सब्सक्रिप्शन या छिपा शुल्क नहीं।';

  @override
  String get navLearn => 'सीखें';

  @override
  String get navBakhed => 'बाखेड़';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String navTabSemantics(String label) {
    return '$label टैब';
  }

  @override
  String navItemSemantics(String label) {
    return '$label नेविगेशन आइटम';
  }

  @override
  String get kudosMistake1 =>
      'गलतियों की समीक्षा हुई। इसी तरह निपुणता बनती है।';

  @override
  String get kudosMistake2 =>
      'निपुणता बन रही है! आपने गलतियों को ज्ञान में बदल दिया।';

  @override
  String get kudosMistake3 =>
      'शानदार! गलतियाँ सुधारना ही धाराप्रवाहता का रहस्य है।';

  @override
  String get kudosMistake4 =>
      'शानदार समीक्षा! गलतियों को सुधारकर आप तेज़ी से सीख रहे हैं।';
}
