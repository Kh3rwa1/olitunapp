import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../logging/app_logger.dart';

/// What the checkout sheet needs: a server-created order and the public key.
class RazorpayCheckoutRequest {
  const RazorpayCheckoutRequest({
    required this.keyId,
    required this.orderId,
    required this.amountInPaise,
    required this.currency,
    required this.description,
    this.prefillEmail,
  });

  final String keyId;
  final String orderId;
  final int amountInPaise;
  final String currency;
  final String description;
  final String? prefillEmail;

  Map<String, dynamic> toOptions() => {
    'key': keyId,
    'order_id': orderId,
    'amount': amountInPaise,
    'currency': currency,
    'name': 'Olitun',
    'description': description,
    if (prefillEmail != null && prefillEmail!.isNotEmpty)
      'prefill': {'email': prefillEmail},
    'theme': {'color': '#1EE088'},
  };
}

sealed class RazorpayCheckoutResult {
  const RazorpayCheckoutResult();
}

/// The Razorpay checkout response fields the Worker verifies.
class RazorpayCheckoutSuccess extends RazorpayCheckoutResult {
  const RazorpayCheckoutSuccess({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

class RazorpayCheckoutCancelled extends RazorpayCheckoutResult {
  const RazorpayCheckoutCancelled();
}

class RazorpayCheckoutFailed extends RazorpayCheckoutResult {
  const RazorpayCheckoutFailed({this.code, this.isNetworkError = false});

  final int? code;
  final bool isNetworkError;
}

/// Seam over `razorpay_flutter` so the purchase flow is testable without the
/// platform plugin.
abstract interface class RazorpayLauncher {
  Future<RazorpayCheckoutResult> open(RazorpayCheckoutRequest request);
}

/// `razorpay_flutter` ships Android and iOS implementations only.
bool get isRazorpayCheckoutPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

final checkoutSupportedProvider = Provider<bool>(
  (ref) => isRazorpayCheckoutPlatform,
);

final razorpayLauncherProvider = Provider<RazorpayLauncher>(
  (ref) => PluginRazorpayLauncher(),
);

/// Opens the native Razorpay sheet. A fresh plugin instance per checkout keeps
/// listeners from leaking between attempts.
class PluginRazorpayLauncher implements RazorpayLauncher {
  PluginRazorpayLauncher({Razorpay Function()? create})
    : _create = create ?? Razorpay.new;

  final Razorpay Function() _create;

  @override
  Future<RazorpayCheckoutResult> open(RazorpayCheckoutRequest request) {
    final razorpay = _create();
    final completer = Completer<RazorpayCheckoutResult>();
    void finish(RazorpayCheckoutResult result) {
      if (completer.isCompleted) return;
      completer.complete(result);
      razorpay.clear();
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(
        RazorpayCheckoutSuccess(
          orderId: r.orderId ?? request.orderId,
          paymentId: r.paymentId ?? '',
          signature: r.signature ?? '',
        ),
      );
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      AppLogger.debug('Razorpay error ${r.code}', name: 'RazorpayLauncher');
      finish(
        r.code == Razorpay.PAYMENT_CANCELLED
            ? const RazorpayCheckoutCancelled()
            : RazorpayCheckoutFailed(
                code: r.code,
                isNetworkError: r.code == Razorpay.NETWORK_ERROR,
              ),
      );
    });
    // External wallets settle outside the order flow; treat as not paid.
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
      finish(const RazorpayCheckoutFailed());
    });
    try {
      razorpay.open(request.toOptions());
    } catch (e) {
      AppLogger.debug('Razorpay open failed: $e', name: 'RazorpayLauncher');
      finish(const RazorpayCheckoutFailed());
    }
    return completer.future;
  }
}
