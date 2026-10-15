import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/core/auth/user_entity.dart';
import 'package:itun/core/payments/checkout_service.dart';
import 'package:itun/core/payments/razorpay_launcher.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/catalog/category_entity.dart';
import 'package:itun/shared/models/catalog/lesson_entity.dart';
import 'package:itun/shared/widgets/paywall/paywall_bottom_sheet.dart';

import '../../../helpers/fake_checkout.dart';

const paidCategory = CategoryEntity(
  id: 'cat_paid',
  titleOlChiki: 'ᱡᱚᱦᱟᱨ',
  titleLatin: 'Everyday Phrases',
  unlockMode: 'paid_only',
  priceInr: 99,
  totalLessons: 12,
  courseDescription: 'Greetings, market talk and family words.',
);

const freeCategory = CategoryEntity(
  id: 'cat_free',
  titleOlChiki: 'ᱚᱞ',
  titleLatin: 'Alphabet',
);

const member = UserEntity(id: 'u1', email: 'mina@example.com');
const anonymous = UserEntity(id: 'anon1', email: '');

void main() {
  late CheckoutHarness h;
  PaywallResult? result;

  setUp(() async {
    h = await CheckoutHarness.create();
    result = null;
  });

  Future<void> openPaywall(
    WidgetTester tester, {
    UserEntity? user = member,
    bool supported = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkoutServiceProvider.overrideWithValue(h.service),
          checkoutSupportedProvider.overrideWithValue(supported),
          currentUserProvider.overrideWith((ref) async => user),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await PaywallBottomSheet.show(
                    context,
                    category: paidCategory,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder unlockButton() => find.byKey(const Key('paywall-unlock'));

  Future<void> tapUnlock(WidgetTester tester) async {
    await tester.ensureVisible(unlockButton());
    await tester.tap(unlockButton());
    await tester.pumpAndSettle();
  }

  testWidgets('shows course, server price, and unlocks after verify', (
    tester,
  ) async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody(amount: 19900))
      ..enqueue('verifyCoursePurchase', 200, verifiedBody);
    await openPaywall(tester);

    expect(find.text('Everyday Phrases'), findsOneWidget);
    expect(find.text('12 lessons'), findsOneWidget);
    // Price comes from the order response, not the cached category.
    expect(find.text('Unlock Course (₹199)'), findsOneWidget);
    expect(h.events, ['paywall_viewed']);

    await tapUnlock(tester);

    expect(h.launcher.requests.single.orderId, 'order_A1');
    expect(h.functions.callsTo('createRazorpayOrder'), 1);
    expect(find.text('Course successfully unlocked!'), findsOneWidget);
    expect(h.refreshedUsers, ['u1']);

    await tester.tap(find.byKey(const Key('paywall-start-learning')));
    await tester.pumpAndSettle();
    expect(result, PaywallResult.unlocked);
  });

  testWidgets('cancel keeps the paywall open with a retryable notice', (
    tester,
  ) async {
    h.functions.enqueue('createRazorpayOrder', 200, orderBody());
    h.launcher.result = const RazorpayCheckoutCancelled();
    await openPaywall(tester);

    await tapUnlock(tester);

    expect(
      find.text('Payment cancelled. You can try again anytime.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ElevatedButton>(
            find.descendant(
              of: unlockButton(),
              matching: find.byType(ElevatedButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
    expect(h.functions.callsTo('verifyCoursePurchase'), 0);
  });

  testWidgets('verify failure shows the pending message and keeps a record', (
    tester,
  ) async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('verifyCoursePurchase', 502, {'ok': false});
    await openPaywall(tester);

    await tapUnlock(tester);

    expect(
      find.text('Payment received. We\'ll confirm your unlock shortly.'),
      findsOneWidget,
    );
    expect(h.store.forUser('u1').single.paymentId, 'pay_B2');
  });

  testWidgets('409 already owned closes as unlocked', (tester) async {
    h.functions.enqueue('createRazorpayOrder', 409, {'ok': false});
    await openPaywall(tester);

    expect(find.byType(PaywallBottomSheet), findsNothing);
    expect(result, PaywallResult.unlocked);
    expect(h.refreshedUsers, ['u1']);
    expect(h.launcher.requests, isEmpty);
  });

  testWidgets('400 free category just opens', (tester) async {
    h.functions.enqueue('createRazorpayOrder', 400, {
      'ok': false,
      'message': 'Category is already free',
    });
    await openPaywall(tester);

    expect(result, PaywallResult.unlocked);
    expect(h.launcher.requests, isEmpty);
  });

  testWidgets('503 shows payments-unavailable and no unlock button', (
    tester,
  ) async {
    h.functions.enqueue('createRazorpayOrder', 503, {'ok': false});
    await openPaywall(tester);

    expect(
      find.text(
        'Purchases aren\'t available right now. Please try again later.',
      ),
      findsOneWidget,
    );
    expect(unlockButton(), findsNothing);
  });

  testWidgets('offline order fetch falls back to catalog price and retries', (
    tester,
  ) async {
    // No queued order: the first fetch fails like a network error.
    await openPaywall(tester);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Unlock Course (₹99)'), findsOneWidget);

    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('verifyCoursePurchase', 200, verifiedBody);
    await tapUnlock(tester);

    expect(find.text('Course successfully unlocked!'), findsOneWidget);
  });

  testWidgets('guests are asked to sign in and no order is created', (
    tester,
  ) async {
    await openPaywall(tester, user: anonymous);

    expect(find.text('Please log in to purchase courses.'), findsOneWidget);
    expect(unlockButton(), findsNothing);
    expect(h.functions.calls, isEmpty);

    await tester.tap(find.byKey(const Key('paywall-sign-in')));
    await tester.pumpAndSettle();
    expect(result, PaywallResult.signInRequested);
  });

  testWidgets('signed-out users are asked to sign in', (tester) async {
    await openPaywall(tester, user: null);
    expect(find.byKey(const Key('paywall-sign-in')), findsOneWidget);
  });

  testWidgets('unsupported platforms point to the Android app', (tester) async {
    await openPaywall(tester, supported: false);

    expect(
      find.text('Purchases are available in the Olitun Android app.'),
      findsOneWidget,
    );
    expect(h.functions.calls, isEmpty);
  });

  testWidgets('double tap creates one order and opens one checkout', (
    tester,
  ) async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('verifyCoursePurchase', 200, verifiedBody);
    h.launcher.hold = Completer<void>();
    await openPaywall(tester);

    await tester.ensureVisible(unlockButton());
    await tester.tap(unlockButton());
    await tester.tap(unlockButton(), warnIfMissed: false);
    await tester.pump();

    expect(h.launcher.requests, hasLength(1));
    h.launcher.release();
    await tester.pumpAndSettle();
    expect(h.launcher.requests, hasLength(1));
    expect(h.functions.callsTo('createRazorpayOrder'), 1);
    expect(h.functions.callsTo('verifyCoursePurchase'), 1);
  });

  group('paywall gating', () {
    const lesson = LessonEntity(
      id: 'l1',
      categoryId: 'cat_paid',
      titleOlChiki: 'ᱡᱚᱦᱟᱨ',
      titleLatin: 'Hello',
    );

    test('free categories never require purchase', () {
      expect(categoryRequiresPurchase(freeCategory, const {}), isFalse);
      expect(
        lessonRequiresPurchase(
          lesson: lesson.copyWith(categoryId: 'cat_free', isLocked: true),
          category: freeCategory,
          ownedCategoryIds: const {},
        ),
        isFalse,
      );
      expect(categoryRequiresPurchase(null, const {}), isFalse);
    });

    test('paid categories require purchase until owned', () {
      expect(categoryRequiresPurchase(paidCategory, const {}), isTrue);
      expect(
        categoryRequiresPurchase(paidCategory, const {'cat_paid'}),
        isFalse,
      );
      expect(
        lessonRequiresPurchase(
          lesson: lesson.copyWith(isPreview: true),
          category: paidCategory,
          ownedCategoryIds: const {},
        ),
        isFalse,
      );
    });

    test('anonymous sessions count as guests', () {
      expect(isGuestPurchaser(null), isTrue);
      expect(isGuestPurchaser(anonymous), isTrue);
      expect(isGuestPurchaser(member), isFalse);
    });
  });
}
