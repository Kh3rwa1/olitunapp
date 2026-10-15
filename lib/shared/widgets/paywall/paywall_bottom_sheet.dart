import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/auth/user_entity.dart';
import '../../../core/payments/checkout_service.dart';
import '../../../core/payments/razorpay_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../models/catalog/category_entity.dart';
import '../../models/catalog/lesson_entity.dart';
import 'paywall_action_section.dart';
import 'paywall_course_details.dart';
import 'paywall_header.dart';
import 'paywall_value_props.dart';

enum PaywallResult {
  /// The learner owns the category now (bought, already owned, or free).
  unlocked,
  signInRequested,
  dismissed,
}

/// True only for a paid category the learner does not own. Free categories
/// (`unlockMode == 'free'`, today's production state) never show a paywall.
bool categoryRequiresPurchase(
  CategoryEntity? category,
  Set<String> ownedCategoryIds,
) =>
    category != null &&
    category.isPremium &&
    !ownedCategoryIds.contains(category.id);

bool lessonRequiresPurchase({
  required LessonEntity lesson,
  required CategoryEntity? category,
  required Set<String> ownedCategoryIds,
}) => !lesson.isPreview && categoryRequiresPurchase(category, ownedCategoryIds);

/// Anonymous Appwrite sessions have no email; purchases need a real account.
bool isGuestPurchaser(UserEntity? user) =>
    user == null || user.email.trim().isEmpty;

class PaywallBottomSheet extends ConsumerStatefulWidget {
  const PaywallBottomSheet({super.key, required this.category});

  final CategoryEntity category;

  /// Opens the paywall for [category]. A sign-in request is routed to the
  /// login screen, the same entry the home guest banner uses.
  static Future<PaywallResult> show(
    BuildContext context, {
    required CategoryEntity category,
  }) async {
    final result = await showModalBottomSheet<PaywallResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaywallBottomSheet(category: category),
    );
    if (result == PaywallResult.signInRequested && context.mounted) {
      GoRouter.maybeOf(context)?.push('/login');
    }
    return result ?? PaywallResult.dismissed;
  }

  @override
  ConsumerState<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends ConsumerState<PaywallBottomSheet> {
  PaywallStage _stage = PaywallStage.preparing;
  CheckoutOrder? _order;
  String? _notice;
  UserEntity? _user;

  CheckoutService get _checkout => ref.read(checkoutServiceProvider);

  @override
  void initState() {
    super.initState();
    unawaited(_checkout.logPaywallViewed(widget.category.id));
    if (ref.read(checkoutSupportedProvider)) {
      unawaited(_initialize());
    } else {
      _stage = PaywallStage.unsupportedPlatform;
    }
  }

  Future<void> _initialize() async {
    UserEntity? user;
    try {
      user = await ref.read(currentUserProvider.future);
    } catch (_) {
      user = null;
    }
    if (!mounted) return;
    if (isGuestPurchaser(user)) {
      setState(() => _stage = PaywallStage.signInRequired);
      return;
    }
    _user = user;
    // Fetch the order up front so the button shows the server's price.
    final outcome = await _checkout.createOrder(widget.category.id);
    if (!mounted) return;
    switch (outcome) {
      case OrderReady(:final order):
        setState(() {
          _order = order;
          _stage = PaywallStage.ready;
        });
      case OrderRejected(:final outcome):
        await _applyOutcome(outcome);
    }
  }

  Future<void> _unlock() async {
    final user = _user;
    if (user == null || _stage != PaywallStage.ready) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _stage = PaywallStage.purchasing;
      _notice = null;
    });
    final outcome = await _checkout.purchase(
      userId: user.id,
      email: user.email,
      categoryId: widget.category.id,
      preparedOrder: _order,
    );
    if (!mounted) return;
    await _applyOutcome(outcome);
  }

  Future<void> _applyOutcome(PurchaseOutcome outcome) async {
    final l10n = AppLocalizations.of(context)!;
    switch (outcome) {
      case PurchaseOutcome.unlocked:
        HapticFeedback.heavyImpact();
        setState(() => _stage = PaywallStage.unlocked);
      case PurchaseOutcome.alreadyOwned:
        final user = _user;
        if (user != null) {
          await _checkout.refreshEntitlements(user.id);
        }
        if (mounted) Navigator.of(context).pop(PaywallResult.unlocked);
      case PurchaseOutcome.free:
        Navigator.of(context).pop(PaywallResult.unlocked);
      case PurchaseOutcome.notConfigured:
        setState(() => _stage = PaywallStage.notConfigured);
      case PurchaseOutcome.pendingVerification:
        setState(() => _stage = PaywallStage.pendingVerification);
      case PurchaseOutcome.busy:
        break;
      case PurchaseOutcome.cancelled:
        _retryable(l10n.paywallPaymentCancelled);
      case PurchaseOutcome.networkError:
        _retryable(l10n.checkConnectionPeriod);
      case PurchaseOutcome.failed:
        _retryable(l10n.paywallPaymentFailed);
    }
  }

  void _retryable(String notice) => setState(() {
    _stage = PaywallStage.ready;
    _notice = notice;
  });

  void _close() => Navigator.of(context).pop(
    _stage == PaywallStage.unlocked
        ? PaywallResult.unlocked
        : PaywallResult.dismissed,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = widget.category;
    final priceLabel = _order?.displayAmount ?? '${category.priceInr}';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            PaywallHeader(category: category, isDark: isDark),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PaywallCourseDetails(category: category, isDark: isDark),
                  PaywallValueProps(
                    isDark: isDark,
                    lessonCount: category.totalLessons,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PaywallActionSection(
                    stage: _stage,
                    priceLabel: priceLabel,
                    notice: _notice,
                    onUnlock: _unlock,
                    onSignIn: () => Navigator.of(
                      context,
                    ).pop(PaywallResult.signInRequested),
                    onDone: _close,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
