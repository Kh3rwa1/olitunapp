import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import '../api/appwrite_db_service.dart';
import '../storage/cache_service.dart';
import '../logging/app_logger.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';

final hasUnlockedViaReviewProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return false;

  const cacheKey = 'has_unlocked_via_review';

  // Try Cache First
  final cached = await CacheService.get(
    cacheKey,
    (json) => json['value'] as bool,
  );
  if (cached != null) {
    return cached;
  }

  try {
    final db = ref.read(appwriteDbServiceProvider);
    final result = await db.listDocuments(
      'course_purchases',
      queries: [
        Query.equal('userId', user.id),
        Query.equal('unlockMethod', 'play_store_review'),
        Query.equal('status', 'verified'),
        Query.limit(1),
      ],
    );

    final hasReviewed = result.isNotEmpty;
    await CacheService.set(cacheKey, {'value': hasReviewed});
    return hasReviewed;
  } catch (e) {
    AppLogger.debug('❌ Error checking review eligibility: $e');
    return false;
  }
});
