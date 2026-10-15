import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/payments/razorpay_launcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('razorpay_flutter');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Map<String, dynamic>? openedWith;

  void answerOpenWith(Map<String, dynamic> response) {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'open') {
        openedWith = Map<String, dynamic>.from(call.arguments as Map);
        return response;
      }
      return null; // resync: nothing lost
    });
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const request = RazorpayCheckoutRequest(
    keyId: 'rzp_test_key',
    orderId: 'order_A1',
    amountInPaise: 14900,
    currency: 'INR',
    description: 'Everyday Phrases',
  );

  test('success returns the fields the Worker verifies', () async {
    answerOpenWith({
      'type': 0,
      'data': {
        'razorpay_payment_id': 'pay_B2',
        'razorpay_order_id': 'order_A1',
        'razorpay_signature': 'sig_C3',
      },
    });

    final result = await PluginRazorpayLauncher().open(request);

    expect(result, isA<RazorpayCheckoutSuccess>());
    final success = result as RazorpayCheckoutSuccess;
    expect(success.orderId, 'order_A1');
    expect(success.paymentId, 'pay_B2');
    expect(success.signature, 'sig_C3');
    expect(openedWith?['order_id'], 'order_A1');
    expect(openedWith?['amount'], 14900);
    expect(openedWith?['key'], 'rzp_test_key');
    expect(openedWith?.containsKey('prefill'), isFalse);
  });

  test('user cancel maps to cancelled', () async {
    answerOpenWith({
      'type': 1,
      'data': {'code': 2, 'message': 'Payment cancelled'},
    });
    expect(
      await PluginRazorpayLauncher().open(request),
      isA<RazorpayCheckoutCancelled>(),
    );
  });

  test('network and other errors map to failed', () async {
    answerOpenWith({
      'type': 1,
      'data': {'code': 0, 'message': 'offline'},
    });
    final network = await PluginRazorpayLauncher().open(request);
    expect((network as RazorpayCheckoutFailed).isNetworkError, isTrue);

    answerOpenWith({
      'type': 2,
      'data': {'external_wallet': 'paytm'},
    });
    final wallet = await PluginRazorpayLauncher().open(request);
    expect((wallet as RazorpayCheckoutFailed).isNetworkError, isFalse);
  });
}
