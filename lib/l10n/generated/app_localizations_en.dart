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

  @override
  String get streakActiveTitle => 'Weekly Streak Active';

  @override
  String get streakIdleTitle => 'Start Your Streak';

  @override
  String get streakActiveSubtitle => 'Keep learning to grow your flame!';

  @override
  String get streakIdleSubtitle => 'Complete any activity to light your flame!';

  @override
  String get streakStartLearning => 'Start learning';

  @override
  String streakDaysBadge(int count) {
    return '$count DAYS';
  }

  @override
  String streakFooterActive(int count, int total) {
    return 'You practiced $count of $total days this week. Keep it up!';
  }

  @override
  String get streakFooterIdle =>
      'No practice yet this week — pick any activity to begin!';

  @override
  String streakWeekSemantics(int count, int total) {
    return 'This week: practiced $count of $total days';
  }

  @override
  String get dayDetailNoActivity => 'No activity recorded';

  @override
  String get dayDetailPracticeSession => 'Practice session';

  @override
  String get dayDetailStreakDay => 'Streak day';

  @override
  String get dayDetailQuiz => 'Quiz';

  @override
  String get dayUpcoming => 'upcoming';

  @override
  String get dayPracticed => 'practiced';

  @override
  String get dayNotPracticed => 'not practiced';

  @override
  String milestoneLevelProgressCaption(String from, String to) {
    return 'Level progress · $from → $to';
  }

  @override
  String get homeDiscover => 'DISCOVER';

  @override
  String get homeSwipeHint => 'SWIPE';

  @override
  String get homeExploreHint => 'EXPLORE';

  @override
  String get guestSignInCta => 'Sign in to save your progress';

  @override
  String get nbaBadgeStartHere => 'START HERE';

  @override
  String get nbaTitleFirstLetters => 'Learn your first Ol Chiki letters';

  @override
  String get nbaSubFirstLetters =>
      'Begin with the basic alphabet and unlock Santali writing.';

  @override
  String get nbaCtaBeginLesson => 'Begin Lesson';

  @override
  String get nbaBadgeNextStep => 'NEXT STEP';

  @override
  String get nbaTitleNumbers => 'Practice Santali numbers';

  @override
  String get nbaSubNumbers =>
      'Build confidence with everyday counting and number words.';

  @override
  String get nbaCtaPracticeNumbers => 'Practice Numbers';

  @override
  String get nbaBadgeMistakes => 'PRACTICE NEEDED';

  @override
  String get nbaTitleMistakes => 'Transform mistakes into wisdom';

  @override
  String nbaSubMistakes(int count) {
    return 'You have $count question(s) to review and master.';
  }

  @override
  String get nbaCtaReviewMistakes => 'Review Mistakes';

  @override
  String get nbaBadgeStreakRisk => 'STREAK RISK';

  @override
  String get nbaTitleStreakRisk => 'Keep your daily momentum';

  @override
  String nbaSubStreakRisk(int count) {
    return 'One quick quiz or lesson will secure your $count day streak today.';
  }

  @override
  String get nbaCtaQuickReview => 'Quick Review';

  @override
  String get nbaBadgeTryBakhed => 'TRY BAKHED';

  @override
  String get nbaTitleTryBakhed => 'Listen to a cultural rhyme';

  @override
  String get nbaSubTryBakhed =>
      'Immerse yourself in beautiful Santali oral poetry for 30s.';

  @override
  String get nbaCtaListenNow => 'Listen Now';

  @override
  String get nbaBadgeAllDone => 'ALL COMPLETE';

  @override
  String get nbaTitleAllDone => 'You finished everything — brilliant!';

  @override
  String get nbaSubAllDone =>
      'New lessons are on the way. Revisit Bakhed or review anytime.';

  @override
  String get nbaCtaExploreBakhed => 'Explore Bakhed';

  @override
  String get affirmationListen => 'Listen';

  @override
  String get affirmationStop => 'Stop';

  @override
  String get affirmationMarkRead => 'Mark Read';

  @override
  String get affirmationRead => 'Read';

  @override
  String get hindi => 'Hindi';

  @override
  String get bengali => 'Bengali';

  @override
  String get odia => 'Odia';

  @override
  String get teachingLanguage => 'Teaching Language';

  @override
  String get teachingLanguageSubtitle => 'Used for meanings and explanations';

  @override
  String get lessonAudioMode => 'Lesson Audio';

  @override
  String get lessonAudioModeSubtitle =>
      'Choose how Santali and translation audio play';

  @override
  String get onboardingStepLanguageTitle =>
      'Which language do you understand best?';

  @override
  String get onboardingStepProficiencyTitle => 'How much Santali do you know?';

  @override
  String get onboardingStepGoalsTitle => 'What do you want to achieve?';

  @override
  String get onboardingStepGoalsSubtitle =>
      'Pick one or more — we\'ll personalize your path.';

  @override
  String get onboardingStepAudioTitle => 'How should lesson audio play?';

  @override
  String get onboardingStepReadyTitle => 'You\'re almost ready!';

  @override
  String get proficiencyNone => 'I don\'t know Santali';

  @override
  String get proficiencyUnderstandsSome => 'I understand some Santali';

  @override
  String get proficiencyFluentSpeaker => 'I speak Santali';

  @override
  String get proficiencyBeginnerReader => 'I can read a little Ol Chiki';

  @override
  String get proficiencyFluentReader => 'I already read Ol Chiki';

  @override
  String get goalSpeakSantali => 'Speak Santali';

  @override
  String get goalUnderstandSantali => 'Understand Santali';

  @override
  String get goalReadOlChiki => 'Read Ol Chiki';

  @override
  String get goalWriteOlChiki => 'Write Ol Chiki';

  @override
  String get goalLearnEverything => 'Learn everything';

  @override
  String get goalHelpMyChild => 'Help my child learn';

  @override
  String get goalPrepareExam => 'Prepare for school or an exam';

  @override
  String get audioModeTargetOnly => 'Santali only';

  @override
  String get audioModeBilingual => 'Santali, then my language';

  @override
  String get audioModeTranslationOnDemand =>
      'Play translation only when I tap it';

  @override
  String get dailyGoalLabel => 'Daily goal';

  @override
  String minutesPerDay(int minutes) {
    return '$minutes min/day';
  }

  @override
  String get downloadStarterAudio => 'Download starter audio';

  @override
  String get downloadStarterAudioSubtitle => 'Learn offline from day one';

  @override
  String get backButton => 'Back';

  @override
  String get joharLoading => 'Johar... Loading';

  @override
  String get somethingWentWrong => 'Something went wrong!';

  @override
  String get offlineMode => 'Offline mode. Showing cached content.';

  @override
  String get offlineProgressCached => 'Offline. Progress cached locally.';

  @override
  String get syncingProgress => 'Syncing progress...';

  @override
  String get progressSynced => 'Progress synced!';

  @override
  String get failedToSyncProgress => 'Failed to sync progress.';

  @override
  String get processing => 'Processing...';

  @override
  String get pleaseLogInToPurchase => 'Please log in to purchase courses.';

  @override
  String get creatingSecureOrder => 'Creating secure server order...';

  @override
  String get openingPaymentGateway => 'Opening payment gateway...';

  @override
  String get verifyingPayment => 'Verifying payment with server...';

  @override
  String get courseUnlocked => 'Course successfully unlocked!';

  @override
  String get failedToCreateOrder => 'Failed to create payment order';

  @override
  String get paymentVerificationFailed => 'Payment verification failed';

  @override
  String checkoutUnexpectedError(String error) {
    return 'Checkout encountered an unexpected error: $error';
  }

  @override
  String unlockCourse(String amount) {
    return 'Unlock Course (₹$amount)';
  }

  @override
  String get trustBadgeSecureCheckout =>
      '256-bit encrypted checkout via Razorpay • Instant access';

  @override
  String get webMonetizationRestrictedTitle => 'Monetization restricted on Web';

  @override
  String get webMonetizationNotice =>
      'Razorpay checkouts and App Store reviews are only supported on the Olitun Mobile Application. Please load this on Android/iOS to unlock.';

  @override
  String get aboutThisCourse => 'About this course';

  @override
  String get courseOutcome => 'Course Outcome';

  @override
  String get premiumCourseBadge => 'PREMIUM COURSE';

  @override
  String get maranJauharTitle => 'Maran Jauhar! 🎉';

  @override
  String get startLearning => 'Start Learning';

  @override
  String get paywallValueOfflineTitle => 'Full Offline Pack Access';

  @override
  String get paywallValueOfflineSubtitle =>
      'Download lessons, audio pronunciations, and quizzes for anytime offline learning.';

  @override
  String get paywallValueAiTitle => 'Unlimited AI Translations';

  @override
  String get paywallValueAiSubtitle =>
      'Instant Ol Chiki translations and pronunciation guides without query limits.';

  @override
  String get paywallValueAdFreeTitle => 'Zero Ad Interruptions';

  @override
  String get paywallValueAdFreeSubtitle =>
      'Experience 100% distraction-free language practice across all modules.';

  @override
  String get paywallValueLifetimeTitle => 'Lifetime Access Guarantee';

  @override
  String get paywallValueLifetimeSubtitle =>
      'Pay once with no recurring fees, subscriptions, or hidden charges.';

  @override
  String get navLearn => 'Learn';

  @override
  String get navBakhed => 'Bakhed';

  @override
  String get navProfile => 'Profile';

  @override
  String navTabSemantics(String label) {
    return '$label tab';
  }

  @override
  String navItemSemantics(String label) {
    return '$label navigation item';
  }

  @override
  String get kudosMistake1 =>
      'Mistakes reviewed. That\'s how mastery is built.';

  @override
  String get kudosMistake2 =>
      'Mastery in progress! You transformed mistakes into wisdom.';

  @override
  String get kudosMistake3 =>
      'Fantastic! Correcting mistakes is the secret to fluency.';

  @override
  String get kudosMistake4 =>
      'Brilliant review! You are learning faster by refining errors.';

  @override
  String get reviewToday => 'TODAY\'S REVIEW';

  @override
  String get reviewLoading => 'Loading your review…';

  @override
  String get reviewDueOne => '1 review due';

  @override
  String reviewDueOther(int count) {
    return '$count reviews due';
  }

  @override
  String reviewDueSubtitle(int minutes) {
    return '~$minutes min · from lessons you already started';
  }

  @override
  String get reviewStart => 'Start review';

  @override
  String get reviewCaughtUp => 'You\'re caught up.';

  @override
  String reviewCaughtUpRetained(int count) {
    return '$count items retained so far. Keep remembering.';
  }

  @override
  String get reviewCaughtUpEmpty =>
      'Start a lesson below — what you learn will show up here for review.';

  @override
  String get reviewContinueLearning => 'Continue learning';

  @override
  String get reviewLearnNew => 'Learn something new';

  @override
  String reviewRetained(int count) {
    return '$count retained';
  }

  @override
  String get reviewExit => 'Exit review';

  @override
  String reviewSessionTitle(int current, int total) {
    return 'Today\'s Review $current of $total';
  }

  @override
  String get reviewSessionTitleBare => 'Today\'s Review';

  @override
  String get reviewComplete => 'Review complete';

  @override
  String get reviewCorrectFeedback => 'Correct — nice recall.';

  @override
  String get reviewWrongFeedback => 'Not quite — this one comes back sooner.';

  @override
  String reviewCorrectAnswer(String answer) {
    return 'Correct answer: $answer';
  }

  @override
  String get reviewHintTyping => 'Type each sound, slowly.';

  @override
  String get reviewHintListening =>
      'Listen again — match the sound to the meaning.';

  @override
  String get reviewHintRecognition => 'Sound it out from the Ol Chiki letters.';

  @override
  String get reviewRepromptListen => 'LISTEN';

  @override
  String get reviewRepromptWrite => 'WRITE IN OL CHIKI';

  @override
  String get reviewRepromptMeaning => 'WHAT DOES THIS MEAN?';

  @override
  String get reviewPlayAudio => 'Play audio';

  @override
  String get reviewReplayAudio => 'Replay audio';

  @override
  String get reviewCheck => 'Check';

  @override
  String get reviewFinish => 'Finish review';

  @override
  String get reviewBackHome => 'Back to Home';

  @override
  String get reviewDone => 'Done';

  @override
  String get reviewCaughtUpShort =>
      'Nothing due. Learn something new below to keep the loop going.';

  @override
  String reviewSummaryScore(int correct, int total, int accuracy) {
    return '$correct of $total correct ($accuracy%)';
  }

  @override
  String reviewSummaryMastered(int mastered, int stars) {
    return '$mastered mastered · +$stars stars';
  }

  @override
  String get reviewSummaryRecovery =>
      'Missed items come back sooner — that is the system working, not failing.';

  @override
  String get reviewLoadError => 'Couldn\'t load your review';

  @override
  String reviewLoadErrorBody(int count) {
    return 'Your $count due reviews are safe — the lesson content just didn\'t load. Check your connection and retry.';
  }

  @override
  String get notifReviewTitleOne => '1 review ready';

  @override
  String notifReviewTitleOther(int count) {
    return '$count reviews ready';
  }

  @override
  String notifReviewBodyOne(int minutes) {
    return '1 item is ready for review (~$minutes min). Open Today\'s Review when you have a moment.';
  }

  @override
  String notifReviewBodyOther(int count, int minutes) {
    return '$count items are ready for review (~$minutes min). Open Today\'s Review when you have a moment.';
  }

  @override
  String get notifStruggleTitle => 'Tricky ones are back';

  @override
  String get notifStruggleBodyOne =>
      'A word you found tricky is due again — a quick retry locks it in.';

  @override
  String notifStruggleBodyOther(int count) {
    return '$count words you found tricky are due again — a quick retry locks them in.';
  }

  @override
  String get notifGentleTitle => 'Your Santali is waiting';

  @override
  String get notifGentleBody =>
      'A short review keeps what you learned fresh. No rush.';

  @override
  String get santaliAiVoice => 'Santali AI Voice';

  @override
  String get closeVoiceStudio => 'Close voice studio';

  @override
  String get createVoiceAction => 'CREATE VOICE';

  @override
  String get creatingVoiceProgress => 'CREATING VOICE...';

  @override
  String get voiceStatusWorking => 'Giving your words a Santali voice…';

  @override
  String get voiceStatusIdle => 'Type it. Hear it. Share it.';

  @override
  String voiceStatusPlaying(String voice) {
    return 'Playing • $voice';
  }

  @override
  String get voiceStatusReady => 'Ready • tap play';

  @override
  String get voiceStatusOpenPlayer => 'Voice ready • open player below';

  @override
  String get voiceCacheTip =>
      'Tip: repeat clips are instant and free — they replay from cache.';

  @override
  String get voiceDownloadFailed => 'Download failed.';

  @override
  String get voiceInputHint => 'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ? — type in Ol Chiki...';

  @override
  String get voicePlayerTab => 'PLAYER';

  @override
  String get voiceCreatingBack => 'Creating your voice…';

  @override
  String get voiceEmptyBack => 'Your voice will appear here';

  @override
  String get voiceEditText => 'Edit text';

  @override
  String get voiceDismiss => 'Dismiss';

  @override
  String get voicePlaybackSpeed => 'Playback speed';

  @override
  String get voiceSaving => 'SAVING…';

  @override
  String get voiceDownload => 'DOWNLOAD';

  @override
  String get voiceRegenerate => 'REGENERATE';

  @override
  String get voicePickerHeader => 'VOICE  •  ᱟᱲᱟᱝ';

  @override
  String get voiceStyleHeader => 'STYLE  •  ᱨᱚᱲ';

  @override
  String get voiceSignInUpper => 'SIGN IN';

  @override
  String get voiceRetryUpper => 'RETRY';

  @override
  String get aiStudioTitle => 'AI Studio';

  @override
  String get aiStudioToolTranscribe => 'Transcribe';

  @override
  String get aiStudioToolTranslate => 'Translate';

  @override
  String get aiStudioToolScan => 'Scan';

  @override
  String get aiStudioHeadline =>
      'From a page or a voice\nto words you can use.';

  @override
  String get aiStudioSubhead =>
      'Translate text, transcribe a short recording, or scan a document. Review the result before taking it anywhere.';

  @override
  String get aiStudioStep1 => '1  Add input';

  @override
  String get aiStudioStep2 => '2  Process with consent';

  @override
  String get aiStudioStep3 => '3  Review & use';

  @override
  String get aiStudioNotConfigured =>
      'AI processing is not available in this build. You can prepare text here or use the free script converter below.';

  @override
  String get aiStudioYourText => 'Your text';

  @override
  String get aiStudioYourAudio => 'Your audio';

  @override
  String get aiStudioYourDocument => 'Your document';

  @override
  String get aiStudioSourceLanguage => 'Source language';

  @override
  String get aiStudioTranslateNote =>
      'Translate into Santali (Ol Chiki). Up to 2,000 characters.';

  @override
  String get aiStudioTextToTranslate => 'Text to translate';

  @override
  String get aiStudioTextPlaceholder => 'Type or paste your text';

  @override
  String get aiStudioTextLimitError =>
      'Choose a passage of 2,000 characters or fewer.';

  @override
  String get aiStudioSpeakNote =>
      'Speak normally. Recording stops automatically at 30 seconds. You can also upload a WAV file instead.';

  @override
  String get aiStudioRecordVoice => 'Record voice';

  @override
  String aiStudioStopRecording(String seconds) {
    return 'Stop recording · ${seconds}s';
  }

  @override
  String get aiStudioListening =>
      'Listening… Tap Stop recording when you are done.';

  @override
  String get aiStudioOrExistingRecording => 'Or use an existing recording';

  @override
  String get aiStudioUploadWav => 'Upload WAV file';

  @override
  String get aiStudioReplaceRecording => 'Replace recording';

  @override
  String get aiStudioOpening => 'Opening…';

  @override
  String get aiStudioDocNote =>
      'PDF, PNG or JPG · up to 10 MB and 10 pages\nUse a clear, upright page with readable text.';

  @override
  String get aiStudioChooseFile => 'Choose file';

  @override
  String get aiStudioReplaceFile => 'Replace file';

  @override
  String get aiStudioCapturePage => 'Capture page';

  @override
  String get aiStudioConsentTitle => 'I agree to paid AI processing';

  @override
  String get aiStudioConsentSubtitle =>
      'This sends my text or file to Sarvam, an external AI service, and uses the app’s paid processing allowance. Only send content you have permission to use. Nothing is published automatically.';

  @override
  String get aiStudioProcessing => 'Processing… Keep this screen open.';

  @override
  String aiStudioProcessWithAi(String tool) {
    return '$tool with AI';
  }

  @override
  String get aiStudioReviewAndUse => 'Review & use';

  @override
  String get aiStudioResultPlaceholder => 'Your result will appear here.';

  @override
  String get aiStudioResultDisclaimer =>
      'Nothing has been published or shared. Once text is ready, you can correct it, copy it, or choose a passage for the next step.';

  @override
  String get aiStudioEditableResult => 'Editable result';

  @override
  String get aiStudioReviewHelper =>
      'Review AI text before copying or sharing.';

  @override
  String get aiStudioCopy => 'Copy';

  @override
  String get aiStudioShare => 'Share';

  @override
  String get aiStudioCopyToShare => 'Copy to share';

  @override
  String get aiStudioTranslateResult => 'Translate result';

  @override
  String get aiStudioSendToBodhan => 'Send to Bodhan';

  @override
  String get aiStudioBodhanNote =>
      'Bodhan accepts a passage up to 600 characters. Opening it does not start voice generation.';

  @override
  String get aiStudioLookingForConverter =>
      'Looking for the free script converter?';

  @override
  String get aiStudioDisclaimer =>
      'AI results can contain mistakes; review names, numbers and spelling before use.';

  @override
  String aiStudioPassageNote(int limit) {
    return 'Choose or edit a passage of up to $limit characters. Your original result will stay unchanged.';
  }

  @override
  String get aiStudioPassageToSend => 'Passage to send';

  @override
  String get aiStudioPassageLimitError =>
      'Shorten the passage to continue. Nothing is truncated.';
}
