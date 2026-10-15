import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/auth_providers.dart';
import 'package:itun/core/auth/user_entity.dart';
import 'package:itun/core/payments/checkout_service.dart';
import 'package:itun/core/payments/pending_verification_store.dart';
import 'package:itun/core/payments/razorpay_launcher.dart';
import 'package:itun/core/storage/hive_service.dart';

import '../../helpers/fake_checkout.dart';

void main() {
  late CheckoutHarness h;

  setUp(() async {
    h = await CheckoutHarness.create();
  });

  Future<PurchaseOutcome> buy() =>
      h.service.purchase(userId: 'u1', categoryId: 'cat_paid', email: 'a@b.c');

  test('order -> pay -> verify unlocks and refreshes entitlements', () async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('verifyCoursePurchase', 200, verifiedBody);

    expect(await buy(), PurchaseOutcome.unlocked);

    final request = h.launcher.requests.single;
    expect(request.orderId, 'order_A1');
    expect(request.amountInPaise, 14900);
    expect(request.keyId, 'rzp_test_key');
    expect(request.toOptions()['order_id'], 'order_A1');
    expect(request.toOptions()['prefill'], {'email': 'a@b.c'});
    final verifyBody = h.functions.calls.last.$2;
    expect(verifyBody, {
      'orderId': 'order_A1',
      'paymentId': 'pay_B2',
      'signature': 'sig_C3',
    });
    expect(h.refreshedUsers, ['u1']);
    expect(h.store.readAll(), isEmpty);
    expect(h.events, ['purchase_started', 'purchase_succeeded']);
  });

  test('uses a prepared order without creating another', () async {
    h.functions.enqueue('verifyCoursePurchase', 200, verifiedBody);
    final order = (await _prepare(h)).order;

    final outcome = await h.service.purchase(
      userId: 'u1',
      categoryId: 'cat_paid',
      preparedOrder: order,
    );

    expect(outcome, PurchaseOutcome.unlocked);
    expect(h.functions.callsTo('createRazorpayOrder'), 1);
  });

  test('cancelled checkout is reported and nothing is verified', () async {
    h.functions.enqueue('createRazorpayOrder', 200, orderBody());
    h.launcher.result = const RazorpayCheckoutCancelled();

    expect(await buy(), PurchaseOutcome.cancelled);
    expect(h.functions.callsTo('verifyCoursePurchase'), 0);
    expect(h.events.last, 'purchase_failed:cancelled');
  });

  test('gateway failures map to failed / networkError', () async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('createRazorpayOrder', 200, orderBody());
    h.launcher.result = const RazorpayCheckoutFailed(code: 1);
    expect(await buy(), PurchaseOutcome.failed);

    h.launcher.result = const RazorpayCheckoutFailed(isNetworkError: true);
    expect(await buy(), PurchaseOutcome.networkError);
  });

  test('verify failure keeps a pending record that is retried later', () async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('verifyCoursePurchase', 0, {'ok': false});

    expect(await buy(), PurchaseOutcome.pendingVerification);
    final pending = h.store.forUser('u1').single;
    expect(pending.orderId, 'order_A1');
    expect(pending.paymentId, 'pay_B2');
    expect(pending.signature, 'sig_C3');
    expect(h.refreshedUsers, isEmpty);
    expect(h.events.last, 'purchase_failed:pendingVerification');

    // Next app start: the Worker answers.
    h.functions.enqueue('verifyCoursePurchase', 200, verifiedBody);
    expect(await h.service.retryPendingVerifications('u1'), 1);
    expect(h.store.readAll(), isEmpty);
    expect(h.refreshedUsers, ['u1']);
    expect(h.events.last, 'purchase_succeeded:retried');
  });

  test('retry keeps transient failures and drops unknown orders', () async {
    await h.store.save(_record('order_keep'));
    await h.store.save(_record('order_gone'));
    await h.store.save(_record('order_other', userId: 'u2'));
    h.functions
      ..enqueue('verifyCoursePurchase', 503, {'ok': false})
      ..enqueue('verifyCoursePurchase', 404, {'ok': false});

    expect(await h.service.retryPendingVerifications('u1'), 0);

    expect(h.store.readAll().map((r) => r.orderId), [
      'order_keep',
      'order_other',
    ]);
  });

  test('409 already owned refreshes entitlements and reports owned', () async {
    h.functions.enqueue('createRazorpayOrder', 409, {'ok': false});

    expect(await buy(), PurchaseOutcome.alreadyOwned);
    expect(h.launcher.requests, isEmpty);
    expect(h.refreshedUsers, ['u1']);
    expect(h.events, ['purchase_started']);
  });

  test('400 free category opens; other 400s stay failed', () async {
    h.functions.enqueue('createRazorpayOrder', 400, {
      'ok': false,
      'message': 'Category is already free',
    });
    expect(await buy(), PurchaseOutcome.free);

    final other = await CheckoutHarness.create();
    other.functions.enqueue('createRazorpayOrder', 400, {
      'ok': false,
      'message': 'Invalid category price',
    });
    expect(
      await other.service.purchase(userId: 'u1', categoryId: 'cat_paid'),
      PurchaseOutcome.failed,
    );
    expect(h.launcher.requests, isEmpty);
  });

  test('503 means payments are not configured', () async {
    h.functions.enqueue('createRazorpayOrder', 503, {'ok': false});
    expect(await buy(), PurchaseOutcome.notConfigured);
  });

  test('network error and malformed orders do not open checkout', () async {
    expect(await buy(), PurchaseOutcome.networkError);
    h.functions.enqueue('createRazorpayOrder', 200, {'ok': true});
    expect(await buy(), PurchaseOutcome.failed);
    expect(h.launcher.requests, isEmpty);
  });

  test('a second purchase while one is in flight is refused', () async {
    h.functions
      ..enqueue('createRazorpayOrder', 200, orderBody())
      ..enqueue('verifyCoursePurchase', 200, verifiedBody);
    h.launcher.hold = Completer<void>();

    final first = buy();
    await Future<void>.delayed(Duration.zero);
    expect(h.service.isPurchaseInFlight, isTrue);
    expect(await buy(), PurchaseOutcome.busy);

    h.launcher.release();
    expect(await first, PurchaseOutcome.unlocked);
    expect(h.functions.callsTo('createRazorpayOrder'), 1);
    expect(h.launcher.requests, hasLength(1));
    expect(h.service.isPurchaseInFlight, isFalse);
  });

  test('order display amount', () {
    CheckoutOrder order(int paise) => CheckoutOrder(
      orderId: 'o',
      amountInPaise: paise,
      currency: 'INR',
      keyId: 'k',
      categoryId: 'c',
      categoryTitle: 't',
    );
    expect(order(14900).displayAmount, '149');
    expect(order(14950).displayAmount, '149.50');
  });

  test('pending store ignores corrupt and incomplete records', () async {
    await h.prefs.setString(PendingVerificationStore.storageKey, 'not json');
    expect(h.store.readAll(), isEmpty);
    await h.prefs.setString(
      PendingVerificationStore.storageKey,
      '[{"userId":"u1","orderId":"o"}, 3]',
    );
    expect(h.store.readAll(), isEmpty);
    await h.store.save(_record('o1'));
    await h.store.save(_record('o1'));
    expect(h.store.readAll(), hasLength(1));
    await h.store.remove('o1');
    expect(h.prefs.getString(PendingVerificationStore.storageKey), isNull);
  });

  test(
    'startup retry provider verifies pending records for the user',
    () async {
      await h.store.save(_record('order_A1'));
      h.functions.enqueue('verifyCoursePurchase', 200, verifiedBody);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(h.prefs),
          currentUserProvider.overrideWith(
            (ref) async => const UserEntity(id: 'u1', email: 'a@b.c'),
          ),
          checkoutServiceProvider.overrideWithValue(h.service),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await container.read(pendingPurchaseVerificationRetryProvider.future),
        1,
      );
      expect(h.store.readAll(), isEmpty);
    },
  );

  test('startup retry provider is a no-op when signed out', () async {
    final container = ProviderContainer(
      overrides: [currentUserProvider.overrideWith((ref) async => null)],
    );
    addTearDown(container.dispose);
    expect(
      await container.read(pendingPurchaseVerificationRetryProvider.future),
      0,
    );
  });

  test('real providers wire the service from app dependencies', () {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(h.prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(checkoutServiceProvider), isA<CheckoutService>());
    expect(
      container.read(checkoutSupportedProvider),
      isRazorpayCheckoutPlatform,
    );
  });
}

Future<OrderReady> _prepare(CheckoutHarness h) async {
  h.functions.enqueue('createRazorpayOrder', 200, orderBody());
  final outcome = await h.service.createOrder('cat_paid');
  return outcome as OrderReady;
}

PendingVerification _record(String orderId, {String userId = 'u1'}) =>
    PendingVerification(
      userId: userId,
      categoryId: 'cat_paid',
      orderId: orderId,
      paymentId: 'pay_B2',
      signature: 'sig_C3',
    );
