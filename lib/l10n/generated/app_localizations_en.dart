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
}
