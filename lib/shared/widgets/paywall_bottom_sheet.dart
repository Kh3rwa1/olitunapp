import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/logging/app_logger.dart';
import '../../core/payments/razorpay_service.dart';
import '../../core/reviews/review_service.dart';
import '../../core/reviews/review_eligibility.dart';
import '../../core/auth/appwrite_auth_service.dart';
import '../providers/purchases_provider.dart';
import '../providers/app_settings_provider.dart';
import '../../features/categories/domain/entities/category_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

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
    final user = ref.read(currentUserProvider).value;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase courses.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating secure server order...';
    });

    final repo = ref.read(purchaseRepositoryProvider);

    try {
      // 1. Create Razorpay order on server based on official category price
      final orderResult = await repo.createRazorpayOrder(widget.category.id);
      if (orderResult['ok'] != true) {
        _showError(orderResult['message'] ?? 'Failed to create payment order');
        return;
      }

      final orderId = orderResult['orderId'] as String;
      final amountInPaise = (orderResult['amount'] as num).toInt();
      final keyId = (orderResult['keyId'] as String?) ?? ref.read(razorpayKeyProvider);

      setState(() {
        _statusMessage = 'Opening payment gateway...';
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
        razorpayKey: keyId,
      );

      if (result is PurchaseSuccess) {
        setState(() {
          _statusMessage = 'Verifying payment with server...';
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
          _showSuccessOverlay('Course successfully unlocked!');
        } else {
          _showError(verifyResult['message'] ?? 'Payment verification failed');
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
      _showError('Checkout encountered an unexpected error: $e');
    }
  }

  Future<void> _handleReviewUnlock() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening Play Store...';
    });

    try {
      final reviewService = ref.read(reviewServiceProvider);
      await reviewService.requestReview();
      await reviewService.openStoreListing();

      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for rating Olitun! Play Store reviews are treated as voluntary feedback.'),
          ),
        );
      }
    } catch (e) {
      AppLogger.debug('Review exception: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = null;
      });
    }
  }

  void _showSuccessOverlay(String message) {
    setState(() {
      _isLoading = false;
      _statusMessage = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF141A24)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 48,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                const SizedBox(height: 24),
                const Text(
                  'Maran Jauhar! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // pop dialog
                      Navigator.of(this.context).pop(); // pop bottom sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Start Learning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
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
            const SizedBox(width: 12),
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

    // Watch settings and review eligibility
    final settingsAsync = ref.watch(appSettingsProvider);
    final hasReviewedAsync = ref.watch(hasUnlockedViaReviewProvider);

    final globalReviewEnabled =
        settingsAsync.value?['global_review_unlock_enabled'] != 'false';
    final hasAlreadyReviewed = hasReviewedAsync.value ?? false;

    // Check availability
    final showReviewButton =
        globalReviewEnabled &&
        (widget.category.unlockMode == 'review_only' ||
            widget.category.unlockMode == 'review_or_paid');

    final showPaidButton =
        widget.category.unlockMode == 'paid_only' ||
        widget.category.unlockMode == 'review_or_paid';

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C1017) : Colors.white,
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
                // Custom Drag Handle Indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 14, bottom: 20),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Hero Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isDark
                            ? const LinearGradient(
                                colors: [Color(0xFF2E1A1A), Color(0xFF140D0D)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFFFF0F0), Color(0xFFFFE0E0)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Stack(
                        children: [
                          if (widget.category.courseHeroImageUrl != null &&
                              widget.category.courseHeroImageUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: widget.category.courseHeroImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.7),
                                  Colors.black.withValues(alpha: 0.2),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            left: 20,
                            right: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.workspace_premium_rounded,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'PREMIUM COURSE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.category.titleLatin,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                if (widget
                                    .category
                                    .titleOlChiki
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.category.titleOlChiki,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'OlChiki',
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Description & Outcome List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.category.courseDescription != null &&
                          widget.category.courseDescription!
                              .trim()
                              .isNotEmpty) ...[
                        Text(
                          'About this course',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.87)
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.category.courseDescription!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (widget.category.courseOutcome != null &&
                          widget.category.courseOutcome!.trim().isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.03)
                                : AppColors.primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : AppColors.primary.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.insights_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Course Outcome',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.category.courseOutcome!,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Value Props List
                      _buildValuePropRow(
                        context,
                        Icons.verified_user_outlined,
                        'Get verified full access',
                        'Unlock all lessons, interactive quizzes, and offline media.',
                      ),
                      const SizedBox(height: 14),
                      _buildValuePropRow(
                        context,
                        Icons.mobile_friendly_rounded,
                        'Learn at your own pace',
                        'Enjoy lifetime access with no renewals or monthly subscriptions.',
                      ),

                      const SizedBox(height: 36),

                      // Platform limitations block
                      if (kIsWeb)
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 36,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Monetization restricted on Web',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Razorpay checkouts and App Store reviews are only supported on the Olitun Mobile Application. Please load this on Android/iOS to unlock.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        // CTAs Area
                        if (showPaidButton) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handlePayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Text(
                                'Unlock Course (₹${widget.category.priceInr})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        if (showReviewButton) ...[
                          if (showPaidButton)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  '— OR —',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: (_isLoading || hasAlreadyReviewed)
                                  ? null
                                  : _handleReviewUnlock,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: hasAlreadyReviewed
                                      ? Colors.grey.withValues(alpha: 0.3)
                                      : AppColors.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.rate_review_outlined,
                                    color: hasAlreadyReviewed
                                        ? Colors.grey
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Unlock via Play Store Review',
                                    style: TextStyle(
                                      color: hasAlreadyReviewed
                                          ? Colors.grey
                                          : AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (hasAlreadyReviewed)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.grey,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'You already unlocked a course via review.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
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
                      const SizedBox(height: 24),
                      Text(
                        _statusMessage ?? 'Processing...',
                        style: TextStyle(
                          fontSize: 16,
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

  Widget _buildValuePropRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.87)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white30 : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
