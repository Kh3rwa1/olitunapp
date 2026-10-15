import 'dart:async';
import 'dart:convert';

import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/payments/checkout_service.dart';
import 'package:itun/core/payments/pending_verification_store.dart';
import 'package:itun/core/payments/razorpay_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Worker stand-in: queued (statusCode, body) answers per function id,
/// consumed in order; an empty queue answers like a network failure.
class FakeFunctionsService extends AppwriteFunctionsService {
  final Map<String, List<(int, Map<String, dynamic>)>> _queued = {};
  final List<(String, Map<String, dynamic>)> calls = [];

  void enqueue(String functionId, int statusCode, Map<String, dynamic> body) {
    _queued.putIfAbsent(functionId, () => []).add((statusCode, body));
  }

  int callsTo(String functionId) =>
      calls.where((c) => c.$1 == functionId).length;

  @override
  Future<FunctionExecutionResult> execute(
    String functionId, {
    Map<String, dynamic> body = const {},
    bool usePost = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    calls.add((functionId, body));
    final queue = _queued[functionId];
    final (status, json) = (queue == null || queue.isEmpty)
        ? (0, <String, dynamic>{'ok': false, 'error': 'NETWORK_ERROR'})
        : queue.removeAt(0);
    return FunctionExecutionResult(
      status: status >= 200 && status < 300 ? 'completed' : 'failed',
      statusCode: status,
      responseBody: jsonEncode(json),
    );
  }
}

Map<String, dynamic> orderBody({
  String orderId = 'order_A1',
  int amount = 14900,
  String categoryId = 'cat_paid',
}) => {
  'ok': true,
  'orderId': orderId,
  'amount': amount,
  'currency': 'INR',
  'keyId': 'rzp_test_key',
  'categoryId': categoryId,
  'categoryTitle': 'Everyday Phrases',
  'isDuplicateRetry': false,
};

const verifiedBody = {'ok': true, 'verified': true, 'categoryId': 'cat_paid'};

const paidResult = RazorpayCheckoutSuccess(
  orderId: 'order_A1',
  paymentId: 'pay_B2',
  signature: 'sig_C3',
);

/// Razorpay stand-in. With [hold] set, `open` waits until [release].
class FakeRazorpayLauncher implements RazorpayLauncher {
  FakeRazorpayLauncher([this.result = paidResult]);

  RazorpayCheckoutResult result;
  final List<RazorpayCheckoutRequest> requests = [];
  Completer<void>? hold;

  void release() => hold?.complete();

  @override
  Future<RazorpayCheckoutResult> open(RazorpayCheckoutRequest request) async {
    requests.add(request);
    if (hold != null) await hold!.future;
    return result;
  }
}

class CheckoutHarness {
  CheckoutHarness._(this.prefs);

  static Future<CheckoutHarness> create() async {
    SharedPreferences.setMockInitialValues({});
    return CheckoutHarness._(await SharedPreferences.getInstance());
  }

  final SharedPreferences prefs;
  final functions = FakeFunctionsService();
  final launcher = FakeRazorpayLauncher();
  final refreshedUsers = <String>[];
  final events = <String>[];
  late final store = PendingVerificationStore(prefs);

  late final CheckoutService service = CheckoutService(
    functions: functions,
    launcher: launcher,
    pendingStore: store,
    refreshEntitlements: (userId) async => refreshedUsers.add(userId),
    logEvent: (event, categoryId, reason) async =>
        events.add(reason == null ? event : '$event:$reason'),
  );
}
