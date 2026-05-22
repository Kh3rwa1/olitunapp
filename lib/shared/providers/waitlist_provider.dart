import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

final userWaitlistProvider = FutureProvider<List<WaitlistModel>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  try {
    final db = ref.read(appwriteDbServiceProvider);
    final result = await db.listDocuments(
      'binti_guru_waitlist',
      queries: [Query.equal('userId', user.id), Query.orderDesc('submittedAt')],
    );
    return result.map((doc) => WaitlistModel.fromJson(doc)).toList();
  } catch (e) {
    AppLogger.debug('❌ fetch userWaitlist failed: $e');
    return [];
  }
});

final adminWaitlistProvider =
    StateNotifierProvider<
      AdminWaitlistNotifier,
      AsyncValue<List<WaitlistModel>>
    >((ref) {
      return AdminWaitlistNotifier(ref);
    });

class AdminWaitlistNotifier
    extends StateNotifier<AsyncValue<List<WaitlistModel>>> {
  final Ref ref;
  AdminWaitlistNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadWaitlist();
  }

  Future<void> loadWaitlist() async {
    try {
      state = const AsyncValue.loading();
      final db = ref.read(appwriteDbServiceProvider);
      final result = await db.listDocuments(
        'binti_guru_waitlist',
        queries: [Query.orderDesc('submittedAt'), Query.limit(1000)],
      );
      final list = result.map((doc) => WaitlistModel.fromJson(doc)).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      AppLogger.debug('❌ loadWaitlist failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus(String waitlistId, String status) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = <String, dynamic>{'status': status};
      if (status == 'contacted') {
        data['contactedAt'] = DateTime.now().toIso8601String();
      }
      await db.updateDocument('binti_guru_waitlist', waitlistId, data);
      await loadWaitlist();
      ref.invalidate(userWaitlistProvider);
    } catch (e) {
      AppLogger.debug('❌ updateWaitlistStatus failed: $e');
      rethrow;
    }
  }

  Future<void> submitWaitlistEntry(WaitlistModel entry) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      await db.createDocument('binti_guru_waitlist', entry.id, entry.toJson());
      await loadWaitlist();
      ref.invalidate(userWaitlistProvider);
    } catch (e) {
      AppLogger.debug('❌ submitWaitlistEntry failed: $e');
      rethrow;
    }
  }
}

final submitWaitlistEntryProvider = Provider((ref) {
  return (WaitlistModel entry) async {
    final db = ref.read(appwriteDbServiceProvider);
    await db.createDocument('binti_guru_waitlist', entry.id, entry.toJson());
    ref.invalidate(userWaitlistProvider);
    // If admin is active, refresh the admin list as well
    ref.read(adminWaitlistProvider.notifier).loadWaitlist();
  };
});
