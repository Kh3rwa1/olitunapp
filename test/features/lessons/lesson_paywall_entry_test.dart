import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/core/auth/user_entity.dart';
import 'package:itun/core/payments/checkout_service.dart';
import 'package:itun/core/payments/purchased_categories_provider.dart';
import 'package:itun/core/payments/razorpay_launcher.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/presentation/category_lessons_screen.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/features/lessons/presentation/widgets/category_lessons/purchase_locked_lesson_view.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/catalog/category_entity.dart';
import 'package:itun/shared/models/catalog/lesson_entity.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/shared/widgets/paywall/paywall_bottom_sheet.dart';

import '../../helpers/fake_checkout.dart';

class _Categories extends CategoryNotifier {
  _Categories(this._items);
  final List<CategoryEntity> _items;

  @override
  List<CategoryEntity> build() => _items;
}

CategoryEntity _category({required bool paid}) => CategoryEntity(
  id: 'cat_phrases',
  titleOlChiki: 'ᱡᱚᱦᱟᱨ',
  titleLatin: 'Everyday Phrases',
  unlockMode: paid ? 'paid_only' : 'free',
  priceInr: paid ? 99 : 0,
  totalLessons: 1,
);

const _lesson = LessonEntity(
  id: 'lesson_hello',
  categoryId: 'cat_phrases',
  titleOlChiki: 'ᱡᱚᱦᱟᱨ',
  titleLatin: 'Hello',
);

void main() {
  late CheckoutHarness h;

  setUp(() async {
    h = await CheckoutHarness.create();
  });

  Future<void> pumpCategoryScreen(
    WidgetTester tester, {
    required bool paid,
    Set<String> owned = const {},
  }) async {
    final router = GoRouter(
      initialLocation: '/lessons/cat_phrases',
      routes: [
        GoRoute(
          path: '/lessons/:categoryId',
          builder: (context, state) => CategoryLessonsScreen(
            categoryId: state.pathParameters['categoryId']!,
          ),
        ),
        GoRoute(
          path: '/lesson/:lessonId',
          builder: (context, state) => Scaffold(
            body: Text('Lesson ${state.pathParameters['lessonId']}'),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(h.prefs),
          categoryNotifierProvider.overrideWith(
            () => _Categories([_category(paid: paid)]),
          ),
          lessonsByCategoryProvider(
            'cat_phrases',
          ).overrideWith((ref) => const AsyncValue.data([_lesson])),
          purchasedCategoriesProvider.overrideWith((ref) => owned),
          effectiveScriptModeProvider.overrideWith((ref) => 'latin'),
          checkoutServiceProvider.overrideWithValue(h.service),
          checkoutSupportedProvider.overrideWithValue(false),
          currentUserProvider.overrideWith(
            (ref) async => const UserEntity(id: 'u1', email: 'a@b.c'),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLesson(WidgetTester tester) async {
    final card = find.byKey(const Key('lesson-card-lesson_hello'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
  }

  testWidgets('free category: lesson opens and no paywall exists', (
    tester,
  ) async {
    await pumpCategoryScreen(tester, paid: false);
    await tapLesson(tester);

    expect(find.byType(PaywallBottomSheet), findsNothing);
    expect(find.text('Lesson lesson_hello'), findsOneWidget);
    expect(h.events, isEmpty);
    expect(h.functions.calls, isEmpty);
  });

  testWidgets('paid, not owned: tapping the lesson opens the paywall', (
    tester,
  ) async {
    await pumpCategoryScreen(tester, paid: true);
    await tapLesson(tester);

    expect(find.byType(PaywallBottomSheet), findsOneWidget);
    expect(find.text('Lesson lesson_hello'), findsNothing);
    expect(h.events, ['paywall_viewed']);
  });

  testWidgets('paid and owned: lesson opens without a paywall', (tester) async {
    await pumpCategoryScreen(tester, paid: true, owned: {'cat_phrases'});
    await tapLesson(tester);

    expect(find.byType(PaywallBottomSheet), findsNothing);
    expect(find.text('Lesson lesson_hello'), findsOneWidget);
  });

  testWidgets('lesson deep link to a paid category shows the unlock view', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(h.prefs),
          learnerLessonsProvider.overrideWithValue(
            const AsyncValue.data([_lesson]),
          ),
          categoryNotifierProvider.overrideWith(
            () => _Categories([_category(paid: true)]),
          ),
          purchasedCategoriesProvider.overrideWith((ref) => <String>{}),
          checkoutServiceProvider.overrideWithValue(h.service),
          checkoutSupportedProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_hello',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PurchaseLockedLessonView), findsOneWidget);
    expect(
      find.text(
        'This lesson is part of a paid course. Unlock the course to continue.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('purchase-locked-unlock')));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallBottomSheet), findsOneWidget);
  });
}
