/// Single entry point for the admin CMS UI.
///
/// The router imports this library `deferred as`, so the whole admin CMS
/// (~40% of the presentation code) is split into its own load unit and only
/// downloaded on web when an `/admin` route is first visited. Everything the
/// router needs is exposed as plain functions so no admin type leaks into the
/// eagerly-loaded router code.
library;

import 'package:flutter/widgets.dart';

import 'presentation/access/admin_access_screen.dart';
import 'presentation/admin_login_screen.dart';
import 'presentation/admin_media_screen.dart';
import 'presentation/admin_settings_screen.dart';
import 'presentation/analytics/admin_analytics_screen.dart';
import 'presentation/bakhed/bakhed_editor_screen.dart';
import 'presentation/bakhed/bakhed_hub_screen.dart';
import 'presentation/banners/admin_banners_screen.dart';
import 'presentation/binti_waitlist/admin_binti_waitlist_screen.dart';
import 'presentation/categories/admin_categories_screen.dart';
import 'presentation/dashboard/admin_dashboard_screen.dart';
import 'presentation/gamification/admin_gamification_screen.dart';
import 'presentation/lessons/admin_lessons_screen.dart';
import 'presentation/lessons/content/admin_lesson_content_screen.dart';
import 'presentation/letters/admin_letters_screen.dart';
import 'presentation/numbers/admin_numbers_screen.dart';
import 'presentation/purchases/admin_purchases_screen.dart';
import 'presentation/quizzes/admin_quizzes_screen.dart';
import 'presentation/review/admin_review_screen.dart';
import 'presentation/sentences/admin_sentences_screen.dart';
import 'presentation/shell/admin_shell.dart';
import 'presentation/translations/admin_translations_screen.dart';
import 'presentation/words/admin_words_screen.dart';

Widget loginScreen() => const AdminLoginScreen();

Widget shell(Widget child) => AdminShell(child: child);

Widget dashboardScreen() => const AdminDashboardScreen();

Widget translationsScreen() => const AdminTranslationsScreen();

Widget categoriesScreen() => const AdminCategoriesScreen();

Widget bannersScreen() => const AdminBannersScreen();

Widget lettersScreen(String? categoryId) =>
    AdminLettersScreen(categoryId: categoryId);

Widget lessonsScreen(String? categoryId) =>
    AdminLessonsScreen(categoryId: categoryId);

Widget lessonContentScreen(String lessonId) =>
    AdminLessonContentScreen(lessonId: lessonId);

Widget numbersScreen(String? categoryId) =>
    AdminNumbersScreen(categoryId: categoryId);

Widget wordsScreen(String? categoryId) =>
    AdminWordsScreen(categoryId: categoryId);

Widget sentencesScreen(String? categoryId) =>
    AdminSentencesScreen(categoryId: categoryId);

Widget quizzesScreen() => const AdminQuizzesScreen();

Widget bakhedHubScreen(String? categoryId) =>
    BakhedHubScreen(categoryId: categoryId);

Widget bakhedEditorScreen(String bakhedId) =>
    BakhedEditorScreen(bakhedId: bakhedId);

/// [mediaType] is one of `all`, `image`, `audio`, `video`.
Widget mediaScreen({String mediaType = 'all'}) => AdminMediaScreen(
  initialType: MediaType.values.firstWhere(
    (type) => type.name == mediaType,
    orElse: () => MediaType.all,
  ),
);

Widget settingsScreen() => const AdminSettingsScreen();

Widget accessScreen() => const AdminAccessScreen();

Widget gamificationScreen(String section) =>
    AdminGamificationScreen(section: section);

Widget analyticsScreen() => const AdminAnalyticsScreen();

Widget purchasesScreen() => const AdminPurchasesScreen();

Widget bintiWaitlistScreen() => const AdminBintiWaitlistScreen();

Widget reviewScreen() => const AdminReviewScreen();
