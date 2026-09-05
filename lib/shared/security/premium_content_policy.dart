/// Central policy for deciding whether lesson bodies may be anonymously read.
///
/// This policy is deliberately independent of UI/paywall state. A caller must
/// resolve the category from the backend before publishing a lesson. Missing or
/// unknown category data fails closed instead of silently making paid content
/// public.
class PremiumContentPolicy {
  static const String freeUnlockMode = 'free';
  static const Set<String> paidUnlockModes = {
    'paid_only',
    'review_or_paid',
    'review_only',
  };

  static PublicationDecision forContentItem({
    required bool isPremium,
    String? categoryUnlockMode,
    int? lessonOrder,
    int previewLessonCount = 0,
    bool categoryResolved = true,
    bool isPreview = false,
  }) {
    if (isPremium) {
      return const PublicationDecision.protected('item-marked-premium');
    }

    if (!categoryResolved) {
      return const PublicationDecision.protected('category-unresolved');
    }

    final mode = categoryUnlockMode?.trim().toLowerCase();
    if (mode == null || mode.isEmpty) {
      return const PublicationDecision.protected('unlock-mode-missing');
    }

    if (mode == freeUnlockMode) {
      return const PublicationDecision.public('free-category');
    }

    if (!paidUnlockModes.contains(mode)) {
      return PublicationDecision.protected('unknown-unlock-mode-$mode');
    }

    if (isPreview) {
      return const PublicationDecision.public('explicit-preview');
    }

    final isLegacyOrderWindowPreview =
        previewLessonCount > 0 &&
        lessonOrder != null &&
        lessonOrder > 0 &&
        lessonOrder <= previewLessonCount;
    if (isLegacyOrderWindowPreview) {
      return const PublicationDecision.public('legacy-order-window-preview');
    }

    return PublicationDecision.protected('category-$mode');
  }
}

class PublicationDecision {
  final bool allowAnonymousRead;
  final String reason;

  const PublicationDecision._(this.allowAnonymousRead, this.reason);

  const PublicationDecision.public(String reason) : this._(true, reason);
  const PublicationDecision.protected(String reason) : this._(false, reason);
}
