import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:itun/features/auth/domain/entities/user_entity.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
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
        const MaterialApp(
          home: Scaffold(
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
        const MaterialApp(
          home: Scaffold(
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
        const MaterialApp(
          home: Scaffold(
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

    testWidgets('PaywallActionSection renders paid and review buttons', (
      tester,
    ) async {
      var payTapped = false;
      var reviewTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PaywallActionSection(
              category: testCategory,
              isLoading: false,
              showPaidButton: true,
              showReviewButton: true,
              onPayPressed: () => payTapped = true,
              onReviewPressed: () => reviewTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Unlock Course (₹299)'), findsOneWidget);
      expect(find.text('Rate & Share Feedback'), findsOneWidget);
      expect(
        find.text('256-bit encrypted checkout via Razorpay • Instant access'),
        findsOneWidget,
      );

      await tester.tap(find.text('Unlock Course (₹299)'));
      expect(payTapped, isTrue);

      await tester.tap(find.text('Rate & Share Feedback'));
      expect(reviewTapped, isTrue);
    });

    testWidgets('PaywallSuccessDialog renders and handles start learning CTA', (
      tester,
    ) async {
      var started = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
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
            child: const MaterialApp(
              home: Scaffold(body: PaywallBottomSheet(category: testCategory)),
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
      'PaywallBottomSheet respects paid_only mode hiding review CTA',
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
                (ref) => Future.value({'global_review_unlock_enabled': 'true'}),
              ),
              purchasedCategoriesProvider.overrideWith(
                (ref) => Future.value(<String>{}),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: PaywallBottomSheet(category: paidOnlyCategory),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unlock Course (₹499)'), findsOneWidget);
        expect(find.text('Rate & Share Feedback'), findsNothing);
      },
    );
  });
}
