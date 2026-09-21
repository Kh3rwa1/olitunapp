import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import '../logging/app_logger.dart';
import '../logging/redaction_helper.dart';

enum AccountDeletionOutcomeKind {
  completed,
  authDeletedReconciliationPending,
  failed,
  malformed,
}

@visibleForTesting
class AccountDeletionResult {
  final AccountDeletionOutcomeKind kind;
  final bool isAuthDeleted;
  final bool isFullSuccess;
  final String? errorMessage;
  final int statusCode;

  const AccountDeletionResult({
    required this.kind,
    required this.isAuthDeleted,
    required this.isFullSuccess,
    this.errorMessage,
    required this.statusCode,
  });
}

@visibleForTesting
AccountDeletionResult parseAccountDeletionExecution({
  required String status,
  required int statusCode,
  required String responseBody,
}) {
  final trimmedBody = responseBody.trim();
  Map<String, dynamic>? responseData;
  bool isMalformed = false;
  if (trimmedBody.isNotEmpty) {
    try {
      final decoded = jsonDecode(trimmedBody);
      if (decoded is Map<String, dynamic>) {
        responseData = decoded;
      } else {
        isMalformed = true;
      }
    } catch (_) {
      // Non-JSON body is intentionally reported as a malformed outcome below.
      isMalformed = true;
    }
  } else {
    isMalformed = true;
  }

  final isAuthDeleted = responseData?['authDeleted'] == true;
  // Accept both SDK enum strings and plain status values.
  final normalizedStatus = status.trim().toLowerCase().split('.').last;
  final isCompletedStatus = normalizedStatus == 'completed';
  // The existing server confirms completed deletion with account_deleted;
  // newer responses may additionally include authDeleted. Never accept a
  // generic {ok: true} or an explicit authDeleted: false as confirmation.
  final isConfirmed =
      responseData?['authDeleted'] != false &&
      (isAuthDeleted || responseData?['code'] == 'account_deleted');

  if (!isCompletedStatus ||
      !isConfirmed ||
      statusCode < 200 ||
      statusCode >= 300 ||
      responseData == null ||
      responseData['ok'] != true ||
      isMalformed) {
    if (isAuthDeleted) {
      return AccountDeletionResult(
        kind: AccountDeletionOutcomeKind.authDeletedReconciliationPending,
        isAuthDeleted: true,
        isFullSuccess: false,
        errorMessage:
            'Account deleted; final cleanup reconciliation is pending.',
        statusCode: statusCode != 0 ? statusCode : 500,
      );
    }

    if (isMalformed) {
      return AccountDeletionResult(
        kind: AccountDeletionOutcomeKind.malformed,
        isAuthDeleted: false,
        isFullSuccess: false,
        errorMessage: 'Account deletion failed: malformed response from server',
        statusCode: statusCode != 0 ? statusCode : 500,
      );
    }

    final errCode =
        responseData?['code']?.toString() ??
        responseData?['message']?.toString() ??
        'Account deletion failed on server';

    return AccountDeletionResult(
      kind: AccountDeletionOutcomeKind.failed,
      isAuthDeleted: false,
      isFullSuccess: false,
      errorMessage: errCode,
      statusCode: statusCode != 0 ? statusCode : 500,
    );
  }

  return AccountDeletionResult(
    kind: AccountDeletionOutcomeKind.completed,
    isAuthDeleted: true,
    isFullSuccess: true,
    statusCode: statusCode != 0 ? statusCode : 200,
  );
}

Future<void> executeAccountDeletion({
  required Functions functions,
  required Future<void> Function() restoreWebSession,
  required Future<void> Function({bool preserveAccount}) clearLocalSessionState,
}) async {
  try {
    await restoreWebSession();

    final execution = await functions.createExecution(
      functionId: 'delete-account',
    );

    final result = parseAccountDeletionExecution(
      status: execution.status.toString(),
      statusCode: execution.responseStatusCode,
      responseBody: execution.responseBody,
    );

    if (!result.isFullSuccess) {
      if (result.isAuthDeleted) {
        await clearLocalSessionState();
        throw AppwriteException(
          result.errorMessage ??
              'Account deleted; final cleanup reconciliation is pending.',
          result.statusCode,
          'account_deletion_pending',
        );
      }

      throw AppwriteException(
        result.errorMessage ?? 'Account deletion failed on server',
        result.statusCode,
      );
    }

    await clearLocalSessionState();
  } on AppwriteException catch (e) {
    if (e.code == 401 && e.type != 'account_deletion_pending') {
      await clearLocalSessionState();
      throw AppwriteException(
        'Sign in again to confirm account deletion. Deletion is not confirmed.',
        401,
        'account_deletion_reauthentication_required',
      );
    }
    AppLogger.error(
      'Appwrite: deleteAccount error: ${RedactionHelper.sanitize(e.message ?? e.toString())}',
    );
    rethrow;
  } catch (e) {
    AppLogger.error(
      'Appwrite: deleteAccount unexpected error: ${RedactionHelper.sanitize(e.toString())}',
    );
    throw AppwriteException(
      'Account deletion failed: ${RedactionHelper.sanitize(e.toString())}',
      500,
    );
  }
}
