import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/core/api/appwrite_functions_service.dart';
import 'package:itun/core/api/appwrite_query_builders.dart';
import 'package:itun/core/logging/app_logger.dart';
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
  final FunctionExecutionResult execution;
  try {
    execution = await ref
        .read(appwriteFunctionsServiceProvider)
        .execute(
          'bintiWaitlist',
          usePost: true,
          body: {
            'fullName': entry.fullName,
            'phoneNumber': entry.phoneNumber,
            'ceremonyType': entry.ceremonyType,
            if (entry.eventDate != null) 'eventDate': entry.eventDate,
            'city': entry.city,
            'state': entry.state,
            if (entry.notes != null) 'notes': entry.notes,
          },
        );
  } catch (e, stack) {
    AppLogger.warning(
      'Waitlist execution failed',
      name: 'Waitlist',
      error: e,
      stackTrace: stack,
    );
    throw const WaitlistSubmissionException(
      'Could not reach the waitlist service. Check your connection and try again.',
    );
  }

  if (!execution.isCompleted) {
    throw const WaitlistSubmissionException(
      'Waitlist submission failed. Please try again.',
    );
  }

  final data = execution.bodyJson;
  if (data == null) {
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
      queries: [
        DbQuery.equal('userId', user.id),
        DbQuery.orderDesc('submittedAt'),
      ],
    );
    return result.map(WaitlistModel.fromJson).toList();
  } catch (e, stack) {
    AppLogger.warning(
      'Fetching user waitlist failed',
      name: 'Waitlist',
      error: e,
      stackTrace: stack,
    );
    return [];
  }
});

final adminWaitlistProvider =
    AsyncNotifierProvider<AdminWaitlistNotifier, List<WaitlistModel>>(
      AdminWaitlistNotifier.new,
    );

class AdminWaitlistNotifier extends AsyncNotifier<List<WaitlistModel>> {
  static const String _collectionId = 'binti_guru_waitlist';

  @override
  FutureOr<List<WaitlistModel>> build() async {
    try {
      final result = await ref
          .read(appwriteDbServiceProvider)
          .listAllDocuments(
            _collectionId,
            queries: [DbQuery.orderDesc('submittedAt')],
          );
      return result.map(WaitlistModel.fromJson).toList();
    } catch (e, stack) {
      AppLogger.error(
        'Loading admin waitlist failed',
        name: 'Waitlist',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Re-fetches the waitlist and waits for the result.
  Future<void> loadWaitlist() async {
    ref.invalidateSelf();
    // Failures are logged in build() and exposed through `state`.
    await future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
  }

  Future<void> updateStatus(String waitlistId, String status) async {
    try {
      final db = ref.read(appwriteDbServiceProvider);
      final data = <String, dynamic>{'status': status};
      if (status == 'contacted') {
        data['contactedAt'] = DateTime.now().toIso8601String();
      }
      await db.updateDocument(_collectionId, waitlistId, data);
      await loadWaitlist();
      ref.invalidate(userWaitlistProvider);
    } catch (e, stack) {
      AppLogger.error(
        'Updating waitlist status failed',
        name: 'Waitlist',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> submitWaitlistEntry(WaitlistModel entry) async {
    try {
      await submitWaitlistViaFunction(ref, entry);
      await loadWaitlist();
      ref.invalidate(userWaitlistProvider);
    } catch (e, stack) {
      AppLogger.error(
        'Submitting waitlist entry failed',
        name: 'Waitlist',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}

final submitWaitlistEntryProvider = Provider((ref) {
  return (WaitlistModel entry) async {
    final created = await submitWaitlistViaFunction(ref, entry);
    ref.invalidate(userWaitlistProvider);
    // Refresh the admin list as well if it is currently being listened to.
    ref.invalidate(adminWaitlistProvider);
    return created;
  };
});
