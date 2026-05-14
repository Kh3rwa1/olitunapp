import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('en'),
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
      <String>['en', 'sat'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
