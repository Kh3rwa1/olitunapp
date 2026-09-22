import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_or.dart';
import 'app_localizations_sat.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('or'),
    Locale('sat'),
  ];

  /// No description provided for @helloUser.
  ///
  /// In en, this message translates to:
  /// **'Hello, {userName}! 👋'**
  String helloUser(String userName);

  /// No description provided for @readyToLearn.
  ///
  /// In en, this message translates to:
  /// **'Ready to learn today?'**
  String get readyToLearn;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get dayStreak;

  /// No description provided for @stars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get stars;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @continueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue Learning'**
  String get continueLearning;

  /// No description provided for @pickUpWhereLeftOff.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off'**
  String get pickUpWhereLeftOff;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Complete'**
  String percentComplete(int percent);

  /// No description provided for @dailyQuiz.
  ///
  /// In en, this message translates to:
  /// **'Daily Quiz'**
  String get dailyQuiz;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @lessonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String lessonsCount(int count);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @customizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Customize your learning experience'**
  String get customizeExperience;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @scriptDisplay.
  ///
  /// In en, this message translates to:
  /// **'Script Display'**
  String get scriptDisplay;

  /// No description provided for @scriptMode.
  ///
  /// In en, this message translates to:
  /// **'Script Mode'**
  String get scriptMode;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageChanged;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @playSoundsForActions.
  ///
  /// In en, this message translates to:
  /// **'Play sounds for actions'**
  String get playSoundsForActions;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get resetProgress;

  /// No description provided for @clearAllLearningData.
  ///
  /// In en, this message translates to:
  /// **'Clear all learning data'**
  String get clearAllLearningData;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get deleteAccountSubtitle;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How account and learning data are handled'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms Of Use'**
  String get termsOfUse;

  /// No description provided for @termsOfUseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rules for learners, accounts, and content'**
  String get termsOfUseSubtitle;

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose Theme'**
  String get chooseTheme;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get systemDefault;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @olChikiOnly.
  ///
  /// In en, this message translates to:
  /// **'Ol Chiki only'**
  String get olChikiOnly;

  /// No description provided for @latinOnly.
  ///
  /// In en, this message translates to:
  /// **'Latin only'**
  String get latinOnly;

  /// No description provided for @bothScripts.
  ///
  /// In en, this message translates to:
  /// **'Both scripts'**
  String get bothScripts;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @resetProgressWarning.
  ///
  /// In en, this message translates to:
  /// **'This will clear all your progress, stars, and streaks. This action cannot be undone.'**
  String get resetProgressWarning;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated data. This action cannot be undone.\n\nYour progress, settings, and personal information will be permanently removed.'**
  String get deleteAccountWarning;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @failedToDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {message}'**
  String failedToDeleteAccount(String message);

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get signInWithEmail;

  /// No description provided for @magicCodeDescription.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a magic code to verify your identity. No password needed!'**
  String get magicCodeDescription;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'learner@example.com'**
  String get emailHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get continueWithoutAccount;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}'**
  String codeSentTo(String email);

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @enterCodeFromEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter code from email'**
  String get enterCodeFromEmail;

  /// No description provided for @verifyAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// No description provided for @resendCodeIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @validEmailError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validEmailError;

  /// No description provided for @enterCodeError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get enterCodeError;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please resend the code.'**
  String get sessionExpired;

  /// No description provided for @errorCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Error copied to clipboard'**
  String get errorCopiedToClipboard;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @quiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @noQuestionsYet.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get noQuestionsYet;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @wellDone.
  ///
  /// In en, this message translates to:
  /// **'Well Done!'**
  String get wellDone;

  /// No description provided for @keepPracticing.
  ///
  /// In en, this message translates to:
  /// **'Keep Practicing'**
  String get keepPracticing;

  /// No description provided for @youScored.
  ///
  /// In en, this message translates to:
  /// **'You scored {score} out of {total}'**
  String youScored(int score, int total);

  /// No description provided for @plusStars.
  ///
  /// In en, this message translates to:
  /// **'+{count} Stars'**
  String plusStars(int count);

  /// No description provided for @aboutThisLesson.
  ///
  /// In en, this message translates to:
  /// **'About this lesson'**
  String get aboutThisLesson;

  /// No description provided for @completeLesson.
  ///
  /// In en, this message translates to:
  /// **'Complete Lesson'**
  String get completeLesson;

  /// No description provided for @lettersToLearn.
  ///
  /// In en, this message translates to:
  /// **'Letters to Learn'**
  String get lettersToLearn;

  /// No description provided for @numbersToLearn.
  ///
  /// In en, this message translates to:
  /// **'Numbers to Learn'**
  String get numbersToLearn;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @commonPhrases.
  ///
  /// In en, this message translates to:
  /// **'Common Phrases'**
  String get commonPhrases;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @takeAQuiz.
  ///
  /// In en, this message translates to:
  /// **'Take a Quiz'**
  String get takeAQuiz;

  /// No description provided for @testYourKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge now!'**
  String get testYourKnowledge;

  /// No description provided for @noLettersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No letters available yet'**
  String get noLettersAvailable;

  /// No description provided for @noNumbersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No numbers available yet'**
  String get noNumbersAvailable;

  /// No description provided for @noWordsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No words available yet'**
  String get noWordsAvailable;

  /// No description provided for @noSentencesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No sentences available yet'**
  String get noSentencesAvailable;

  /// No description provided for @noLessonsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No lessons available'**
  String get noLessonsAvailable;

  /// No description provided for @joharUser.
  ///
  /// In en, this message translates to:
  /// **'Johar, {userName}!'**
  String joharUser(String userName);

  /// No description provided for @dailyProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress: {percent}%'**
  String dailyProgressPercent(int percent);

  /// No description provided for @milestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestones;

  /// No description provided for @learningTime.
  ///
  /// In en, this message translates to:
  /// **'Learning Time'**
  String get learningTime;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @resumeJourney.
  ///
  /// In en, this message translates to:
  /// **'RESUME JOURNEY'**
  String get resumeJourney;

  /// No description provided for @testYourKnowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Test Your\nKnowledge!'**
  String get testYourKnowledgeTitle;

  /// No description provided for @quizzesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} Quizzes Available'**
  String quizzesAvailable(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get discover;

  /// No description provided for @couldNotLoadPaths.
  ///
  /// In en, this message translates to:
  /// **'Could not load learning paths'**
  String get couldNotLoadPaths;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'YOUR STATS'**
  String get yourStats;

  /// No description provided for @skillsMastery.
  ///
  /// In en, this message translates to:
  /// **'SKILLS MASTERY'**
  String get skillsMastery;

  /// No description provided for @quizAnalysis.
  ///
  /// In en, this message translates to:
  /// **'QUIZ ANALYSIS'**
  String get quizAnalysis;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get account;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @chooseYourAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Avatar'**
  String get chooseYourAvatar;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @avatarEmoji.
  ///
  /// In en, this message translates to:
  /// **'Avatar Emoji'**
  String get avatarEmoji;

  /// No description provided for @rhymes.
  ///
  /// In en, this message translates to:
  /// **'Bakhed'**
  String get rhymes;

  /// No description provided for @santali.
  ///
  /// In en, this message translates to:
  /// **'Santali'**
  String get santali;

  /// No description provided for @unlockMagic.
  ///
  /// In en, this message translates to:
  /// **'Unlock the magic of stories & songs'**
  String get unlockMagic;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @discoverMore.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER MORE'**
  String get discoverMore;

  /// No description provided for @moreComing.
  ///
  /// In en, this message translates to:
  /// **'More coming soon! ✨'**
  String get moreComing;

  /// No description provided for @couldNotLoadRhymes.
  ///
  /// In en, this message translates to:
  /// **'Could not load bakhed'**
  String get couldNotLoadRhymes;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get checkConnection;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get featured;

  /// No description provided for @listenNow.
  ///
  /// In en, this message translates to:
  /// **'LISTEN NOW'**
  String get listenNow;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'PAUSE'**
  String get pause;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @replayAnimation.
  ///
  /// In en, this message translates to:
  /// **'Replay Animation'**
  String get replayAnimation;

  /// No description provided for @sentences.
  ///
  /// In en, this message translates to:
  /// **'Sentences'**
  String get sentences;

  /// No description provided for @noSentencesFound.
  ///
  /// In en, this message translates to:
  /// **'No sentences found'**
  String get noSentencesFound;

  /// No description provided for @noQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'No questions found.'**
  String get noQuestionsFound;

  /// No description provided for @streakActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Streak Active'**
  String get streakActiveTitle;

  /// No description provided for @streakIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Your Streak'**
  String get streakIdleTitle;

  /// No description provided for @streakActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep learning to grow your flame!'**
  String get streakActiveSubtitle;

  /// No description provided for @streakIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete any activity to light your flame!'**
  String get streakIdleSubtitle;

  /// No description provided for @streakStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start learning'**
  String get streakStartLearning;

  /// No description provided for @streakDaysBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} DAYS'**
  String streakDaysBadge(int count);

  /// No description provided for @streakFooterActive.
  ///
  /// In en, this message translates to:
  /// **'You practiced {count} of {total} days this week. Keep it up!'**
  String streakFooterActive(int count, int total);

  /// No description provided for @streakFooterIdle.
  ///
  /// In en, this message translates to:
  /// **'No practice yet this week — pick any activity to begin!'**
  String get streakFooterIdle;

  /// No description provided for @streakWeekSemantics.
  ///
  /// In en, this message translates to:
  /// **'This week: practiced {count} of {total} days'**
  String streakWeekSemantics(int count, int total);

  /// No description provided for @dayDetailNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded'**
  String get dayDetailNoActivity;

  /// No description provided for @dayDetailPracticeSession.
  ///
  /// In en, this message translates to:
  /// **'Practice session'**
  String get dayDetailPracticeSession;

  /// No description provided for @dayDetailStreakDay.
  ///
  /// In en, this message translates to:
  /// **'Streak day'**
  String get dayDetailStreakDay;

  /// No description provided for @dayDetailQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get dayDetailQuiz;

  /// No description provided for @dayUpcoming.
  ///
  /// In en, this message translates to:
  /// **'upcoming'**
  String get dayUpcoming;

  /// No description provided for @dayPracticed.
  ///
  /// In en, this message translates to:
  /// **'practiced'**
  String get dayPracticed;

  /// No description provided for @dayNotPracticed.
  ///
  /// In en, this message translates to:
  /// **'not practiced'**
  String get dayNotPracticed;

  /// No description provided for @milestoneLevelProgressCaption.
  ///
  /// In en, this message translates to:
  /// **'Level progress · {from} → {to}'**
  String milestoneLevelProgressCaption(String from, String to);

  /// No description provided for @homeDiscover.
  ///
  /// In en, this message translates to:
  /// **'DISCOVER'**
  String get homeDiscover;

  /// No description provided for @homeSwipeHint.
  ///
  /// In en, this message translates to:
  /// **'SWIPE'**
  String get homeSwipeHint;

  /// No description provided for @homeExploreHint.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE'**
  String get homeExploreHint;

  /// No description provided for @guestSignInCta.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your progress'**
  String get guestSignInCta;

  /// No description provided for @nbaBadgeStartHere.
  ///
  /// In en, this message translates to:
  /// **'START HERE'**
  String get nbaBadgeStartHere;

  /// No description provided for @nbaTitleFirstLetters.
  ///
  /// In en, this message translates to:
  /// **'Learn your first Ol Chiki letters'**
  String get nbaTitleFirstLetters;

  /// No description provided for @nbaSubFirstLetters.
  ///
  /// In en, this message translates to:
  /// **'Begin with the basic alphabet and unlock Santali writing.'**
  String get nbaSubFirstLetters;

  /// No description provided for @nbaCtaBeginLesson.
  ///
  /// In en, this message translates to:
  /// **'Begin Lesson'**
  String get nbaCtaBeginLesson;

  /// No description provided for @nbaBadgeNextStep.
  ///
  /// In en, this message translates to:
  /// **'NEXT STEP'**
  String get nbaBadgeNextStep;

  /// No description provided for @nbaTitleNumbers.
  ///
  /// In en, this message translates to:
  /// **'Practice Santali numbers'**
  String get nbaTitleNumbers;

  /// No description provided for @nbaSubNumbers.
  ///
  /// In en, this message translates to:
  /// **'Build confidence with everyday counting and number words.'**
  String get nbaSubNumbers;

  /// No description provided for @nbaCtaPracticeNumbers.
  ///
  /// In en, this message translates to:
  /// **'Practice Numbers'**
  String get nbaCtaPracticeNumbers;

  /// No description provided for @nbaBadgeMistakes.
  ///
  /// In en, this message translates to:
  /// **'PRACTICE NEEDED'**
  String get nbaBadgeMistakes;

  /// No description provided for @nbaTitleMistakes.
  ///
  /// In en, this message translates to:
  /// **'Transform mistakes into wisdom'**
  String get nbaTitleMistakes;

  /// No description provided for @nbaSubMistakes.
  ///
  /// In en, this message translates to:
  /// **'You have {count} question(s) to review and master.'**
  String nbaSubMistakes(int count);

  /// No description provided for @nbaCtaReviewMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review Mistakes'**
  String get nbaCtaReviewMistakes;

  /// No description provided for @nbaBadgeStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'STREAK RISK'**
  String get nbaBadgeStreakRisk;

  /// No description provided for @nbaTitleStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'Keep your daily momentum'**
  String get nbaTitleStreakRisk;

  /// No description provided for @nbaSubStreakRisk.
  ///
  /// In en, this message translates to:
  /// **'One quick quiz or lesson will secure your {count} day streak today.'**
  String nbaSubStreakRisk(int count);

  /// No description provided for @nbaCtaQuickReview.
  ///
  /// In en, this message translates to:
  /// **'Quick Review'**
  String get nbaCtaQuickReview;

  /// No description provided for @nbaBadgeTryBakhed.
  ///
  /// In en, this message translates to:
  /// **'TRY BAKHED'**
  String get nbaBadgeTryBakhed;

  /// No description provided for @nbaTitleTryBakhed.
  ///
  /// In en, this message translates to:
  /// **'Listen to a cultural rhyme'**
  String get nbaTitleTryBakhed;

  /// No description provided for @nbaSubTryBakhed.
  ///
  /// In en, this message translates to:
  /// **'Immerse yourself in beautiful Santali oral poetry for 30s.'**
  String get nbaSubTryBakhed;

  /// No description provided for @nbaCtaListenNow.
  ///
  /// In en, this message translates to:
  /// **'Listen Now'**
  String get nbaCtaListenNow;

  /// No description provided for @nbaBadgeAllDone.
  ///
  /// In en, this message translates to:
  /// **'ALL COMPLETE'**
  String get nbaBadgeAllDone;

  /// No description provided for @nbaTitleAllDone.
  ///
  /// In en, this message translates to:
  /// **'You finished everything — brilliant!'**
  String get nbaTitleAllDone;

  /// No description provided for @nbaSubAllDone.
  ///
  /// In en, this message translates to:
  /// **'New lessons are on the way. Revisit Bakhed or review anytime.'**
  String get nbaSubAllDone;

  /// No description provided for @nbaCtaExploreBakhed.
  ///
  /// In en, this message translates to:
  /// **'Explore Bakhed'**
  String get nbaCtaExploreBakhed;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bengali'**
  String get bengali;

  /// No description provided for @odia.
  ///
  /// In en, this message translates to:
  /// **'Odia'**
  String get odia;

  /// No description provided for @teachingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Teaching Language'**
  String get teachingLanguage;

  /// No description provided for @teachingLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Used for meanings and explanations'**
  String get teachingLanguageSubtitle;

  /// No description provided for @lessonAudioMode.
  ///
  /// In en, this message translates to:
  /// **'Lesson Audio'**
  String get lessonAudioMode;

  /// No description provided for @lessonAudioModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how Santali and translation audio play'**
  String get lessonAudioModeSubtitle;

  /// No description provided for @onboardingStepLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Which language do you understand best?'**
  String get onboardingStepLanguageTitle;

  /// No description provided for @onboardingStepProficiencyTitle.
  ///
  /// In en, this message translates to:
  /// **'How much Santali do you know?'**
  String get onboardingStepProficiencyTitle;

  /// No description provided for @onboardingStepGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to achieve?'**
  String get onboardingStepGoalsTitle;

  /// No description provided for @onboardingStepGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick one or more — we\'ll personalize your path.'**
  String get onboardingStepGoalsSubtitle;

  /// No description provided for @onboardingStepAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'How should lesson audio play?'**
  String get onboardingStepAudioTitle;

  /// No description provided for @onboardingStepReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost ready!'**
  String get onboardingStepReadyTitle;

  /// No description provided for @proficiencyNone.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know Santali'**
  String get proficiencyNone;

  /// No description provided for @proficiencyUnderstandsSome.
  ///
  /// In en, this message translates to:
  /// **'I understand some Santali'**
  String get proficiencyUnderstandsSome;

  /// No description provided for @proficiencyFluentSpeaker.
  ///
  /// In en, this message translates to:
  /// **'I speak Santali'**
  String get proficiencyFluentSpeaker;

  /// No description provided for @proficiencyBeginnerReader.
  ///
  /// In en, this message translates to:
  /// **'I can read a little Ol Chiki'**
  String get proficiencyBeginnerReader;

  /// No description provided for @proficiencyFluentReader.
  ///
  /// In en, this message translates to:
  /// **'I already read Ol Chiki'**
  String get proficiencyFluentReader;

  /// No description provided for @goalSpeakSantali.
  ///
  /// In en, this message translates to:
  /// **'Speak Santali'**
  String get goalSpeakSantali;

  /// No description provided for @goalUnderstandSantali.
  ///
  /// In en, this message translates to:
  /// **'Understand Santali'**
  String get goalUnderstandSantali;

  /// No description provided for @goalReadOlChiki.
  ///
  /// In en, this message translates to:
  /// **'Read Ol Chiki'**
  String get goalReadOlChiki;

  /// No description provided for @goalWriteOlChiki.
  ///
  /// In en, this message translates to:
  /// **'Write Ol Chiki'**
  String get goalWriteOlChiki;

  /// No description provided for @goalLearnEverything.
  ///
  /// In en, this message translates to:
  /// **'Learn everything'**
  String get goalLearnEverything;

  /// No description provided for @goalHelpMyChild.
  ///
  /// In en, this message translates to:
  /// **'Help my child learn'**
  String get goalHelpMyChild;

  /// No description provided for @goalPrepareExam.
  ///
  /// In en, this message translates to:
  /// **'Prepare for school or an exam'**
  String get goalPrepareExam;

  /// No description provided for @audioModeTargetOnly.
  ///
  /// In en, this message translates to:
  /// **'Santali only'**
  String get audioModeTargetOnly;

  /// No description provided for @audioModeBilingual.
  ///
  /// In en, this message translates to:
  /// **'Santali, then my language'**
  String get audioModeBilingual;

  /// No description provided for @audioModeTranslationOnDemand.
  ///
  /// In en, this message translates to:
  /// **'Play translation only when I tap it'**
  String get audioModeTranslationOnDemand;

  /// No description provided for @dailyGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoalLabel;

  /// No description provided for @minutesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min/day'**
  String minutesPerDay(int minutes);

  /// No description provided for @downloadStarterAudio.
  ///
  /// In en, this message translates to:
  /// **'Download starter audio'**
  String get downloadStarterAudio;

  /// No description provided for @downloadStarterAudioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Learn offline from day one'**
  String get downloadStarterAudioSubtitle;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @joharLoading.
  ///
  /// In en, this message translates to:
  /// **'Johar... Loading'**
  String get joharLoading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong!'**
  String get somethingWentWrong;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode. Showing cached content.'**
  String get offlineMode;

  /// No description provided for @offlineProgressCached.
  ///
  /// In en, this message translates to:
  /// **'Offline. Progress cached locally.'**
  String get offlineProgressCached;

  /// No description provided for @syncingProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing progress...'**
  String get syncingProgress;

  /// No description provided for @progressSynced.
  ///
  /// In en, this message translates to:
  /// **'Progress synced!'**
  String get progressSynced;

  /// No description provided for @failedToSyncProgress.
  ///
  /// In en, this message translates to:
  /// **'Failed to sync progress.'**
  String get failedToSyncProgress;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @pleaseLogInToPurchase.
  ///
  /// In en, this message translates to:
  /// **'Please log in to purchase courses.'**
  String get pleaseLogInToPurchase;

  /// No description provided for @creatingSecureOrder.
  ///
  /// In en, this message translates to:
  /// **'Creating secure server order...'**
  String get creatingSecureOrder;

  /// No description provided for @openingPaymentGateway.
  ///
  /// In en, this message translates to:
  /// **'Opening payment gateway...'**
  String get openingPaymentGateway;

  /// No description provided for @verifyingPayment.
  ///
  /// In en, this message translates to:
  /// **'Verifying payment with server...'**
  String get verifyingPayment;

  /// No description provided for @courseUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Course successfully unlocked!'**
  String get courseUnlocked;

  /// No description provided for @failedToCreateOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to create payment order'**
  String get failedToCreateOrder;

  /// No description provided for @paymentVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment verification failed'**
  String get paymentVerificationFailed;

  /// No description provided for @checkoutUnexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Checkout encountered an unexpected error: {error}'**
  String checkoutUnexpectedError(String error);

  /// No description provided for @unlockCourse.
  ///
  /// In en, this message translates to:
  /// **'Unlock Course (₹{amount})'**
  String unlockCourse(String amount);

  /// No description provided for @trustBadgeSecureCheckout.
  ///
  /// In en, this message translates to:
  /// **'256-bit encrypted checkout via Razorpay • Instant access'**
  String get trustBadgeSecureCheckout;

  /// No description provided for @webMonetizationRestrictedTitle.
  ///
  /// In en, this message translates to:
  /// **'Monetization restricted on Web'**
  String get webMonetizationRestrictedTitle;

  /// No description provided for @webMonetizationNotice.
  ///
  /// In en, this message translates to:
  /// **'Razorpay checkouts and App Store reviews are only supported on the Olitun Mobile Application. Please load this on Android/iOS to unlock.'**
  String get webMonetizationNotice;

  /// No description provided for @aboutThisCourse.
  ///
  /// In en, this message translates to:
  /// **'About this course'**
  String get aboutThisCourse;

  /// No description provided for @courseOutcome.
  ///
  /// In en, this message translates to:
  /// **'Course Outcome'**
  String get courseOutcome;

  /// No description provided for @premiumCourseBadge.
  ///
  /// In en, this message translates to:
  /// **'PREMIUM COURSE'**
  String get premiumCourseBadge;

  /// No description provided for @maranJauharTitle.
  ///
  /// In en, this message translates to:
  /// **'Maran Jauhar! 🎉'**
  String get maranJauharTitle;

  /// No description provided for @startLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get startLearning;

  /// No description provided for @paywallValueOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Full Offline Pack Access'**
  String get paywallValueOfflineTitle;

  /// No description provided for @paywallValueOfflineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download lessons, audio pronunciations, and quizzes for anytime offline learning.'**
  String get paywallValueOfflineSubtitle;

  /// No description provided for @paywallValueAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI Translations'**
  String get paywallValueAiTitle;

  /// No description provided for @paywallValueAiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Ol Chiki translations and pronunciation guides without query limits.'**
  String get paywallValueAiSubtitle;

  /// No description provided for @paywallValueAdFreeTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero Ad Interruptions'**
  String get paywallValueAdFreeTitle;

  /// No description provided for @paywallValueAdFreeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Experience 100% distraction-free language practice across all modules.'**
  String get paywallValueAdFreeSubtitle;

  /// No description provided for @paywallValueLifetimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Access Guarantee'**
  String get paywallValueLifetimeTitle;

  /// No description provided for @paywallValueLifetimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay once with no recurring fees, subscriptions, or hidden charges.'**
  String get paywallValueLifetimeSubtitle;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navBakhed.
  ///
  /// In en, this message translates to:
  /// **'Bakhed'**
  String get navBakhed;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navTabSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} tab'**
  String navTabSemantics(String label);

  /// No description provided for @navItemSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label} navigation item'**
  String navItemSemantics(String label);

  /// No description provided for @kudosMistake1.
  ///
  /// In en, this message translates to:
  /// **'Mistakes reviewed. That\'s how mastery is built.'**
  String get kudosMistake1;

  /// No description provided for @kudosMistake2.
  ///
  /// In en, this message translates to:
  /// **'Mastery in progress! You transformed mistakes into wisdom.'**
  String get kudosMistake2;

  /// No description provided for @kudosMistake3.
  ///
  /// In en, this message translates to:
  /// **'Fantastic! Correcting mistakes is the secret to fluency.'**
  String get kudosMistake3;

  /// No description provided for @kudosMistake4.
  ///
  /// In en, this message translates to:
  /// **'Brilliant review! You are learning faster by refining errors.'**
  String get kudosMistake4;

  /// No description provided for @reviewToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S REVIEW'**
  String get reviewToday;

  /// No description provided for @reviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your review…'**
  String get reviewLoading;

  /// No description provided for @reviewDueOne.
  ///
  /// In en, this message translates to:
  /// **'1 review due'**
  String get reviewDueOne;

  /// No description provided for @reviewDueOther.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews due'**
  String reviewDueOther(int count);

  /// No description provided for @reviewDueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min · from lessons you already started'**
  String reviewDueSubtitle(int minutes);

  /// No description provided for @reviewStart.
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get reviewStart;

  /// No description provided for @reviewCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re caught up.'**
  String get reviewCaughtUp;

  /// No description provided for @reviewCaughtUpRetained.
  ///
  /// In en, this message translates to:
  /// **'{count} items retained so far. Keep remembering.'**
  String reviewCaughtUpRetained(int count);

  /// No description provided for @reviewCaughtUpEmpty.
  ///
  /// In en, this message translates to:
  /// **'Start a lesson below — what you learn will show up here for review.'**
  String get reviewCaughtUpEmpty;

  /// No description provided for @reviewContinueLearning.
  ///
  /// In en, this message translates to:
  /// **'Continue learning'**
  String get reviewContinueLearning;

  /// No description provided for @reviewLearnNew.
  ///
  /// In en, this message translates to:
  /// **'Learn something new'**
  String get reviewLearnNew;

  /// No description provided for @reviewRetained.
  ///
  /// In en, this message translates to:
  /// **'{count} retained'**
  String reviewRetained(int count);

  /// No description provided for @reviewExit.
  ///
  /// In en, this message translates to:
  /// **'Exit review'**
  String get reviewExit;

  /// No description provided for @reviewSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Review {current} of {total}'**
  String reviewSessionTitle(int current, int total);

  /// No description provided for @reviewSessionTitleBare.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Review'**
  String get reviewSessionTitleBare;

  /// No description provided for @reviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Review complete'**
  String get reviewComplete;

  /// No description provided for @reviewCorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct — nice recall.'**
  String get reviewCorrectFeedback;

  /// No description provided for @reviewWrongFeedback.
  ///
  /// In en, this message translates to:
  /// **'Not quite — this one comes back sooner.'**
  String get reviewWrongFeedback;

  /// No description provided for @reviewCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct answer: {answer}'**
  String reviewCorrectAnswer(String answer);

  /// No description provided for @reviewHintTyping.
  ///
  /// In en, this message translates to:
  /// **'Type each sound, slowly.'**
  String get reviewHintTyping;

  /// No description provided for @reviewHintListening.
  ///
  /// In en, this message translates to:
  /// **'Listen again — match the sound to the meaning.'**
  String get reviewHintListening;

  /// No description provided for @reviewHintRecognition.
  ///
  /// In en, this message translates to:
  /// **'Sound it out from the Ol Chiki letters.'**
  String get reviewHintRecognition;

  /// No description provided for @reviewRepromptListen.
  ///
  /// In en, this message translates to:
  /// **'LISTEN'**
  String get reviewRepromptListen;

  /// No description provided for @reviewRepromptWrite.
  ///
  /// In en, this message translates to:
  /// **'WRITE IN OL CHIKI'**
  String get reviewRepromptWrite;

  /// No description provided for @reviewRepromptMeaning.
  ///
  /// In en, this message translates to:
  /// **'WHAT DOES THIS MEAN?'**
  String get reviewRepromptMeaning;

  /// No description provided for @reviewPlayAudio.
  ///
  /// In en, this message translates to:
  /// **'Play audio'**
  String get reviewPlayAudio;

  /// No description provided for @reviewReplayAudio.
  ///
  /// In en, this message translates to:
  /// **'Replay audio'**
  String get reviewReplayAudio;

  /// No description provided for @reviewCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get reviewCheck;

  /// No description provided for @reviewFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish review'**
  String get reviewFinish;

  /// No description provided for @reviewBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get reviewBackHome;

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reviewDone;

  /// No description provided for @reviewCaughtUpShort.
  ///
  /// In en, this message translates to:
  /// **'Nothing due. Learn something new below to keep the loop going.'**
  String get reviewCaughtUpShort;

  /// No description provided for @reviewSummaryScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} of {total} correct ({accuracy}%)'**
  String reviewSummaryScore(int correct, int total, int accuracy);

  /// No description provided for @reviewSummaryMastered.
  ///
  /// In en, this message translates to:
  /// **'{mastered} mastered · +{stars} stars'**
  String reviewSummaryMastered(int mastered, int stars);

  /// No description provided for @reviewSummaryRecovery.
  ///
  /// In en, this message translates to:
  /// **'Missed items come back sooner — that is the system working, not failing.'**
  String get reviewSummaryRecovery;

  /// No description provided for @reviewLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your review'**
  String get reviewLoadError;

  /// No description provided for @reviewLoadErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Your {count} due reviews are safe — the lesson content just didn\'t load. Check your connection and retry.'**
  String reviewLoadErrorBody(int count);

  /// No description provided for @notifReviewTitleOne.
  ///
  /// In en, this message translates to:
  /// **'1 review ready'**
  String get notifReviewTitleOne;

  /// No description provided for @notifReviewTitleOther.
  ///
  /// In en, this message translates to:
  /// **'{count} reviews ready'**
  String notifReviewTitleOther(int count);

  /// No description provided for @notifReviewBodyOne.
  ///
  /// In en, this message translates to:
  /// **'1 item is ready for review (~{minutes} min). Open Today\'s Review when you have a moment.'**
  String notifReviewBodyOne(int minutes);

  /// No description provided for @notifReviewBodyOther.
  ///
  /// In en, this message translates to:
  /// **'{count} items are ready for review (~{minutes} min). Open Today\'s Review when you have a moment.'**
  String notifReviewBodyOther(int count, int minutes);

  /// No description provided for @notifStruggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Tricky ones are back'**
  String get notifStruggleTitle;

  /// No description provided for @notifStruggleBodyOne.
  ///
  /// In en, this message translates to:
  /// **'A word you found tricky is due again — a quick retry locks it in.'**
  String get notifStruggleBodyOne;

  /// No description provided for @notifStruggleBodyOther.
  ///
  /// In en, this message translates to:
  /// **'{count} words you found tricky are due again — a quick retry locks them in.'**
  String notifStruggleBodyOther(int count);

  /// No description provided for @notifGentleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Santali is waiting'**
  String get notifGentleTitle;

  /// No description provided for @notifGentleBody.
  ///
  /// In en, this message translates to:
  /// **'A short review keeps what you learned fresh. No rush.'**
  String get notifGentleBody;

  /// No description provided for @santaliAiVoice.
  ///
  /// In en, this message translates to:
  /// **'Santali AI Voice'**
  String get santaliAiVoice;

  /// No description provided for @closeVoiceStudio.
  ///
  /// In en, this message translates to:
  /// **'Close voice studio'**
  String get closeVoiceStudio;

  /// No description provided for @createVoiceAction.
  ///
  /// In en, this message translates to:
  /// **'CREATE VOICE'**
  String get createVoiceAction;

  /// No description provided for @creatingVoiceProgress.
  ///
  /// In en, this message translates to:
  /// **'CREATING VOICE...'**
  String get creatingVoiceProgress;

  /// No description provided for @voiceStatusWorking.
  ///
  /// In en, this message translates to:
  /// **'Giving your words a Santali voice…'**
  String get voiceStatusWorking;

  /// No description provided for @voiceStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Type it. Hear it. Share it.'**
  String get voiceStatusIdle;

  /// No description provided for @voiceStatusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing • {voice}'**
  String voiceStatusPlaying(String voice);

  /// No description provided for @voiceStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready • tap play'**
  String get voiceStatusReady;

  /// No description provided for @voiceStatusOpenPlayer.
  ///
  /// In en, this message translates to:
  /// **'Voice ready • open player below'**
  String get voiceStatusOpenPlayer;

  /// No description provided for @voiceCacheTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: repeat clips are instant and free — they replay from cache.'**
  String get voiceCacheTip;

  /// No description provided for @voiceDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed.'**
  String get voiceDownloadFailed;

  /// No description provided for @voiceInputHint.
  ///
  /// In en, this message translates to:
  /// **'ᱟᱢᱟᱜ ᱧᱩᱛᱩᱢ ᱫᱚ ᱪᱮᱫ ᱠᱟᱱᱟ? — type in Ol Chiki...'**
  String get voiceInputHint;

  /// No description provided for @voicePlayerTab.
  ///
  /// In en, this message translates to:
  /// **'PLAYER'**
  String get voicePlayerTab;

  /// No description provided for @voiceCreatingBack.
  ///
  /// In en, this message translates to:
  /// **'Creating your voice…'**
  String get voiceCreatingBack;

  /// No description provided for @voiceEmptyBack.
  ///
  /// In en, this message translates to:
  /// **'Your voice will appear here'**
  String get voiceEmptyBack;

  /// No description provided for @voiceEditText.
  ///
  /// In en, this message translates to:
  /// **'Edit text'**
  String get voiceEditText;

  /// No description provided for @voiceDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get voiceDismiss;

  /// No description provided for @voicePlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback speed'**
  String get voicePlaybackSpeed;

  /// No description provided for @voiceSaving.
  ///
  /// In en, this message translates to:
  /// **'SAVING…'**
  String get voiceSaving;

  /// No description provided for @voiceDownload.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get voiceDownload;

  /// No description provided for @voiceRegenerate.
  ///
  /// In en, this message translates to:
  /// **'REGENERATE'**
  String get voiceRegenerate;

  /// No description provided for @voicePickerHeader.
  ///
  /// In en, this message translates to:
  /// **'VOICE  •  ᱟᱲᱟᱝ'**
  String get voicePickerHeader;

  /// No description provided for @voiceStyleHeader.
  ///
  /// In en, this message translates to:
  /// **'STYLE  •  ᱨᱚᱲ'**
  String get voiceStyleHeader;

  /// No description provided for @voiceSignInUpper.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN'**
  String get voiceSignInUpper;

  /// No description provided for @voiceRetryUpper.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get voiceRetryUpper;

  /// No description provided for @aiStudioTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Studio'**
  String get aiStudioTitle;

  /// No description provided for @aiStudioToolTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get aiStudioToolTranscribe;

  /// No description provided for @aiStudioToolTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get aiStudioToolTranslate;

  /// No description provided for @aiStudioToolScan.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get aiStudioToolScan;

  /// No description provided for @aiStudioHeadline.
  ///
  /// In en, this message translates to:
  /// **'From a page or a voice\nto words you can use.'**
  String get aiStudioHeadline;

  /// No description provided for @aiStudioSubhead.
  ///
  /// In en, this message translates to:
  /// **'Translate text, transcribe a short recording, or scan a document. Review the result before taking it anywhere.'**
  String get aiStudioSubhead;

  /// No description provided for @aiStudioStep1.
  ///
  /// In en, this message translates to:
  /// **'1  Add input'**
  String get aiStudioStep1;

  /// No description provided for @aiStudioStep2.
  ///
  /// In en, this message translates to:
  /// **'2  Process with consent'**
  String get aiStudioStep2;

  /// No description provided for @aiStudioStep3.
  ///
  /// In en, this message translates to:
  /// **'3  Review & use'**
  String get aiStudioStep3;

  /// No description provided for @aiStudioNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI processing is not available in this build. You can prepare text here or use the free script converter below.'**
  String get aiStudioNotConfigured;

  /// No description provided for @aiStudioYourText.
  ///
  /// In en, this message translates to:
  /// **'Your text'**
  String get aiStudioYourText;

  /// No description provided for @aiStudioYourAudio.
  ///
  /// In en, this message translates to:
  /// **'Your audio'**
  String get aiStudioYourAudio;

  /// No description provided for @aiStudioYourDocument.
  ///
  /// In en, this message translates to:
  /// **'Your document'**
  String get aiStudioYourDocument;

  /// No description provided for @aiStudioSourceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Source language'**
  String get aiStudioSourceLanguage;

  /// No description provided for @aiStudioTranslateNote.
  ///
  /// In en, this message translates to:
  /// **'Translate into Santali (Ol Chiki). Up to 2,000 characters.'**
  String get aiStudioTranslateNote;

  /// No description provided for @aiStudioTextToTranslate.
  ///
  /// In en, this message translates to:
  /// **'Text to translate'**
  String get aiStudioTextToTranslate;

  /// No description provided for @aiStudioTextPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type or paste your text'**
  String get aiStudioTextPlaceholder;

  /// No description provided for @aiStudioTextLimitError.
  ///
  /// In en, this message translates to:
  /// **'Choose a passage of 2,000 characters or fewer.'**
  String get aiStudioTextLimitError;

  /// No description provided for @aiStudioSpeakNote.
  ///
  /// In en, this message translates to:
  /// **'Speak normally. Recording stops automatically at 30 seconds. You can also upload a WAV file instead.'**
  String get aiStudioSpeakNote;

  /// No description provided for @aiStudioRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get aiStudioRecordVoice;

  /// No description provided for @aiStudioStopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording · {seconds}s'**
  String aiStudioStopRecording(String seconds);

  /// No description provided for @aiStudioListening.
  ///
  /// In en, this message translates to:
  /// **'Listening… Tap Stop recording when you are done.'**
  String get aiStudioListening;

  /// No description provided for @aiStudioOrExistingRecording.
  ///
  /// In en, this message translates to:
  /// **'Or use an existing recording'**
  String get aiStudioOrExistingRecording;

  /// No description provided for @aiStudioUploadWav.
  ///
  /// In en, this message translates to:
  /// **'Upload WAV file'**
  String get aiStudioUploadWav;

  /// No description provided for @aiStudioReplaceRecording.
  ///
  /// In en, this message translates to:
  /// **'Replace recording'**
  String get aiStudioReplaceRecording;

  /// No description provided for @aiStudioOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get aiStudioOpening;

  /// No description provided for @aiStudioDocNote.
  ///
  /// In en, this message translates to:
  /// **'PDF, PNG or JPG · up to 10 MB and 10 pages\nUse a clear, upright page with readable text.'**
  String get aiStudioDocNote;

  /// No description provided for @aiStudioChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get aiStudioChooseFile;

  /// No description provided for @aiStudioReplaceFile.
  ///
  /// In en, this message translates to:
  /// **'Replace file'**
  String get aiStudioReplaceFile;

  /// No description provided for @aiStudioCapturePage.
  ///
  /// In en, this message translates to:
  /// **'Capture page'**
  String get aiStudioCapturePage;

  /// No description provided for @aiStudioProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing… Keep this screen open.'**
  String get aiStudioProcessing;

  /// No description provided for @aiStudioProcessWithAi.
  ///
  /// In en, this message translates to:
  /// **'{tool} with AI'**
  String aiStudioProcessWithAi(String tool);

  /// No description provided for @aiStudioReviewAndUse.
  ///
  /// In en, this message translates to:
  /// **'Review & use'**
  String get aiStudioReviewAndUse;

  /// No description provided for @aiStudioResultPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Your result will appear here.'**
  String get aiStudioResultPlaceholder;

  /// No description provided for @aiStudioResultDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been published or shared. Once text is ready, you can correct it, copy it, or choose a passage for the next step.'**
  String get aiStudioResultDisclaimer;

  /// No description provided for @aiStudioReviewHelper.
  ///
  /// In en, this message translates to:
  /// **'Review AI text before copying or sharing.'**
  String get aiStudioReviewHelper;

  /// No description provided for @aiStudioCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get aiStudioCopy;

  /// No description provided for @aiStudioShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get aiStudioShare;

  /// No description provided for @aiStudioCopyToShare.
  ///
  /// In en, this message translates to:
  /// **'Copy to share'**
  String get aiStudioCopyToShare;

  /// No description provided for @aiStudioTranslateResult.
  ///
  /// In en, this message translates to:
  /// **'Translate result'**
  String get aiStudioTranslateResult;

  /// No description provided for @aiStudioSendToVoiceStudio.
  ///
  /// In en, this message translates to:
  /// **'Voice Studio'**
  String get aiStudioSendToVoiceStudio;

  /// No description provided for @aiStudioAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get aiStudioAuto;

  /// No description provided for @aiStudioLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get aiStudioLive;

  /// No description provided for @aiStudioThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get aiStudioThinking;

  /// No description provided for @aiStudioScanningLive.
  ///
  /// In en, this message translates to:
  /// **'Reading your page — updates appear here live.'**
  String get aiStudioScanningLive;

  /// No description provided for @aiStudioLookingForConverter.
  ///
  /// In en, this message translates to:
  /// **'Looking for the free script converter?'**
  String get aiStudioLookingForConverter;

  /// No description provided for @aiStudioDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI results can contain mistakes; review names, numbers and spelling before use.'**
  String get aiStudioDisclaimer;

  /// No description provided for @aiStudioPassageNote.
  ///
  /// In en, this message translates to:
  /// **'Choose or edit a passage of up to {limit} characters. Your original result will stay unchanged.'**
  String aiStudioPassageNote(int limit);

  /// No description provided for @aiStudioPassageToSend.
  ///
  /// In en, this message translates to:
  /// **'Passage to send'**
  String get aiStudioPassageToSend;

  /// No description provided for @aiStudioPassageLimitError.
  ///
  /// In en, this message translates to:
  /// **'Shorten the passage to continue. Nothing is truncated.'**
  String get aiStudioPassageLimitError;

  /// No description provided for @aiStudioUploadPrompt.
  ///
  /// In en, this message translates to:
  /// **'Upload document or capture page'**
  String get aiStudioUploadPrompt;

  /// No description provided for @aiStudioUploadFormats.
  ///
  /// In en, this message translates to:
  /// **'PDF, PNG or JPG · up to 10 MB'**
  String get aiStudioUploadFormats;

  /// No description provided for @aiStudioJobId.
  ///
  /// In en, this message translates to:
  /// **'Job: {id}'**
  String aiStudioJobId(String id);

  /// No description provided for @aiStudioCheckStatus.
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get aiStudioCheckStatus;

  /// No description provided for @aiStudioReplaceWithScan.
  ///
  /// In en, this message translates to:
  /// **'Replace my edits with latest scan text'**
  String get aiStudioReplaceWithScan;

  /// No description provided for @aiStudioEditSource.
  ///
  /// In en, this message translates to:
  /// **'Edit source input'**
  String get aiStudioEditSource;

  /// No description provided for @olitun.
  ///
  /// In en, this message translates to:
  /// **'Olitun'**
  String get olitun;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Learn Ol Chiki Script'**
  String get welcomeTagline;

  /// No description provided for @errorLoadingContent.
  ///
  /// In en, this message translates to:
  /// **'Error loading content: {error}'**
  String errorLoadingContent(String error);

  /// No description provided for @startQuiz2.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get startQuiz2;

  /// No description provided for @practiceTyping.
  ///
  /// In en, this message translates to:
  /// **'Practice Typing'**
  String get practiceTyping;

  /// No description provided for @mediaDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {seconds}s'**
  String mediaDuration(int seconds);

  /// No description provided for @noLearningContent.
  ///
  /// In en, this message translates to:
  /// **'No learning content available.'**
  String get noLearningContent;

  /// No description provided for @errorLoadingDetails.
  ///
  /// In en, this message translates to:
  /// **'Error loading details: {error}'**
  String errorLoadingDetails(String error);

  /// No description provided for @culturalNotesPreparing.
  ///
  /// In en, this message translates to:
  /// **'Cultural notes are being prepared.'**
  String get culturalNotesPreparing;

  /// No description provided for @culturalNoteSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String culturalNoteSource(String source);

  /// No description provided for @noVocabularyItems.
  ///
  /// In en, this message translates to:
  /// **'No vocabulary items defined.'**
  String get noVocabularyItems;

  /// No description provided for @lyricsBeingAdded.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are being added.'**
  String get lyricsBeingAdded;

  /// No description provided for @bakhedLabel.
  ///
  /// In en, this message translates to:
  /// **'BAKHED'**
  String get bakhedLabel;

  /// No description provided for @wordLabel.
  ///
  /// In en, this message translates to:
  /// **'word'**
  String get wordLabel;

  /// No description provided for @cancelLower.
  ///
  /// In en, this message translates to:
  /// **'cancel'**
  String get cancelLower;

  /// No description provided for @greetingDayPart.
  ///
  /// In en, this message translates to:
  /// **'ᱡᱚᱦᱟᱨ • {part}'**
  String greetingDayPart(String part);

  /// No description provided for @homePickupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick up where you left off — small steps, every day.'**
  String get homePickupSubtitle;

  /// No description provided for @aiTranslatorTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Translator'**
  String get aiTranslatorTitle;

  /// No description provided for @voiceSpeakWithConfidence.
  ///
  /// In en, this message translates to:
  /// **'Speak With\nConfidence'**
  String get voiceSpeakWithConfidence;

  /// No description provided for @aiStudioPromoBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW • AI STUDIO'**
  String get aiStudioPromoBadge;

  /// No description provided for @aiStudioPromoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan or speak — get Santali text.'**
  String get aiStudioPromoSubtitle;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @instantTranslate.
  ///
  /// In en, this message translates to:
  /// **'Instant Translate'**
  String get instantTranslate;

  /// No description provided for @anyLanguageToOlChiki.
  ///
  /// In en, this message translates to:
  /// **'Any Language → Ol Chiki'**
  String get anyLanguageToOlChiki;

  /// No description provided for @aiBadge.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get aiBadge;

  /// No description provided for @yourLearningPath.
  ///
  /// In en, this message translates to:
  /// **'YOUR LEARNING PATH'**
  String get yourLearningPath;

  /// No description provided for @stepOfPath.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}: '**
  String stepOfPath(int step, int total);

  /// No description provided for @learningPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A guided path matched to your Santali level.'**
  String get learningPathSubtitle;

  /// No description provided for @santaliOlChikiLabel.
  ///
  /// In en, this message translates to:
  /// **'SANTALI (OL CHIKI)'**
  String get santaliOlChikiLabel;

  /// No description provided for @magicTranslatePrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Translations are processed securely, cached via privacy hashes, and never linked to your profile.'**
  String get magicTranslatePrivacyNote;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// No description provided for @aiVoicePromoBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW • AI VOICE'**
  String get aiVoicePromoBadge;

  /// No description provided for @aiVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Voice'**
  String get aiVoiceTitle;

  /// No description provided for @aiVoicePromoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type anything — hear it in Santali.'**
  String get aiVoicePromoSubtitle;

  /// No description provided for @tryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get tryNow;

  /// No description provided for @k15Styles.
  ///
  /// In en, this message translates to:
  /// **'ᱟᱲᱟᱝ • 15 styles'**
  String get k15Styles;

  /// No description provided for @backToLearningPaths.
  ///
  /// In en, this message translates to:
  /// **'Back to learning paths'**
  String get backToLearningPaths;

  /// No description provided for @learningPathsHeader.
  ///
  /// In en, this message translates to:
  /// **'LEARNING PATHS'**
  String get learningPathsHeader;

  /// No description provided for @chooseYourJourney.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Journey'**
  String get chooseYourJourney;

  /// No description provided for @morePaths.
  ///
  /// In en, this message translates to:
  /// **'MORE PATHS'**
  String get morePaths;

  /// No description provided for @plusTenXp.
  ///
  /// In en, this message translates to:
  /// **'+10 XP'**
  String get plusTenXp;

  /// No description provided for @strokeOrderHint.
  ///
  /// In en, this message translates to:
  /// **'Watch the stroke flow and then switch to Tracing mode to replicate it.'**
  String get strokeOrderHint;

  /// No description provided for @traceAccuracy.
  ///
  /// In en, this message translates to:
  /// **'{feedback}  Accuracy: {percent}%'**
  String traceAccuracy(String feedback, int percent);

  /// No description provided for @niceWork.
  ///
  /// In en, this message translates to:
  /// **'Nice!'**
  String get niceWork;

  /// No description provided for @youScoredOutOf.
  ///
  /// In en, this message translates to:
  /// **'You scored {score} out of {total}'**
  String youScoredOutOf(int score, int total);

  /// No description provided for @percentFormat.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String percentFormat(int percent);

  /// No description provided for @backLabel.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// No description provided for @quizKeyboardHint.
  ///
  /// In en, this message translates to:
  /// **'Arrow keys to navigate  •  1-4 to select  •  Enter ↵ to submit'**
  String get quizKeyboardHint;

  /// No description provided for @scoreOnly.
  ///
  /// In en, this message translates to:
  /// **'{score}'**
  String scoreOnly(int score);

  /// No description provided for @pressEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter ↵'**
  String get pressEnter;

  /// No description provided for @readyToTestYourself.
  ///
  /// In en, this message translates to:
  /// **'Ready to test yourself?'**
  String get readyToTestYourself;

  /// No description provided for @takeTheQuiz.
  ///
  /// In en, this message translates to:
  /// **'TAKE THE QUIZ'**
  String get takeTheQuiz;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @browseView.
  ///
  /// In en, this message translates to:
  /// **'BROWSE VIEW'**
  String get browseView;

  /// No description provided for @openDictionary.
  ///
  /// In en, this message translates to:
  /// **'Open Dictionary'**
  String get openDictionary;

  /// No description provided for @learnLabel.
  ///
  /// In en, this message translates to:
  /// **'LEARN'**
  String get learnLabel;

  /// No description provided for @doneLabel.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get doneLabel;

  /// No description provided for @lockedForNowTitle.
  ///
  /// In en, this message translates to:
  /// **'HOLD ON • LOCKED FOR NOW'**
  String get lockedForNowTitle;

  /// No description provided for @completeBlockerFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete “{blocker}” first to crack it open.'**
  String completeBlockerFirst(String blocker);

  /// No description provided for @interactiveHtmlTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactive HTML Content'**
  String get interactiveHtmlTitle;

  /// No description provided for @interactiveHtmlBody.
  ///
  /// In en, this message translates to:
  /// **'This lesson contains an interactive HTML experience. Tap below to launch it.'**
  String get interactiveHtmlBody;

  /// No description provided for @openInteractiveContent.
  ///
  /// In en, this message translates to:
  /// **'Open Interactive Content'**
  String get openInteractiveContent;

  /// No description provided for @recommendedLabel.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED'**
  String get recommendedLabel;

  /// No description provided for @audioPlaybackHint.
  ///
  /// In en, this message translates to:
  /// **'Press Space to play audio • ← → to navigate'**
  String get audioPlaybackHint;

  /// No description provided for @finishReviewing.
  ///
  /// In en, this message translates to:
  /// **'FINISH REVIEWING'**
  String get finishReviewing;

  /// No description provided for @takeQuizNow.
  ///
  /// In en, this message translates to:
  /// **'Take Quiz Now'**
  String get takeQuizNow;

  /// No description provided for @stepOfTotal.
  ///
  /// In en, this message translates to:
  /// **'STEP {step} OF {total}'**
  String stepOfTotal(int step, int total);

  /// No description provided for @checkConnectionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get checkConnectionPeriod;

  /// No description provided for @sentencePronunciation.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation: {pronunciation}'**
  String sentencePronunciation(String pronunciation);

  /// No description provided for @santaliLearner.
  ///
  /// In en, this message translates to:
  /// **'SANTALI LEARNER'**
  String get santaliLearner;

  /// No description provided for @streakTip.
  ///
  /// In en, this message translates to:
  /// **'Finish 3 lessons to keep your streak alive.'**
  String get streakTip;

  /// No description provided for @continueLearningArrow.
  ///
  /// In en, this message translates to:
  /// **'Continue learning →'**
  String get continueLearningArrow;

  /// No description provided for @olitun2.
  ///
  /// In en, this message translates to:
  /// **'Olitun'**
  String get olitun2;

  /// No description provided for @santaliOlChikiTag.
  ///
  /// In en, this message translates to:
  /// **'SANTALI • OL CHIKI'**
  String get santaliOlChikiTag;

  /// No description provided for @menuLabel.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menuLabel;

  /// No description provided for @olitunPwaVersion.
  ///
  /// In en, this message translates to:
  /// **'Olitun PWA • v2.4'**
  String get olitunPwaVersion;

  /// No description provided for @onboardingCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} · {total}'**
  String onboardingCounter(String current, String total);

  /// No description provided for @goalsTitle.
  ///
  /// In en, this message translates to:
  /// **'What are your learning goals?'**
  String get goalsTitle;

  /// No description provided for @goalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply to personalize your learning experience.'**
  String get goalsSubtitle;

  /// No description provided for @requiredLabel.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get requiredLabel;

  /// No description provided for @stepOneOfFive.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 5'**
  String get stepOneOfFive;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your mother tongue. We will use this language to explain Ol Chiki letters, word meanings, and audio lessons.'**
  String get languageSubtitle;

  /// No description provided for @prefsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save your preferences. Please try again.'**
  String get prefsSaveFailed;

  /// No description provided for @selectMotherTongueToast.
  ///
  /// In en, this message translates to:
  /// **'Please select your mother tongue / teaching language to continue.'**
  String get selectMotherTongueToast;

  /// No description provided for @onboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Learn Ol Chiki,\\none step at a time'**
  String get onboardingHeadline;

  /// No description provided for @familiarityTitle.
  ///
  /// In en, this message translates to:
  /// **'How familiar are you with Ol Chiki?'**
  String get familiarityTitle;

  /// No description provided for @familiaritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will tailor your learning path accordingly.'**
  String get familiaritySubtitle;

  /// No description provided for @displayTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to see content?'**
  String get displayTitle;

  /// No description provided for @displaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred script display. You can change this anytime.'**
  String get displaySubtitle;

  /// No description provided for @practiceGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'How much do you want to practice?'**
  String get practiceGoalTitle;

  /// No description provided for @practiceGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Setting a small daily goal helps build a continuous learning streak.'**
  String get practiceGoalSubtitle;

  /// No description provided for @olitunWordmark.
  ///
  /// In en, this message translates to:
  /// **'OLITUN'**
  String get olitunWordmark;

  /// No description provided for @learnOlChiki.
  ///
  /// In en, this message translates to:
  /// **'LEARN OL CHIKI'**
  String get learnOlChiki;

  /// No description provided for @spaceKey.
  ///
  /// In en, this message translates to:
  /// **'SPACE'**
  String get spaceKey;

  /// No description provided for @practicedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Practiced Successfully'**
  String get practicedSuccessfully;

  /// No description provided for @revealAndContinue.
  ///
  /// In en, this message translates to:
  /// **'REVEAL & CONTINUE'**
  String get revealAndContinue;

  /// No description provided for @systemDiagnosticsTitle.
  ///
  /// In en, this message translates to:
  /// **'System Diagnostics & Health'**
  String get systemDiagnosticsTitle;

  /// No description provided for @systemDiagnosticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anonymized runtime performance & diagnostic telemetry'**
  String get systemDiagnosticsSubtitle;

  /// No description provided for @diagnosticPayloadPreview.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Payload Preview'**
  String get diagnosticPayloadPreview;

  /// No description provided for @diagnosticPayloadCopied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic payload copied to clipboard!'**
  String get diagnosticPayloadCopied;

  /// No description provided for @diagnosticsTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View runtime health, memory state & anonymized telemetry'**
  String get diagnosticsTileSubtitle;

  /// No description provided for @deleteAllDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads?'**
  String get deleteAllDownloadsTitle;

  /// No description provided for @deleteAllDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every offline story audio clip from this device. Stories will stream again when you are back online.'**
  String get deleteAllDownloadsBody;

  /// No description provided for @editYourName.
  ///
  /// In en, this message translates to:
  /// **'Edit Your Name'**
  String get editYourName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @indigenousLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Indigenous Languages Platform'**
  String get indigenousLanguagesTitle;

  /// No description provided for @indigenousLanguagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore native scripts & tribal languages of eastern India'**
  String get indigenousLanguagesSubtitle;

  /// No description provided for @packsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} content & audio packs are coming soon!'**
  String packsComingSoon(String name);

  /// No description provided for @learningLanguageSetTo.
  ///
  /// In en, this message translates to:
  /// **'Learning language set to {name} ({script})'**
  String learningLanguageSetTo(String name, String script);

  /// No description provided for @audioPack.
  ///
  /// In en, this message translates to:
  /// **'Audio Pack'**
  String get audioPack;

  /// No description provided for @offlineLessons.
  ///
  /// In en, this message translates to:
  /// **'Offline Lessons'**
  String get offlineLessons;

  /// No description provided for @lettersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} letters'**
  String lettersCount(int count);

  /// No description provided for @demoLabel.
  ///
  /// In en, this message translates to:
  /// **'DEMO'**
  String get demoLabel;

  /// No description provided for @masteryAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {percent}%'**
  String masteryAccuracy(int percent);

  /// No description provided for @masteryProgression.
  ///
  /// In en, this message translates to:
  /// **'Mastery Progression'**
  String get masteryProgression;

  /// No description provided for @nextMilestone.
  ///
  /// In en, this message translates to:
  /// **'NEXT MILESTONE'**
  String get nextMilestone;

  /// No description provided for @roadToLevel.
  ///
  /// In en, this message translates to:
  /// **'Road to {level}'**
  String roadToLevel(String level);

  /// No description provided for @badgeUnlockHint.
  ///
  /// In en, this message translates to:
  /// **'To unlock the {name} badge: {target}'**
  String badgeUnlockHint(String name, String target);

  /// No description provided for @closestBadge.
  ///
  /// In en, this message translates to:
  /// **'Closest Badge Achievement'**
  String get closestBadge;

  /// No description provided for @unlockBadge.
  ///
  /// In en, this message translates to:
  /// **'Unlock the {name} Badge'**
  String unlockBadge(String name);

  /// No description provided for @reminderFrequency.
  ///
  /// In en, this message translates to:
  /// **'Reminder Frequency'**
  String get reminderFrequency;

  /// No description provided for @reminderFrequencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how often you would like to be reminded to practice Ol Chiki.'**
  String get reminderFrequencySubtitle;

  /// No description provided for @dailySchedulePreview.
  ///
  /// In en, this message translates to:
  /// **'Daily Schedule Preview'**
  String get dailySchedulePreview;

  /// No description provided for @sendTestNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Test Notification'**
  String get sendTestNotification;

  /// No description provided for @chooseYourAvatarLower.
  ///
  /// In en, this message translates to:
  /// **'Choose your avatar'**
  String get chooseYourAvatarLower;

  /// No description provided for @avatarAnimationsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load avatar animations.'**
  String get avatarAnimationsFailed;

  /// No description provided for @tryAgainLower.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainLower;

  /// No description provided for @avatarSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save avatar. Please try again.'**
  String get avatarSaveFailed;

  /// No description provided for @since.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String since(String date);

  /// No description provided for @overallProgress.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get overallProgress;

  /// No description provided for @noBookingsFound.
  ///
  /// In en, this message translates to:
  /// **'No bookings found'**
  String get noBookingsFound;

  /// No description provided for @bookingsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Book verified reciters for your ceremonies under the Bakhed tab.'**
  String get bookingsEmptyHint;

  /// No description provided for @waitlistBookingsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load waitlist bookings.'**
  String get waitlistBookingsFailed;

  /// No description provided for @assessmentScore.
  ///
  /// In en, this message translates to:
  /// **'Assessment Score'**
  String get assessmentScore;

  /// No description provided for @avgLabel.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avgLabel;

  /// No description provided for @adPrivacyRegionNote.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy settings are not required for your region.'**
  String get adPrivacyRegionNote;

  /// No description provided for @signOutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out of your account on this device?'**
  String get signOutConfirmBody;

  /// No description provided for @learningLanguageScript.
  ///
  /// In en, this message translates to:
  /// **'Learning Language & Script'**
  String get learningLanguageScript;

  /// No description provided for @mistakeReview.
  ///
  /// In en, this message translates to:
  /// **'Mistake Review'**
  String get mistakeReview;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// No description provided for @noMistakesToReview.
  ///
  /// In en, this message translates to:
  /// **'No mistakes need review. Your Santali roots are strong!'**
  String get noMistakesToReview;

  /// No description provided for @mistakesMastered.
  ///
  /// In en, this message translates to:
  /// **'Mistakes Mastered!'**
  String get mistakesMastered;

  /// No description provided for @moreQuizzes.
  ///
  /// In en, this message translates to:
  /// **'MORE QUIZZES'**
  String get moreQuizzes;

  /// No description provided for @challengeYourself.
  ///
  /// In en, this message translates to:
  /// **'CHALLENGE YOURSELF'**
  String get challengeYourself;

  /// No description provided for @chooseAQuiz.
  ///
  /// In en, this message translates to:
  /// **'Choose a Quiz'**
  String get chooseAQuiz;

  /// No description provided for @noQuizzesYet.
  ///
  /// In en, this message translates to:
  /// **'No quizzes yet!'**
  String get noQuizzesYet;

  /// No description provided for @completeLessonsFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete some lessons first'**
  String get completeLessonsFirst;

  /// No description provided for @quizUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Quiz unavailable'**
  String get quizUnavailable;

  /// No description provided for @quizUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'Quiz unavailable — this lesson does not contain enough valid questions yet.'**
  String get quizUnavailableDetail;

  /// No description provided for @quizLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the quiz.'**
  String get quizLoadFailed;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation: \"{text}\"'**
  String translation(String text);

  /// No description provided for @audioNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio is not available for this question.'**
  String get audioNotAvailable;

  /// No description provided for @mistakeReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'MISTAKE REVIEW'**
  String get mistakeReviewBadge;

  /// No description provided for @takesTwoMin.
  ///
  /// In en, this message translates to:
  /// **'Takes 2 min'**
  String get takesTwoMin;

  /// No description provided for @mistakesQuote.
  ///
  /// In en, this message translates to:
  /// **'“Mistakes are just lessons asking for a second chance.”'**
  String get mistakesQuote;

  /// No description provided for @quizKeyboardHintAlt.
  ///
  /// In en, this message translates to:
  /// **'↑ / ↓ Navigate  •  1-4 Choose  •  Enter ↵ Submit'**
  String get quizKeyboardHintAlt;

  /// No description provided for @watchAdBonusStars.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad for +50 Bonus Stars'**
  String get watchAdBonusStars;

  /// No description provided for @shareAchievement.
  ///
  /// In en, this message translates to:
  /// **'Share Achievement'**
  String get shareAchievement;

  /// No description provided for @bonusStarsEarned.
  ///
  /// In en, this message translates to:
  /// **'Bonus 50 Stars Earned! ⭐'**
  String get bonusStarsEarned;

  /// No description provided for @rewardedAdCooldown.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad is cooling down. Try again later.'**
  String get rewardedAdCooldown;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @accuracyLabel.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracyLabel;

  /// No description provided for @starsEarned.
  ///
  /// In en, this message translates to:
  /// **'Stars Earned'**
  String get starsEarned;

  /// No description provided for @maxCombo.
  ///
  /// In en, this message translates to:
  /// **'Max Combo'**
  String get maxCombo;

  /// No description provided for @reviewMistakes.
  ///
  /// In en, this message translates to:
  /// **'Review Mistakes'**
  String get reviewMistakes;

  /// No description provided for @reviewMistakesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review what you got incorrect to build your mastery! Laha se!'**
  String get reviewMistakesSubtitle;

  /// No description provided for @correctColon.
  ///
  /// In en, this message translates to:
  /// **'Correct:'**
  String get correctColon;

  /// No description provided for @correctAnswerColon.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer:'**
  String get correctAnswerColon;

  /// No description provided for @insightGuidance.
  ///
  /// In en, this message translates to:
  /// **'Insight & Guidance:'**
  String get insightGuidance;

  /// No description provided for @selectMissingWord.
  ///
  /// In en, this message translates to:
  /// **'Select the missing word:'**
  String get selectMissingWord;

  /// No description provided for @questionsWithLevel.
  ///
  /// In en, this message translates to:
  /// **'{count} questions • {level}'**
  String questionsWithLevel(int count, String level);

  /// No description provided for @startQuiz.
  ///
  /// In en, this message translates to:
  /// **'START QUIZ'**
  String get startQuiz;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionsCount(int count);

  /// No description provided for @outOfHearts.
  ///
  /// In en, this message translates to:
  /// **'Out of Hearts!'**
  String get outOfHearts;

  /// No description provided for @outOfHeartsSummary.
  ///
  /// In en, this message translates to:
  /// **'You answered {score}/{total} correctly and earned {stars} stars so far. Keep practicing to build your strength!'**
  String outOfHeartsSummary(int score, int total, int stars);

  /// No description provided for @watchAdRefillHearts.
  ///
  /// In en, this message translates to:
  /// **'Watch Ad to Refill Hearts (Free)'**
  String get watchAdRefillHearts;

  /// No description provided for @backToQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Back to Quizzes'**
  String get backToQuizzes;

  /// No description provided for @heartsRefilled.
  ///
  /// In en, this message translates to:
  /// **'Hearts Refilled! ❤️❤️❤️'**
  String get heartsRefilled;

  /// No description provided for @rewardedAdCooldownReset.
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad is cooling down. Please try regular reset.'**
  String get rewardedAdCooldownReset;

  /// No description provided for @currentOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String currentOfTotal(int current, int total);

  /// No description provided for @rhymesEndNote.
  ///
  /// In en, this message translates to:
  /// **'That\'s everything here — new Bakhed coming soon!'**
  String get rhymesEndNote;

  /// No description provided for @rhymesLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the rhymes list.'**
  String get rhymesLoadFailed;

  /// No description provided for @bakhedPreparing.
  ///
  /// In en, this message translates to:
  /// **'Bakhed are being prepared'**
  String get bakhedPreparing;

  /// No description provided for @bakhedPreparingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New listening stories will appear here after publishing.'**
  String get bakhedPreparingSubtitle;

  /// No description provided for @failedToJoinWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Failed to join waitlist: {error}'**
  String failedToJoinWaitlist(String error);

  /// No description provided for @waitlistJoined.
  ///
  /// In en, this message translates to:
  /// **'Waitlist Joined! 🎉'**
  String get waitlistJoined;

  /// No description provided for @waitlistJoinedBody.
  ///
  /// In en, this message translates to:
  /// **'Thank you for submitting your details. Our cultural coordination team will contact you shortly via phone/WhatsApp to match you with a certified Binti Guru.'**
  String get waitlistJoinedBody;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get great;

  /// No description provided for @joinBintiGuruWaitlist.
  ///
  /// In en, this message translates to:
  /// **'Join Binti Guru Waitlist'**
  String get joinBintiGuruWaitlist;

  /// No description provided for @bintiGuruFormSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your ceremony. We will search for available certified reciters.'**
  String get bintiGuruFormSubtitle;

  /// No description provided for @submitWaitlistEntry.
  ///
  /// In en, this message translates to:
  /// **'Submit Waitlist Entry'**
  String get submitWaitlistEntry;

  /// No description provided for @bookVerifiedBintiGuru.
  ///
  /// In en, this message translates to:
  /// **'Book a Verified Binti Guru'**
  String get bookVerifiedBintiGuru;

  /// No description provided for @bintiGuruLandingBody.
  ///
  /// In en, this message translates to:
  /// **'Binti is the sacred act of Santali recitation. Whether for Karam, Sohrai, Baha, weddings, or naming ceremonies, connect with certified, premium Binti reciters who preserve our cultural heritage.'**
  String get bintiGuruLandingBody;

  /// No description provided for @joinWaitlistNow.
  ///
  /// In en, this message translates to:
  /// **'Join waitlist now'**
  String get joinWaitlistNow;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'HOW IT WORKS'**
  String get howItWorks;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// No description provided for @ctrlEnterCreate.
  ///
  /// In en, this message translates to:
  /// **'Ctrl+Enter ↵ to create'**
  String get ctrlEnterCreate;

  /// No description provided for @charCount.
  ///
  /// In en, this message translates to:
  /// **'{current} / {max}'**
  String charCount(int current, int max);

  /// No description provided for @svgLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load SVG animation'**
  String get svgLoadFailed;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @shareCardTagline.
  ///
  /// In en, this message translates to:
  /// **'OLITUN • ᱚᱞ ᱪᱤᱠᱤ'**
  String get shareCardTagline;

  /// No description provided for @shareCardFooter.
  ///
  /// In en, this message translates to:
  /// **'Learn Santali (Ol Chiki) • olitun.app'**
  String get shareCardFooter;

  /// No description provided for @shareTextCopied.
  ///
  /// In en, this message translates to:
  /// **'Share text copied to clipboard! 📋'**
  String get shareTextCopied;

  /// No description provided for @tracingPracticeGlyph.
  ///
  /// In en, this message translates to:
  /// **'Tracing practice — {glyph}'**
  String tracingPracticeGlyph(String glyph);

  /// No description provided for @mastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery: {current}/{required}'**
  String mastery(int current, int required);

  /// No description provided for @onboardingStepsBody.
  ///
  /// In en, this message translates to:
  /// **'Start with letters, build words, practice with quizzes, and keep your Santali learning journey alive.'**
  String get onboardingStepsBody;

  /// No description provided for @practiceModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Practice • {mode}'**
  String practiceModeLabel(String mode);

  /// No description provided for @greatJobTakeQuiz.
  ///
  /// In en, this message translates to:
  /// **'Great job! Take \"{title}\" now to test your knowledge.'**
  String greatJobTakeQuiz(String title);

  /// No description provided for @wordsNeedPractice.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} word needs practice} other{{count} words need practice}}'**
  String wordsNeedPractice(int count);

  /// No description provided for @voiceClipMeta.
  ///
  /// In en, this message translates to:
  /// **'{voice} • {style}{instant}'**
  String voiceClipMeta(String voice, String style, String instant);

  /// No description provided for @continueWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with Email'**
  String get continueWithEmail;

  /// No description provided for @exploreAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Explore as Guest'**
  String get exploreAsGuest;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @guestSessionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start a guest session. Please try again.'**
  String get guestSessionFailed;

  /// No description provided for @couldNotLoadLessons.
  ///
  /// In en, this message translates to:
  /// **'Could not load lessons'**
  String get couldNotLoadLessons;

  /// No description provided for @shareMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Share message copied to clipboard! 📋'**
  String get shareMessageCopied;

  /// No description provided for @shareMilestoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Your Milestone'**
  String get shareMilestoneTitle;

  /// No description provided for @shareMilestoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Inspire others to learn Santali & Ol Chiki'**
  String get shareMilestoneSubtitle;

  /// No description provided for @copyTextSummary.
  ///
  /// In en, this message translates to:
  /// **'Copy Text Summary'**
  String get copyTextSummary;

  /// No description provided for @traceGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Trace the character guidelines accurately'**
  String get traceGuidelines;

  /// No description provided for @showExample.
  ///
  /// In en, this message translates to:
  /// **'Show example'**
  String get showExample;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @finishLesson.
  ///
  /// In en, this message translates to:
  /// **'Finish Lesson'**
  String get finishLesson;

  /// No description provided for @couldNotOpenShareSheet.
  ///
  /// In en, this message translates to:
  /// **'Could not open share sheet'**
  String get couldNotOpenShareSheet;

  /// No description provided for @couldNotClearDownloads.
  ///
  /// In en, this message translates to:
  /// **'Could not clear downloads'**
  String get couldNotClearDownloads;

  /// No description provided for @progressLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Your saved progress is still safe. Try refreshing this view.'**
  String get progressLoadFailed;

  /// No description provided for @couldNotLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'Could not load progress'**
  String get couldNotLoadProgress;

  /// No description provided for @couldNotLoadQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Could not load quizzes'**
  String get couldNotLoadQuizzes;

  /// No description provided for @contentLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Content could not be loaded. Please try again.'**
  String get contentLoadFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'hi', 'or', 'sat'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'or':
      return AppLocalizationsOr();
    case 'sat':
      return AppLocalizationsSat();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
