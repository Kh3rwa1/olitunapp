import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'purchase_repository.dart';

/// Category ids the signed-in learner has purchased (empty when signed out).
/// Re-evaluates when the entitlement revision for the user is bumped.
final purchasedCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};

  ref.watch(entitlementRevisionProvider(user.id));
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchasedCategoryIds(user.id);
});
