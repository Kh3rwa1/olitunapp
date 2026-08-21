import 'package:flutter/foundation.dart';
import '../../../../shared/models/content_models.dart';

/// Immutable accounting result calculated from purchase records.
@immutable
class PurchaseMetricsResult {
  /// Total gross revenue collected before refunds in integer minor currency units (INR).
  /// Includes all successfully collected paid transactions, even if subsequently refunded.
  final int grossCollectedInr;

  /// Total amount refunded back from previously collected payments (INR).
  final int refundedInr;

  /// Net revenue after deducting confirmed refunds (`grossCollectedInr - refundedInr`).
  final int netRevenueInr;

  /// Total count of all transactions that successfully collected payment (active + refunded).
  final int verifiedPaidCount;

  /// Total count of currently active (non-refunded) paid transactions.
  final int activePaidCount;

  /// Total count of refunded transactions.
  final int refundedCount;

  /// Total count of failed / uncaptured payment attempts.
  final int failedCount;

  /// Total count of non-monetary Play Store review unlocks.
  final int reviewUnlockCount;

  /// Total count of free, promotional, or manual administrative unlocks.
  final int freeOrManualCount;

  /// Total records evaluated.
  final int totalRecords;

  /// Percentage of verified unlocks that were monetized via payment (`(activePaidCount / (activePaidCount + reviewUnlockCount)) * 100`).
  final double verifiedPaidShare;

  /// Indicates if metrics are calculated from a sampled or partial dataset.
  final bool isSampledOrPartial;

  /// Primary currency code (defaults to INR).
  final String currency;

  /// Indicates if multiple currencies were detected in the source records.
  final bool hasMixedCurrencies;

  const PurchaseMetricsResult({
    required this.grossCollectedInr,
    required this.refundedInr,
    required this.netRevenueInr,
    required this.verifiedPaidCount,
    required this.activePaidCount,
    required this.refundedCount,
    required this.failedCount,
    required this.reviewUnlockCount,
    required this.freeOrManualCount,
    required this.totalRecords,
    required this.verifiedPaidShare,
    this.isSampledOrPartial = false,
    this.currency = 'INR',
    this.hasMixedCurrencies = false,
  });

  static const empty = PurchaseMetricsResult(
    grossCollectedInr: 0,
    refundedInr: 0,
    netRevenueInr: 0,
    verifiedPaidCount: 0,
    activePaidCount: 0,
    refundedCount: 0,
    failedCount: 0,
    reviewUnlockCount: 0,
    freeOrManualCount: 0,
    totalRecords: 0,
    verifiedPaidShare: 0.0,
  );
}

/// Pure, authoritative financial metrics engine for purchase accounting.
class PurchaseMetricsCalculator {
  const PurchaseMetricsCalculator._();

  /// Calculates accurate, audit-compliant financial metrics from purchase items.
  ///
  /// Mathematical invariants:
  /// - `grossCollectedInr` includes all successfully collected payments (active + refunded).
  /// - `netRevenueInr` strictly equals `grossCollectedInr - refundedInr`.
  /// - Deduplicates by `razorpayPaymentId` when present to prevent duplicate records from inflating revenue.
  /// - Never double-subtracts refunds.
  /// - Excludes failed, pending, promotional, and review unlocks from collected revenue.
  static PurchaseMetricsResult calculate(
    List<PurchaseModel> items, {
    bool isSampledOrPartial = false,
    String defaultCurrency = 'INR',
  }) {
    if (items.isEmpty) {
      return PurchaseMetricsResult.empty;
    }

    int grossInr = 0;
    int refundedInr = 0;
    int activePaid = 0;
    int refundedCount = 0;
    int failedCount = 0;
    int reviewCount = 0;
    int freeOrManualCount = 0;

    final seenPaymentIds = <String>{};
    final seenDocIds = <String>{};

    for (final item in items) {
      // Prevent duplicate documents from double-counting
      if (item.id.isNotEmpty) {
        if (seenDocIds.contains(item.id)) continue;
        seenDocIds.add(item.id);
      }

      final unlockMethod = item.unlockMethod.toLowerCase().trim();
      final status = item.status.toLowerCase().trim();
      final amount = item.amountPaidInr > 0 ? item.amountPaidInr : 0;
      final paymentId = item.razorpayPaymentId?.trim() ?? '';

      // Check payment ID deduplication for payment transactions
      final isDuplicatePayment =
          paymentId.isNotEmpty && seenPaymentIds.contains(paymentId);
      if (paymentId.isNotEmpty) {
        seenPaymentIds.add(paymentId);
      }

      if (unlockMethod == 'razorpay') {
        if (isDuplicatePayment) {
          // Skip counting duplicate payment transactions to prevent fraud/duplicate ingestion inflation
          continue;
        }

        if (status == 'verified') {
          grossInr += amount;
          activePaid++;
        } else if (status == 'refunded') {
          // Historical accounting: gross collects the original paid amount;
          // refunded records the refund deduction.
          grossInr += amount;
          refundedInr += amount;
          refundedCount++;
        } else if (status == 'failed' || status == 'cancelled') {
          failedCount++;
        }
      } else if (unlockMethod == 'play_store_review') {
        if (status == 'verified' || status == 'active') {
          reviewCount++;
        }
      } else if (unlockMethod == 'free' ||
          unlockMethod == 'manual' ||
          unlockMethod == 'promo') {
        freeOrManualCount++;
      } else {
        // Fallback checks for status
        if (status == 'failed' || status == 'cancelled') {
          failedCount++;
        } else if (status == 'refunded') {
          refundedInr += amount;
          grossInr += amount;
          refundedCount++;
        }
      }
    }

    final totalVerifiedPaid = activePaid + refundedCount;
    final totalVerifiedUnlocks = activePaid + reviewCount;
    final netRevenue = grossInr - refundedInr;

    final paidShare = totalVerifiedUnlocks > 0
        ? (activePaid / totalVerifiedUnlocks) * 100
        : 0.0;

    return PurchaseMetricsResult(
      grossCollectedInr: grossInr,
      refundedInr: refundedInr,
      netRevenueInr: netRevenue,
      verifiedPaidCount: totalVerifiedPaid,
      activePaidCount: activePaid,
      refundedCount: refundedCount,
      failedCount: failedCount,
      reviewUnlockCount: reviewCount,
      freeOrManualCount: freeOrManualCount,
      totalRecords: items.length,
      verifiedPaidShare: paidShare,
      isSampledOrPartial: isSampledOrPartial,
      currency: defaultCurrency,
    );
  }
}
