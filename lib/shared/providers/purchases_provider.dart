import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/payments/purchase_repository.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

final purchasedCategoriesProvider = FutureProvider<Set<String>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return {};

  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.fetchPurchasedCategoryIds(user.id);
});

final adminPurchasesProvider =
    StateNotifierProvider<
      AdminPurchasesNotifier,
      AsyncValue<List<PurchaseModel>>
    >((ref) {
      return AdminPurchasesNotifier(ref);
    });

class AdminPurchasesNotifier
    extends StateNotifier<AsyncValue<List<PurchaseModel>>> {
  final Ref ref;
  AdminPurchasesNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    try {
      state = const AsyncValue.loading();
      final db = ref.read(appwriteDbServiceProvider);
      final result = await db.listDocuments(
        'course_purchases',
        queries: [Query.orderDesc('purchasedAt'), Query.limit(1000)],
      );
      final list = result.map(PurchaseModel.fromJson).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      AppLogger.debug('❌ loadPurchases failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refundPurchase(String purchaseId) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);

      // Update purchase status on Appwrite
      await db.updateDocument('course_purchases', purchaseId, {
        'status': 'refunded',
      });

      // Clear purchase cache so user loses access
      final repo = ref.read(purchaseRepositoryProvider);
      await repo.clearAllCaches();

      // Reload purchases
      await loadPurchases();

      // Also refresh the purchased categories provider for the user
      ref.invalidate(purchasedCategoriesProvider);
    } catch (e) {
      AppLogger.debug('❌ refundPurchase failed: $e');
      rethrow;
    }
  }
}
