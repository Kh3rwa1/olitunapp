import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ads/widgets/native_ad_widget.dart';
import '../../core/logging/app_logger.dart';
import '../../core/payments/purchase_repository.dart';
import '../../core/payments/razorpay_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/categories/domain/entities/category_entity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import '../providers/purchases_provider.dart';
import 'paywall/paywall_action_section.dart';
import 'paywall/paywall_course_details.dart';
import 'paywall/paywall_header.dart';
import 'paywall/paywall_success_dialog.dart';
import 'paywall/paywall_value_props.dart';

class PaywallBottomSheet extends ConsumerStatefulWidget {
  final CategoryEntity category;

  const PaywallBottomSheet({super.key, required this.category});

  @override
  ConsumerState<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends ConsumerState<PaywallBottomSheet> {
  final RazorpayService _razorpayService = RazorpayService();
  bool _isLoading = false;
  String? _statusMessage;

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  Future<void> _handlePayment() async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseLogInToPurchase)));
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = l10n.creatingSecureOrder;
    });

    final repo = ref.read(purchaseRepositoryProvider);

    try {
      // 1. Create Razorpay order on server based on official category price
      final orderResult = await repo.createRazorpayOrder(widget.category.id);
      if (orderResult['ok'] != true) {
        _showError(orderResult['message'] ?? l10n.failedToCreateOrder);
        return;
      }

      final orderId = orderResult['orderId'] as String;
      final amountInPaise = (orderResult['amount'] as num).toInt();
      final String razorpayKey =
          (orderResult['keyId'] as String?) ?? ref.read(razorpayKeyProvider);

      setState(() {
        _statusMessage = l10n.openingPaymentGateway;
      });

      // 2. Launch Razorpay checkout bound to server order ID
      final result = await _razorpayService.startCheckoutWithOrder(
        orderId: orderId,
        amountInPaise: amountInPaise,
        categoryId: widget.category.id,
        categoryTitle: widget.category.titleLatin,
        userId: user.id,
        userEmail: user.email,
        userPhone: '9999999999',
        razorpayKey: razorpayKey,
      );

      if (result is PurchaseSuccess) {
        setState(() {
          _statusMessage = l10n.verifyingPayment;
        });

        // 3. Verify payment signature & captured status on server
        final verifyResult = await repo.verifyPurchase(
          categoryId: widget.category.id,
          paymentId: result.paymentId,
          orderId: result.orderId,
          signature: result.signature,
        );

        if (verifyResult['ok'] == true) {
          ref.invalidate(purchasedCategoriesProvider);
          HapticFeedback.heavyImpact();
          _showSuccessOverlay(l10n.courseUnlocked);
        } else {
          _showError(verifyResult['message'] ?? l10n.paymentVerificationFailed);
        }
      } else if (result is PurchaseFailed) {
        _showError(result.message);
      } else {
        // PurchaseCancelled
        setState(() {
          _isLoading = false;
          _statusMessage = null;
        });
      }
    } catch (e) {
      AppLogger.debug('Checkout exception: $e');
      _showError(l10n.checkoutUnexpectedError(e.toString()));
    }
  }

  // Review-for-unlock was removed (Google Play incentivized-review policy
  // risk). Categories previously gated as review_only now stay paid;
  // players who already unlocked via review keep their entitlement — the
  // server still honors those records.

  void _showSuccessOverlay(String message) {
    setState(() {
      _isLoading = false;
      _statusMessage = null;
    });

    PaywallSuccessDialog.show(
      context,
      message: message,
      onStartLearning: () {
        Navigator.of(context).pop(); // pop bottom sheet
      },
    );
  }

  void _showError(String errorMsg) {
    setState(() {
      _isLoading = false;
      _statusMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(errorMsg)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    final showPaidButton =
        widget.category.unlockMode == 'paid_only' ||
        widget.category.unlockMode == 'review_or_paid' ||
        widget.category.unlockMode == 'review_only';

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 36,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                PaywallHeader(category: widget.category, isDark: isDark),
                const SizedBox(height: AppSpacing.lg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PaywallCourseDetails(
                        category: widget.category,
                        isDark: isDark,
                      ),
                      PaywallValueProps(isDark: isDark),
                      const SizedBox(height: AppSpacing.lg),
                      const RepaintBoundary(
                        child: NativeAdWidget(placement: 'paywall_native'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PaywallActionSection(
                        category: widget.category,
                        isLoading: _isLoading,
                        showPaidButton: showPaidButton,
                        onPayPressed: _handlePayment,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading Screen Overlaid
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.85,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _statusMessage ??
                            AppLocalizations.of(context)!.processing,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
