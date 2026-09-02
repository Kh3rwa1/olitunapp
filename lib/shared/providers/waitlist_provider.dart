import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

/// Thrown when the bintiWaitlist function rejects a submission; the message
/// is user-facing (validation errors, rate limits, or a generic failure).
class WaitlistSubmissionException implements Exception {
  final String message;
  const WaitlistSubmissionException(this.message);

  @override
  String toString() => message;
}

/// Submits a waitlist entry through the `bintiWaitlist` Appwrite function,
/// which validates input, rate-limits by caller and phone number, and
/// deduplicates pending submissions. The collection itself has no public
/// write access; the function's API key performs the write server-side.
Future<WaitlistModel> submitWaitlistViaFunction(
  Ref ref,
  WaitlistModel entry,
) async {
  final authService = ref.read(appwriteAuthServiceProvider);
  final functions = Functions(authService.client);

  final dynamic execution;
  try {
    execution = await functions.createExecution(
      functionId: 'bintiWaitlist',
      body: jsonEncode({
        'fullName': entry.fullName,
        'phoneNumber': entry.phoneNumber,
        'ceremonyType': entry.ceremonyType,
        if (entry.eventDate != null) 'eventDate': entry.eventDate,
        'city': entry.city,
        'state': entry.state,
        if (entry.notes != null) 'notes': entry.notes,
      }),
    );
  } catch (e) {
    AppLogger.debug('Waitlist execution failed: $e');
    throw const WaitlistSubmissionException(
      'Could not reach the waitlist service. Check your connection and try again.',
    );
  }

  if (execution.status.name != 'completed') {
    throw const WaitlistSubmissionException(
      'Waitlist submission failed. Please try again.',
    );
  }

  final Map<String, dynamic> data;
  try {
    data = jsonDecode(execution.responseBody) as Map<String, dynamic>;
  } catch (e) {
    AppLogger.warning(
      'Waitlist: failed to parse function response: $e',
      name: 'Waitlist',
    );
    throw const WaitlistSubmissionException(
      'Unexpected waitlist service response.',
    );
  }

  if (data['ok'] != true) {
    throw WaitlistSubmissionException(
      (data['message'] as String?) ??
          'Waitlist submission failed. Please try again.',
    );
  }

  final entryData = Map<String, dynamic>.from(data['entry'] as Map);
  return WaitlistModel.fromJson(entryData, entryData['id'] as String?);
}

final userWaitlistProvider = FutureProvider<List<WaitlistModel>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  try {
    final db = ref.read(appwriteDbServiceProvider);
    final result = await db.listDocuments(
      'binti_guru_waitlist',
      queries: [Query.equal('userId', user.id), Query.orderDesc('submittedAt')],
    );
    return result.map(WaitlistModel.fromJson).toList();
  } catch (e) {
    AppLogger.debug('❌ fetch userWaitlist failed: $e');
    return [];
  }
});

final adminWaitlistProvider =
    NotifierProvider<AdminWaitlistNotifier, AsyncValue<List<WaitlistModel>>>(
      AdminWaitlistNotifier.new,
    );

class AdminWaitlistNotifier extends Notifier<AsyncValue<List<WaitlistModel>>> {
  bool _disposed = false;

  @override
  AsyncValue<List<WaitlistModel>> build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    // Deferred: `state` may not be read or written inside build().
    Future.microtask(loadWaitlist);
    return const AsyncValue.loading();
  }

  Future<void> loadWaitlist() async {
    try {
      if (_disposed) return;
      state = const AsyncValue.loading();
      final db = ref.read(appwriteDbServiceProvider);
      final result = await db.listDocuments(
        'binti_guru_waitlist',
        queries: [Query.orderDesc('submittedAt'), Query.limit(1000)],
      );
      if (_disposed) return;
      final list = result.map(WaitlistModel.fromJson).toList();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      AppLogger.debug('❌ loadWaitlist failed: $e');
      if (_disposed) return;
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
      await submitWaitlistViaFunction(ref, entry);
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
    final created = await submitWaitlistViaFunction(ref, entry);
    ref.invalidate(userWaitlistProvider);
    // If admin is active, refresh the admin list as well
    ref.read(adminWaitlistProvider.notifier).loadWaitlist();
    return created;
  };
});
