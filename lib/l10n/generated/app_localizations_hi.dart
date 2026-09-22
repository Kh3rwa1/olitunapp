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

  @override
  String get reviewToday => 'आज का रिव्यू';

  @override
  String get reviewLoading => 'आपका रिव्यू लोड हो रहा है…';

  @override
  String get reviewDueOne => '1 रिव्यू बाकी';

  @override
  String reviewDueOther(int count) {
    return '$count रिव्यू बाकी';
  }

  @override
  String reviewDueSubtitle(int minutes) {
    return '~$minutes मिनट · शुरू किए गए पाठों से';
  }

  @override
  String get reviewStart => 'रिव्यू शुरू करें';

  @override
  String get reviewCaughtUp => 'सब पूरा हो गया।';

  @override
  String reviewCaughtUpRetained(int count) {
    return 'अब तक $count आइटम याद हैं। याद रखना जारी रखें।';
  }

  @override
  String get reviewCaughtUpEmpty =>
      'नीचे कोई पाठ शुरू करें — जो सीखेंगे वह यहाँ रिव्यू में आएगा।';

  @override
  String get reviewContinueLearning => 'सीखना जारी रखें';

  @override
  String get reviewLearnNew => 'कुछ नया सीखें';

  @override
  String reviewRetained(int count) {
    return '$count याद रखा';
  }

  @override
  String get reviewExit => 'रिव्यू से बाहर निकलें';

  @override
  String reviewSessionTitle(int current, int total) {
    return 'आज का रिव्यू $current / $total';
  }

  @override
  String get reviewSessionTitleBare => 'आज का रिव्यू';

  @override
  String get reviewComplete => 'रिव्यू पूरा हुआ';

  @override
  String get reviewCorrectFeedback => 'सही — अच्छी याददाश्त।';

  @override
  String get reviewWrongFeedback => 'थोड़ा और — यह जल्द वापस आएगा।';

  @override
  String reviewCorrectAnswer(String answer) {
    return 'सही उत्तर: $answer';
  }

  @override
  String get reviewHintTyping => 'धीरे-धीरे हर ध्वनि लिखें।';

  @override
  String get reviewHintListening => 'फिर से सुनें — ध्वनि को अर्थ से मिलाएँ।';

  @override
  String get reviewHintRecognition => 'ओल चिकी अक्षरों से उच्चारण करें।';

  @override
  String get reviewRepromptListen => 'सुनें';

  @override
  String get reviewRepromptWrite => 'ओल चिकी में लिखें';

  @override
  String get reviewRepromptMeaning => 'इसका अर्थ क्या है?';

  @override
  String get reviewPlayAudio => 'ऑडियो चलाएँ';

  @override
  String get reviewReplayAudio => 'फिर से सुनें';

  @override
  String get reviewCheck => 'जाँचें';

  @override
  String get reviewFinish => 'रिव्यू समाप्त करें';

  @override
  String get reviewBackHome => 'होम पर वापस';

  @override
  String get reviewDone => 'हो गया';

  @override
  String get reviewCaughtUpShort =>
      'कुछ बाकी नहीं। लूप जारी रखने के लिए नीचे कुछ नया सीखें।';

  @override
  String reviewSummaryScore(int correct, int total, int accuracy) {
    return '$total में से $correct सही ($accuracy%)';
  }

  @override
  String reviewSummaryMastered(int mastered, int stars) {
    return '$mastered में महारत · +$stars स्टार';
  }

  @override
  String get reviewSummaryRecovery =>
      'छूटे हुए जल्द वापस आएंगे — यही सिस्टम का काम है, असफलता नहीं।';

  @override
  String get reviewLoadError => 'आपका रिव्यू लोड नहीं हो सका';

  @override
  String reviewLoadErrorBody(int count) {
    return 'आपके $count बाकी रिव्यू सुरक्षित हैं — पाठ सामग्री लोड नहीं हुई। कनेक्शन जाँचें और पुनः प्रयास करें।';
  }

  @override
  String get notifReviewTitleOne => '1 रिव्यू तैयार';

  @override
  String notifReviewTitleOther(int count) {
    return '$count रिव्यू तैयार';
  }

  @override
  String notifReviewBodyOne(int minutes) {
    return '1 आइटम रिव्यू के लिए तैयार है (~$minutes मिनट)। समय मिले तो आज का रिव्यू खोलें।';
  }

  @override
  String notifReviewBodyOther(int count, int minutes) {
    return '$count आइटम रिव्यू के लिए तैयार हैं (~$minutes मिनट)। समय मिले तो आज का रिव्यू खोलें।';
  }

  @override
  String get notifStruggleTitle => 'मुश्किल वाले वापस आ गए';

  @override
  String get notifStruggleBodyOne =>
      'जो शब्द मुश्किल लगा था, वह फिर बाकी है — एक बार दोहराने से पक्का होगा।';

  @override
  String notifStruggleBodyOther(int count) {
    return '$count मुश्किल शब्द फिर बाकी हैं — एक बार दोहराने से पक्के होंगे।';
  }

  @override
  String get notifGentleTitle => 'आपकी संताली प्रतीक्षा कर रही है';

  @override
  String get notifGentleBody =>
      'छोटा रिव्यू सीखा हुआ ताज़ा रखता है। कोई जल्दी नहीं।';

  @override
  String get santaliAiVoice => 'संताली एआई आवाज़';

  @override
  String get closeVoiceStudio => 'वॉइस स्टूडियो बंद करें';

  @override
  String get createVoiceAction => 'वॉइस बनाएं';

  @override
  String get creatingVoiceProgress => 'वॉइस बन रही है...';

  @override
  String get voiceStatusWorking => 'आपके शब्दों को संताली आवाज़ दी जा रही है…';

  @override
  String get voiceStatusIdle => 'टाइप करें। सुनें। शेयर करें।';

  @override
  String voiceStatusPlaying(String voice) {
    return 'बज रहा है • $voice';
  }

  @override
  String get voiceStatusReady => 'तैयार • प्ले करने के लिए टैप करें';

  @override
  String get voiceStatusOpenPlayer => 'वॉइस तैयार • नीचे प्लेयर खोलें';

  @override
  String get voiceCacheTip =>
      'सुझाव: पहले से तैयार क्लिप तुरंत और निःशुल्क चलते हैं — ये कैश से बजते हैं।';

  @override
  String get voiceDownloadFailed => 'डाउनलोड विफल रहा।';

  @override
  String get voiceInputHint =>
      'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ? — ओल चिकी में टाइप करें...';

  @override
  String get voicePlayerTab => 'प्लेयर';

  @override
  String get voiceCreatingBack => 'आपकी आवाज़ बनाई जा रही है…';

  @override
  String get voiceEmptyBack => 'आपकी आवाज़ यहाँ दिखाई देगी';

  @override
  String get voiceEditText => 'टेक्स्ट संपादित करें';

  @override
  String get voiceDismiss => 'हटाएं';

  @override
  String get voicePlaybackSpeed => 'प्लेबैक गति';

  @override
  String get voiceSaving => 'सहेजा जा रहा है…';

  @override
  String get voiceDownload => 'डाउनलोड';

  @override
  String get voiceRegenerate => 'फिर से बनाएं';

  @override
  String get voicePickerHeader => 'आवाज़  •  ᱟᱲᱟᱝ';

  @override
  String get voiceStyleHeader => 'शैली  •  ᱨᱚᱲ';

  @override
  String get voiceSignInUpper => 'साइन इन';

  @override
  String get voiceRetryUpper => 'पुनः प्रयास करें';

  @override
  String get aiStudioTitle => 'एआई स्टूडियो';

  @override
  String get aiStudioToolTranscribe => 'ट्रांसक्राइब';

  @override
  String get aiStudioToolTranslate => 'अनुवाद';

  @override
  String get aiStudioToolScan => 'स्कैन';

  @override
  String get aiStudioHeadline => 'पन्ने या आवाज़ से\nउपयोगी शब्दों में।';

  @override
  String get aiStudioSubhead =>
      'टेक्स्ट का अनुवाद करें, छोटी रिकॉर्डिंग ट्रांसक्राइब करें, या दस्तावेज़ स्कैन करें। आगे उपयोग से पहले परिणाम की समीक्षा करें।';

  @override
  String get aiStudioStep1 => '1  इनपुट जोड़ें';

  @override
  String get aiStudioStep2 => '2  सहमति के साथ प्रोसेस करें';

  @override
  String get aiStudioStep3 => '3  समीक्षा और उपयोग करें';

  @override
  String get aiStudioNotConfigured =>
      'इस संस्करण में एआई प्रोसेसिंग उपलब्ध नहीं है। आप यहाँ टेक्स्ट तैयार कर सकते हैं या नीचे निःशुल्क लिपि परिवर्तक का उपयोग कर सकते हैं।';

  @override
  String get aiStudioYourText => 'आपका टेक्स्ट';

  @override
  String get aiStudioYourAudio => 'आपका ऑडियो';

  @override
  String get aiStudioYourDocument => 'आपका दस्तावेज़';

  @override
  String get aiStudioSourceLanguage => 'स्रोत भाषा';

  @override
  String get aiStudioTranslateNote =>
      'संताली (ओल चिकी) में अनुवाद करें। अधिकतम 2,000 अक्षर।';

  @override
  String get aiStudioTextToTranslate => 'अनुवाद के लिए टेक्स्ट';

  @override
  String get aiStudioTextPlaceholder => 'अपना टेक्स्ट टाइप या पेस्ट करें';

  @override
  String get aiStudioTextLimitError => '2,000 या उससे कम अक्षरों का अंश चुनें।';

  @override
  String get aiStudioSpeakNote =>
      'सामान्य रूप से बोलें। रिकॉर्डिंग 30 सेकंड में अपने आप रुक जाएगी। आप इसके बजाय WAV फ़ाइल भी अपलोड कर सकते हैं।';

  @override
  String get aiStudioRecordVoice => 'वॉइस रिकॉर्ड करें';

  @override
  String aiStudioStopRecording(String seconds) {
    return 'रिकॉर्डिंग रोकें · $seconds से';
  }

  @override
  String get aiStudioListening =>
      'सुन रहे हैं… पूरा होने पर रिकॉर्डिंग रोकें पर टैप करें।';

  @override
  String get aiStudioOrExistingRecording =>
      'या किसी मौजूदा रिकॉर्डिंग का उपयोग करें';

  @override
  String get aiStudioUploadWav => 'WAV फ़ाइल अपलोड करें';

  @override
  String get aiStudioReplaceRecording => 'रिकॉर्डिंग बदलें';

  @override
  String get aiStudioOpening => 'खोल रहे हैं…';

  @override
  String get aiStudioDocNote =>
      'PDF, PNG या JPG · 10 MB और 10 पृष्ठों तक\nस्पष्ट और पढ़ने योग्य पन्ने का उपयोग करें।';

  @override
  String get aiStudioChooseFile => 'फ़ाइल चुनें';

  @override
  String get aiStudioReplaceFile => 'फ़ाइल बदलें';

  @override
  String get aiStudioCapturePage => 'पृष्ठ की फ़ोटो लें';

  @override
  String get aiStudioProcessing =>
      'प्रोसेसिंग जारी है… इस स्क्रीन को खुला रखें।';

  @override
  String aiStudioProcessWithAi(String tool) {
    return 'एआई के साथ $tool';
  }

  @override
  String get aiStudioReviewAndUse => 'समीक्षा और उपयोग';

  @override
  String get aiStudioResultPlaceholder => 'आपका परिणाम यहाँ दिखाई देगा।';

  @override
  String get aiStudioResultDisclaimer =>
      'कुछ भी प्रकाशित या साझा नहीं किया गया है। टेक्स्ट तैयार होने पर आप इसे सही कर सकते हैं, कॉपी कर सकते हैं या अगले कदम के लिए अंश चुन सकते हैं।';

  @override
  String get aiStudioReviewHelper =>
      'कॉपी या शेयर करने से पहले एआई टेक्स्ट की समीक्षा करें।';

  @override
  String get aiStudioCopy => 'कॉपी करें';

  @override
  String get aiStudioShare => 'शेयर करें';

  @override
  String get aiStudioCopyToShare => 'शेयर के लिए कॉपी करें';

  @override
  String get aiStudioTranslateResult => 'परिणाम का अनुवाद करें';

  @override
  String get aiStudioSendToVoiceStudio => 'वॉयस स्टूडियो';

  @override
  String get aiStudioAuto => 'ऑटो';

  @override
  String get aiStudioLive => 'लाइव';

  @override
  String get aiStudioThinking => 'सोच रहा है';

  @override
  String get aiStudioScanningLive =>
      'आपका पेज पढ़ा जा रहा है — अपडेट यहाँ लाइव दिखेंगे।';

  @override
  String get aiStudioLookingForConverter =>
      'क्या आप निःशुल्क लिपि परिवर्तक ढूंढ रहे हैं?';

  @override
  String get aiStudioDisclaimer =>
      'एআই परिणामों में त्रुटियाँ हो सकती हैं; उपयोग से पहले नाम, संख्या और वर्तनी की समीक्षा करें।';

  @override
  String aiStudioPassageNote(int limit) {
    return '$limit अक्षरों तक का अंश चुनें या संपादित करें। आपका मूल परिणाम अपरिवर्तित रहेगा।';
  }

  @override
  String get aiStudioPassageToSend => 'भेजने के लिए अंश';

  @override
  String get aiStudioPassageLimitError =>
      'आगे बढ़ने के लिए अंश को छोटा करें। कुछ भी काटा नहीं गया है।';

  @override
  String get aiStudioUploadPrompt =>
      'अपनी छवि अपलोड करें या कैमरे से स्कैन करें';

  @override
  String get aiStudioUploadFormats => 'PDF, PNG या JPG · अधिकतम 10 MB';

  @override
  String aiStudioJobId(String id) {
    return 'Job: $id';
  }

  @override
  String get aiStudioCheckStatus => 'स्थिति जाँचें';

  @override
  String get aiStudioReplaceWithScan => 'स्कैन से बदलें';

  @override
  String get aiStudioEditSource => 'स्रोत संपादित करें';

  @override
  String get olitun => 'Olitun';

  @override
  String get welcomeTagline => 'ओल चिकी लिपि सीखें';

  @override
  String errorLoadingContent(String error) {
    return 'Error loading content: $error';
  }

  @override
  String get startQuiz2 => 'क्विज़ शुरू करें';

  @override
  String get practiceTyping => 'टाइपिंग का अभ्यास करें';

  @override
  String mediaDuration(int seconds) {
    return 'Duration: ${seconds}s';
  }

  @override
  String get noLearningContent => 'अभी कोई सीखने की सामग्री उपलब्ध नहीं है।';

  @override
  String errorLoadingDetails(String error) {
    return 'Error loading details: $error';
  }

  @override
  String get culturalNotesPreparing => 'सांस्कृतिक नोट तैयार किए जा रहे हैं।';

  @override
  String culturalNoteSource(String source) {
    return 'Source: $source';
  }

  @override
  String get noVocabularyItems => 'कोई शब्दावली आइटम परिभाषित नहीं है।';

  @override
  String get lyricsBeingAdded => 'गीत जोड़े जा रहे हैं';

  @override
  String get bakhedLabel => 'BAKHED';

  @override
  String get wordLabel => 'शब्द';

  @override
  String get cancelLower => 'रद्द करें';

  @override
  String greetingDayPart(String part) {
    return 'ᱡᱚᱦᱟᱨ • $part';
  }

  @override
  String get homePickupSubtitle =>
      'जहाँ छोड़ा था वहीं से जारी रखें — छोटे कदम, हर दिन।';

  @override
  String get aiTranslatorTitle => 'AI Translator';

  @override
  String get voiceSpeakWithConfidence => 'आत्मविश्वास से बोलें';

  @override
  String get aiStudioPromoBadge => 'NEW • AI STUDIO';

  @override
  String get aiStudioPromoSubtitle => 'अपने सपनों की भाषा बनाएं।';

  @override
  String get learnMore => 'और जानें';

  @override
  String get instantTranslate => 'तुरंत अनुवाद';

  @override
  String get anyLanguageToOlChiki => 'किसी भी भाषा से ओल चिकी';

  @override
  String get aiBadge => 'AI';

  @override
  String get yourLearningPath => 'आपका सीखने का रास्ता';

  @override
  String stepOfPath(int step, int total) {
    return 'Step $step of $total: ';
  }

  @override
  String get learningPathSubtitle =>
      'आपके संताली स्तर के अनुरूप एक निर्देशित रास्ता।';

  @override
  String get santaliOlChikiLabel => 'संताली (ओल चिकी)';

  @override
  String get magicTranslatePrivacyNote =>
      'मैजिक ट्रांसलेट आपकी फ़ोटो ऑन-डिवाइस पर प्रोसेस करता है और आपकी गोपनीयता का सम्मान करता है।';

  @override
  String get close => 'बंद करें';

  @override
  String get aiVoicePromoBadge => 'NEW • AI VOICE';

  @override
  String get aiVoiceTitle => 'AI Voice';

  @override
  String get aiVoicePromoSubtitle => 'कुछ भी टाइप करें — संताली में सुनें।';

  @override
  String get tryNow => 'अभी आज़माएँ';

  @override
  String get k15Styles => 'ᱟᱲᱟᱝ • 15 styles';

  @override
  String get backToLearningPaths => 'सीखने के रास्तों पर वापस जाएँ';

  @override
  String get learningPathsHeader => 'सीखने के रास्ते';

  @override
  String get chooseYourJourney => 'अपनी यात्रा चुनें';

  @override
  String get morePaths => 'और रास्ते';

  @override
  String get plusTenXp => '+10 XP';

  @override
  String get strokeOrderHint => 'स्ट्रोक क्रम याद रखने का प्रयास करें';

  @override
  String traceAccuracy(String feedback, int percent) {
    return '$feedback  Accuracy: $percent%';
  }

  @override
  String get niceWork => 'बढ़िया!';

  @override
  String youScoredOutOf(int score, int total) {
    return 'You scored $score out of $total';
  }

  @override
  String percentFormat(int percent) {
    return '$percent%';
  }

  @override
  String get backLabel => 'वापस';

  @override
  String get quizKeyboardHint =>
      'तीर कुंजियों से नेविगेट करें  •  1-4 से चुनें  •  Enter ↵ से सबमिट करें';

  @override
  String scoreOnly(int score) {
    return '$score';
  }

  @override
  String get pressEnter => 'Enter ↵';

  @override
  String get readyToTestYourself =>
      'क्या आप खुद की परीक्षा लेने के लिए तैयार हैं?';

  @override
  String get takeTheQuiz => 'क्विज़ लें';

  @override
  String get skipForNow => 'अभी छोड़ें';

  @override
  String get browseView => 'ब्राउज़ दृश्य';

  @override
  String get openDictionary => 'शब्दकोश खोलें';

  @override
  String get learnLabel => 'सीखें';

  @override
  String get doneLabel => 'हो गया';

  @override
  String get lockedForNowTitle => 'रुकें • अभी के लिए लॉक';

  @override
  String completeBlockerFirst(String blocker) {
    return 'Complete “$blocker” first to crack it open.';
  }

  @override
  String get interactiveHtmlTitle => 'इंटरैक्टिव पाठ अनुभव';

  @override
  String get interactiveHtmlBody =>
      'यह पाठ इंटरैक्टिव सामग्री के साथ आता है। देखने के लिए नीचे स्क्रॉल करें।';

  @override
  String get openInteractiveContent => 'इंटरैक्टिव सामग्री खोलें';

  @override
  String get recommendedLabel => 'अनुशंसित';

  @override
  String get audioPlaybackHint => 'ऑडियो चलाने के लिए टैप करें';

  @override
  String get finishReviewing => 'समीक्षा समाप्त करें';

  @override
  String get takeQuizNow => 'अभी क्विज़ लें';

  @override
  String stepOfTotal(int step, int total) {
    return 'STEP $step OF $total';
  }

  @override
  String get checkConnectionPeriod =>
      'अपना कनेक्शन जाँचें और पुनः प्रयास करें।';

  @override
  String sentencePronunciation(String pronunciation) {
    return 'Pronunciation: $pronunciation';
  }

  @override
  String get santaliLearner => 'संताली सीखने वाला';

  @override
  String get streakTip => 'स्ट्रीक बनाए रखने के लिए रोज़ 3 पाठ पूरे करें।';

  @override
  String get continueLearningArrow => 'सीखना जारी रखें →';

  @override
  String get olitun2 => 'Olitun';

  @override
  String get santaliOlChikiTag => 'SANTALI • OL CHIKI';

  @override
  String get menuLabel => 'मेनू';

  @override
  String get olitunPwaVersion => 'Olitun PWA • v2.4';

  @override
  String onboardingCounter(String current, String total) {
    return '$current · $total';
  }

  @override
  String get goalsTitle => 'लक्ष्य';

  @override
  String get goalsSubtitle => 'अपने सीखने से पहले लक्ष्य निर्धारित करें।';

  @override
  String get requiredLabel => 'आवश्यक';

  @override
  String get stepOneOfFive => 'चरण 5 में से 1';

  @override
  String get languageSubtitle => 'भाषा चुनें और अपनी प्राथमिकता बदलें';

  @override
  String get prefsSaveFailed =>
      'आपकी सेटिंग सहेजी नहीं जा सकी। कृपया पुनः प्रयास करें।';

  @override
  String get selectMotherTongueToast =>
      'जारी रखने के लिए कृपया अपनी मातृभाषा / शिक्षण भाषा चुनें।';

  @override
  String get onboardingHeadline => 'ओल चिकी सीखें,\nएक कदम समय पर';

  @override
  String get familiarityTitle => 'परिचिति स्तर';

  @override
  String get familiaritySubtitle =>
      'अपनी परिचिति के आधार पर अपने सीखने का अनुकूलन करें।';

  @override
  String get displayTitle => 'आप सामग्री कैसे देखना चाहते हैं?';

  @override
  String get displaySubtitle =>
      'अपनी पसंदीदा लिपि प्रदर्शन चुनें। आप इसे कभी भी बदल सकते हैं।';

  @override
  String get practiceGoalTitle => 'अभ्यास लक्ष्य';

  @override
  String get practiceGoalSubtitle =>
      'अभ्यास लक्ष्य निर्धारित करें — सीखने में अपने स्ट्रीक को बनाए रखने के लिए प्रतिदिन कितने पाठ पूरे करने हैं।';

  @override
  String get olitunWordmark => 'OLITUN';

  @override
  String get learnOlChiki => 'ओल चिकी सीखें';

  @override
  String get spaceKey => 'SPACE';

  @override
  String get practicedSuccessfully => 'सफलतापूर्वक अभ्यास किया';

  @override
  String get revealAndContinue => 'दिखाएँ और जारी रखें';

  @override
  String get systemDiagnosticsTitle => 'सिस्टम डायग्नोस्टिक्स और रनटाइम';

  @override
  String get systemDiagnosticsSubtitle =>
      'गुमनाम रनटाइम प्रदर्शन और डायग्नोस्टिक टेलीमेट्री';

  @override
  String get diagnosticPayloadPreview => 'डायग्नोस्टिक पेलोड पूर्वावलोकन';

  @override
  String get diagnosticPayloadCopied =>
      'डायग्नोस्टिक पेलोड क्लिपबोर्ड पर कॉपी हो गया!';

  @override
  String get diagnosticsTileSubtitle =>
      'रनटाइम डेटा, मेमोरी उपयोग और क्रैश डायग्नोस्टिक्स देखें';

  @override
  String get deleteAllDownloadsTitle => 'सभी डाउनलोड हटाएँ?';

  @override
  String get deleteAllDownloadsBody =>
      'यह इस डिवाइस से हर ऑफ़लाइन कहानी ऑडियो क्लिप हटाता है। कहानियाँ फिर स्ट्रीम होंगी जब आप उन्हें खोलेंगे।';

  @override
  String get editYourName => 'अपना नाम संपादित करें';

  @override
  String get save => 'सहेजें';

  @override
  String get indigenousLanguagesTitle => 'स्वदेशी भाषा मंच';

  @override
  String get indigenousLanguagesSubtitle =>
      'पूर्वी भारत की स्वदेशी लिपियों और जनजातीय भाषाओं का अन्वेषण करें';

  @override
  String packsComingSoon(String name) {
    return '$name content & audio packs are coming soon!';
  }

  @override
  String learningLanguageSetTo(String name, String script) {
    return 'Learning language set to $name ($script)';
  }

  @override
  String get audioPack => 'ऑडियो पैक';

  @override
  String get offlineLessons => 'ऑफ़लाइन पाठ';

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
  String get masteryProgression => 'महारत प्रगति';

  @override
  String get nextMilestone => 'अगला मील का पत्थर';

  @override
  String roadToLevel(String level) {
    return 'Road to $level';
  }

  @override
  String badgeUnlockHint(String name, String target) {
    return 'To unlock the $name badge: $target';
  }

  @override
  String get closestBadge => 'निकटतम बैज उपलब्धि';

  @override
  String unlockBadge(String name) {
    return 'Unlock the $name Badge';
  }

  @override
  String get reminderFrequency => 'रिमाइंडर आवृत्ति';

  @override
  String get reminderFrequencySubtitle =>
      'ओल चिकी का अभ्यास करने के लिए कितनी बार रिमाइंडर चाहिए, चुनें।';

  @override
  String get dailySchedulePreview => 'दैनिक कार्यक्रम पूर्वावलोकन';

  @override
  String get sendTestNotification => 'परीक्षण अधिसूचना भेजें';

  @override
  String get chooseYourAvatarLower => 'अपना अवतार चुनें';

  @override
  String get avatarAnimationsFailed => 'अवतार एनिमेशन लोड नहीं हो सके।';

  @override
  String get tryAgainLower => 'पुनः प्रयास करें';

  @override
  String get avatarSaveFailed =>
      'अवतार सहेजा नहीं जा सका। कृपया पुनः प्रयास करें।';

  @override
  String since(String date) {
    return 'Since $date';
  }

  @override
  String get overallProgress => 'कुल प्रगति';

  @override
  String get noBookingsFound => 'कोई बुकिंग नहीं मिली';

  @override
  String get bookingsEmptyHint =>
      'बखेद टैब के तहत अपने समारोहों के लिए सत्यापित वाचक बुक करें।';

  @override
  String get waitlistBookingsFailed =>
      'प्रतीक्षा सूची बुकिंग लोड नहीं हो सकीं।';

  @override
  String get assessmentScore => 'मूल्यांकन स्कोर';

  @override
  String get avgLabel => 'औसत';

  @override
  String get adPrivacyRegionNote =>
      'आपके क्षेत्र के लिए विज्ञापन गोपनीयता सेटिंग्स आवश्यक नहीं हैं।';

  @override
  String get signOutConfirmBody =>
      'क्या आप वाकई इस डिवाइस पर अपने खाते से साइन आउट करना चाहते हैं?';

  @override
  String get learningLanguageScript => 'सीखने की भाषा और लिपि';

  @override
  String get mistakeReview => 'गलती समीक्षा';

  @override
  String get allCaughtUp => 'सब हो गया!';

  @override
  String get noMistakesToReview =>
      'कोई गलती समीक्षा की आवश्यकता नहीं। आपकी संताली जड़ें मज़बूत हैं!';

  @override
  String get mistakesMastered => 'गलतियाँ महारत हासिल!';

  @override
  String get moreQuizzes => 'और क्विज़';

  @override
  String get challengeYourself => 'खुद को चुनौती दें';

  @override
  String get chooseAQuiz => 'क्विज़ चुनें';

  @override
  String get noQuizzesYet => 'अभी तक कोई क्विज़ नहीं!';

  @override
  String get completeLessonsFirst => 'पहले कुछ पाठ पूरे करें';

  @override
  String get quizUnavailable => 'क्विज़ अनुपलब्ध';

  @override
  String get quizUnavailableDetail =>
      'क्विज़ अनुपलब्ध — इस पाठ में क्विज़ के लिए पर्याप्त प्रश्न नहीं हैं।';

  @override
  String get quizLoadFailed => 'क्विज़ लोड नहीं हो सकी।';

  @override
  String translation(String text) {
    return 'Translation: \"$text\"';
  }

  @override
  String get audioNotAvailable => 'इस प्रश्न के लिए ऑडियो उपलब्ध नहीं है।';

  @override
  String get mistakeReviewBadge => 'गलती समीक्षा';

  @override
  String get takesTwoMin => '2 मिनट लगते हैं';

  @override
  String get mistakesQuote =>
      '“गलतियाँ सीखने का एक हिस्सा हैं — उन्हें दोहराने से बचें।”';

  @override
  String get quizKeyboardHintAlt =>
      '↑ / ↓ नेविगेट  •  1-4 चुनें  •  Enter ↵ सबमिट';

  @override
  String get watchAdBonusStars => '+50 बोनस स्टार के लिए विज्ञापन देखें';

  @override
  String get shareAchievement => 'उपलब्धि साझा करें';

  @override
  String get bonusStarsEarned => '50 बोनस स्टार अर्जित! ⭐';

  @override
  String get rewardedAdCooldown =>
      'रिवॉर्डेड विज्ञापन ठंडा हो रहा है। बाद में पुनः प्रयास करें।';

  @override
  String get scoreLabel => 'स्कोर';

  @override
  String get accuracyLabel => 'सटीकता';

  @override
  String get starsEarned => 'अर्जित स्टार';

  @override
  String get maxCombo => 'अधिकतम कॉम्बो';

  @override
  String get reviewMistakes => 'गलतियों की समीक्षा करें';

  @override
  String get reviewMistakesSubtitle =>
      'अपनी महारत बनाने के लिए गलत उत्तरों की समीक्षा करें! लहा से!';

  @override
  String get correctColon => 'सही उत्तर:';

  @override
  String get correctAnswerColon => 'सही उत्तर:';

  @override
  String get insightGuidance => 'अंतर्दृष्टि और मार्गदर्शन:';

  @override
  String get selectMissingWord => 'गायब शब्द चुनें:';

  @override
  String questionsWithLevel(int count, String level) {
    return '$count questions • $level';
  }

  @override
  String get startQuiz => 'क्विज़ शुरू करें';

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String get outOfHearts => 'दिल समाप्त!';

  @override
  String outOfHeartsSummary(int score, int total, int stars) {
    return 'आपने $score/$total सही उत्तर दिए और अब तक $stars स्टार अर्जित किए। अभ्यास जारी रखें।';
  }

  @override
  String get watchAdRefillHearts => 'दिल भरने के लिए विज्ञापन देखें (मुफ़्त)';

  @override
  String get backToQuizzes => 'क्विज़ पर वापस जाएँ';

  @override
  String get heartsRefilled => 'दिल भर गए! ❤️❤️❤️';

  @override
  String get rewardedAdCooldownReset =>
      'रिवॉर्डेड विज्ञापन ठंडा हो रहा है। कृपया नियमित रीसेट आज़माएँ।';

  @override
  String currentOfTotal(int current, int total) {
    return '$current/$total';
  }

  @override
  String get rhymesEndNote => 'यहाँ बस इतना ही — नई बखेद जल्द आ रही हैं!';

  @override
  String get rhymesLoadFailed => 'लोरी लोड नहीं हो सकी।';

  @override
  String get bakhedPreparing => 'बखेद तैयार किए जा रहे हैं';

  @override
  String get bakhedPreparingSubtitle =>
      'प्रकाशन के बाद नई श्रव्य कहानियाँ यहाँ दिखाई देंगी।';

  @override
  String failedToJoinWaitlist(String error) {
    return 'Failed to join waitlist: $error';
  }

  @override
  String get waitlistJoined => 'प्रतीक्षा सूची में शामिल हो गए! 🎉';

  @override
  String get waitlistJoinedBody =>
      'आप सूची में शामिल हो गए हैं! उपलब्ध होते ही हम आपको सूचित करेंगे।';

  @override
  String get great => 'बढ़िया';

  @override
  String get joinBintiGuruWaitlist => 'बिंदी गुरु प्रतीक्षा सूची में शामिल हों';

  @override
  String get bintiGuruFormSubtitle =>
      'अपने समारोह के बारे में बताएँ। हम उपलब्ध प्रमाणित वाचक खोजेंगे।';

  @override
  String get submitWaitlistEntry => 'प्रविष्टि सबमिट करें';

  @override
  String get bookVerifiedBintiGuru => 'सत्यापित बिंदी गुरु बुक करें';

  @override
  String get bintiGuruLandingBody =>
      'बिंदी संताली वाचन का पवित्र कर्म है। चाहे करम, सोहराई, बहा, विवाह, श्राद्ध या किसी अन्य अवसर के लिए — प्रमाणित वाचक खोजें।';

  @override
  String get joinWaitlistNow => 'अभी प्रतीक्षा सूची में शामिल हों';

  @override
  String get howItWorks => 'यह कैसे काम करता है';

  @override
  String get newBadge => 'नया';

  @override
  String get ctrlEnterCreate => 'Ctrl+Enter ↵ to create';

  @override
  String charCount(int current, int max) {
    return '$current / $max';
  }

  @override
  String get svgLoadFailed => 'SVG एनिमेशन लोड नहीं हो सका';

  @override
  String get signIn => 'साइन इन';

  @override
  String get shareCardTagline => 'OLITUN • ᱚᱞ ᱪᱤᱠᱤ';

  @override
  String get shareCardFooter => 'Learn Santali (Ol Chiki) • olitun.app';

  @override
  String get shareTextCopied =>
      'साझा करने का टेक्स्ट क्लिपबोर्ड पर कॉपी हो गया है। 📋';

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
      'अक्षरों से शुरू करें, शब्द बनाएँ, क्विज़ से अभ्यास करें, और अपनी संताली सीखने की यात्रा जारी रखें।';

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
  String get continueWithEmail => 'ईमेल के साथ जारी रखें';

  @override
  String get exploreAsGuest => 'अतिथि के रूप में देखें';

  @override
  String get continueWithGoogle => 'Google के साथ जारी रखें';

  @override
  String get guestSessionFailed =>
      'अतिथि सत्र शुरू नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get couldNotLoadLessons => 'पाठ लोड नहीं हो सके';

  @override
  String get shareMessageCopied => 'शेयर संदेश क्लिपबोर्ड पर कॉपी हो गया! 📋';

  @override
  String get shareMilestoneTitle => 'अपनी उपलब्धि साझा करें';

  @override
  String get shareMilestoneSubtitle =>
      'संताली और ओल चिकी सीखने के लिए दूसरों को प्रेरित करें';

  @override
  String get copyTextSummary => 'टेक्स्ट सारांश कॉपी करें';

  @override
  String get traceGuidelines => 'अक्षर दिशानिर्देशों को सटीकता से ट्रेस करें';

  @override
  String get showExample => 'उदाहरण दिखाएं';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get finishLesson => 'पाठ समाप्त करें';

  @override
  String get couldNotOpenShareSheet => 'शेयर शीट खोल नहीं सके';

  @override
  String get couldNotClearDownloads => 'डाउनलोड साफ़ नहीं हो सके';

  @override
  String get progressLoadFailed =>
      'आपकी सहेजी गई प्रगति अभी भी सुरक्षित है। कृपया इस दृश्य को रीफ्रेश करें।';

  @override
  String get couldNotLoadProgress => 'प्रगति लोड नहीं हो सकी';

  @override
  String get couldNotLoadQuizzes => 'क्विज़ लोड नहीं हो सके';

  @override
  String get contentLoadFailed =>
      'सामग्री लोड नहीं हो सकी। कृपया पुनः प्रयास करें।';
}
