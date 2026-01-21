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
}
