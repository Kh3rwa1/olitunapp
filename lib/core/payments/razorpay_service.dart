import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../logging/app_logger.dart';

sealed class PurchaseResult {
  const PurchaseResult();
}

class PurchaseSuccess extends PurchaseResult {
  final String paymentId;
  final String orderId;
  final String signature;
  const PurchaseSuccess({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
}

class PurchaseFailed extends PurchaseResult {
  final String message;
  const PurchaseFailed(this.message);
}

class PurchaseCancelled extends PurchaseResult {
  const PurchaseCancelled();
}

class RazorpayService {
  late Razorpay _razorpay;
  Completer<PurchaseResult>? _completer;

  RazorpayService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  /// Launch Razorpay checkout using server-generated order ID
  Future<PurchaseResult> startCheckoutWithOrder({
    required String orderId,
    required int amountInPaise,
    required String categoryId,
    required String categoryTitle,
    required String userId,
    required String userEmail,
    required String userPhone,
    required String razorpayKey,
  }) async {
    if (kIsWeb) {
      return const PurchaseFailed(
        'Razorpay is not supported on web. Please use a mobile device.',
      );
    }

    _completer = Completer<PurchaseResult>();

    final options = {
      'key': razorpayKey,
      'order_id': orderId, // Bound to server-created Razorpay Order
      'amount': amountInPaise,
      'name': 'Olitun App',
      'description': 'Unlock Course: $categoryTitle',
      'prefill': {'contact': userPhone, 'email': userEmail},
      'notes': {'userId': userId, 'categoryId': categoryId, 'orderId': orderId},
      'theme': {'color': '#8B3A3A'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      AppLogger.debug('Razorpay open failed: $e');
      return PurchaseFailed('Could not open payment gateway: $e');
    }

    return _completer!.future;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    AppLogger.debug('Razorpay Success: ${response.paymentId}');
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(
        PurchaseSuccess(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? '',
          signature: response.signature ?? '',
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    AppLogger.debug('Razorpay Error: ${response.code} - ${response.message}');
    if (_completer != null && !_completer!.isCompleted) {
      if (response.code == Razorpay.PAYMENT_CANCELLED) {
        _completer!.complete(const PurchaseCancelled());
      } else {
        _completer!.complete(
          PurchaseFailed(response.message ?? 'Unknown payment error'),
        );
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppLogger.debug('Razorpay External Wallet: ${response.walletName}');
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(
        const PurchaseFailed(
          'External wallets are not supported in this version',
        ),
      );
    }
  }
}
