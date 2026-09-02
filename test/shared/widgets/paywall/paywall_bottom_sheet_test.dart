import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/app_settings_provider.dart';
import 'package:itun/shared/providers/purchases_provider.dart';
import 'package:itun/shared/widgets/paywall/paywall_action_section.dart';
import 'package:itun/shared/widgets/paywall/paywall_course_details.dart';
import 'package:itun/shared/widgets/paywall/paywall_header.dart';
import 'package:itun/shared/widgets/paywall/paywall_success_dialog.dart';
import 'package:itun/shared/widgets/paywall/paywall_value_props.dart';
import 'package:itun/shared/widgets/paywall_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_paywall_test_');
    Hive.init(tempDir.path);
  });

  MaterialApp l10nApp({required Widget child}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  const testCategory = CategoryEntity(
    id: 'cat_advanced_grammar',
    titleLatin: 'Advanced Ol Chiki Grammar',
    titleOlChiki: 'ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱱᱚᱲ',
    description: 'Master complex Ol Chiki sentence structures and phonetics.',
    courseDescription:
        'In-depth comprehensive course on Ol Chiki linguistic rules.',
    courseOutcome:
        'Read, write, and converse fluently with authentic script mastery.',
    priceInr: 299,
    unlockMode: 'review_or_paid',
    order: 1,
  );

  group('Paywall Components & Modular Layout Tests', () {
    testWidgets('PaywallHeader renders title, Ol Chiki script, and badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        l10nApp(
          child: const Scaffold(
            body: PaywallHeader(category: testCategory, isDark: false),
          ),
        ),
      );

      expect(find.text('PREMIUM COURSE'), findsOneWidget);
      expect(find.text('Advanced Ol Chiki Grammar'), findsOneWidget);
      expect(find.text('ᱥᱟᱱᱛᱟᱲᱤ ᱨᱚᱱᱚᱲ'), findsOneWidget);
    });

    testWidgets('PaywallCourseDetails renders description and outcome', (
      tester,
    ) async {
      await tester.pumpWidget(
        l10nApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: PaywallCourseDetails(
                category: testCategory,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('About this course'), findsOneWidget);
      expect(
        find.text(
          'In-depth comprehensive course on Ol Chiki linguistic rules.',
        ),
        findsOneWidget,
      );
      expect(find.text('Course Outcome'), findsOneWidget);
      expect(
        find.text(
          'Read, write, and converse fluently with authentic script mastery.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('PaywallValueProps renders all key value propositions', (
      tester,
    ) async {
      await tester.pumpWidget(
        l10nApp(
          child: const Scaffold(
            body: SingleChildScrollView(
              child: PaywallValueProps(isDark: false),
            ),
          ),
        ),
      );

      expect(find.text('Full Offline Pack Access'), findsOneWidget);
      expect(find.text('Unlimited AI Translations'), findsOneWidget);
      expect(find.text('Zero Ad Interruptions'), findsOneWidget);
      expect(find.text('Lifetime Access Guarantee'), findsOneWidget);
    });

    testWidgets('PaywallActionSection renders paid button; review-for-unlock '
        'is removed', (tester) async {
      var payTapped = false;

      await tester.pumpWidget(
        l10nApp(
          child: Scaffold(
            body: PaywallActionSection(
              category: testCategory,
              isLoading: false,
              showPaidButton: true,
              onPayPressed: () => payTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Unlock Course (₹299)'), findsOneWidget);
      expect(
        find.text('256-bit encrypted checkout via Razorpay • Instant access'),
        findsOneWidget,
      );
      // The incentivized review-for-unlock CTA is gone (Play policy risk).
      expect(find.text('Rate & Share Feedback'), findsNothing);

      await tester.tap(find.text('Unlock Course (₹299)'));
      expect(payTapped, isTrue);
    });

    testWidgets('PaywallSuccessDialog renders and handles start learning CTA', (
      tester,
    ) async {
      var started = false;

      await tester.pumpWidget(
        l10nApp(
          child: Scaffold(
            body: PaywallSuccessDialog(
              message: 'Your course has been unlocked successfully!',
              onStartLearning: () => started = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Maran Jauhar! 🎉'), findsOneWidget);
      expect(
        find.text('Your course has been unlocked successfully!'),
        findsOneWidget,
      );

      await tester.tap(find.text('Start Learning'));
      expect(started, isTrue);
    });
  });

  group('PaywallBottomSheet Coordinator State Machine Tests', () {
    testWidgets(
      'PaywallBottomSheet mounts cleanly and alerts unauthenticated user on checkout',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserProvider.overrideWith((ref) => null),
              appSettingsProvider.overrideWith(
                (ref) => Future.value({'global_review_unlock_enabled': 'true'}),
              ),
              purchasedCategoriesProvider.overrideWith(
                (ref) => Future.value(<String>{}),
              ),
            ],
            child: l10nApp(
              child: const Scaffold(
                body: PaywallBottomSheet(category: testCategory),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Advanced Ol Chiki Grammar'), findsOneWidget);
        expect(find.text('Unlock Course (₹299)'), findsOneWidget);

        // Tap checkout as unauthenticated user
        await tester.ensureVisible(find.text('Unlock Course (₹299)'));
        await tester.tap(find.text('Unlock Course (₹299)'));
        await tester.pump();

        expect(find.text('Please log in to purchase courses.'), findsOneWidget);
      },
    );

    testWidgets(
      'PaywallBottomSheet shows no review CTA for paid_only or review modes',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const paidOnlyCategory = CategoryEntity(
          id: 'cat_paid_only',
          titleLatin: 'Exclusive Premium Masterclass',
          titleOlChiki: 'ᱢᱟᱥᱴᱚᱨᱠᱞᱟᱥ',
          priceInr: 499,
          unlockMode: 'paid_only',
          order: 2,
        );

        const reviewOnlyCategory = CategoryEntity(
          id: 'cat_review_only',
          titleLatin: 'Legacy Review Gated Course',
          titleOlChiki: 'ᱨᱤᱵᱷᱤᱭᱩ',
          priceInr: 199,
          unlockMode: 'review_only',
          order: 3,
        );

        Future<void> pumpCategory(
          WidgetTester tester,
          CategoryEntity category,
        ) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                currentUserProvider.overrideWith(
                  (ref) => Future.value(
                    const UserEntity(
                      id: 'user_test_123',
                      email: 'test@olitun.com',
                      name: 'Test Student',
                    ),
                  ),
                ),
                appSettingsProvider.overrideWith(
                  (ref) =>
                      Future.value({'global_review_unlock_enabled': 'true'}),
                ),
                purchasedCategoriesProvider.overrideWith(
                  (ref) => Future.value(<String>{}),
                ),
              ],
              child: l10nApp(
                child: Scaffold(body: PaywallBottomSheet(category: category)),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await pumpCategory(tester, paidOnlyCategory);
        expect(find.text('Unlock Course (₹499)'), findsOneWidget);
        expect(find.text('Rate & Share Feedback'), findsNothing);

        // Legacy review_only categories now stay paid: the unlock CTA is
        // the paid button and the review CTA never renders.
        await pumpCategory(tester, reviewOnlyCategory);
        expect(find.text('Unlock Course (₹199)'), findsOneWidget);
        expect(find.text('Rate & Share Feedback'), findsNothing);
      },
    );
  });
}
