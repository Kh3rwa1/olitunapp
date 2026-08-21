import 'dart:async';
import 'dart:io';
import 'package:appwrite/appwrite.dart';

/// Typed error classification for all admin operations.
sealed class AdminFailure {
  const AdminFailure(this.userMessage, {this.technicalDetails, this.cause});

  final String userMessage;
  final String? technicalDetails;
  final Object? cause;

  /// Classifies any exception into a typed [AdminFailure].
  factory AdminFailure.fromException(Object error, {String? actionContext}) {
    if (error is AdminFailure) return error;

    final context = actionContext != null ? '$actionContext: ' : '';

    if (error is AppwriteException) {
      final code = error.code ?? 0;
      final type = error.type ?? '';
      final message = error.message ?? '';

      if (code == 404 ||
          type == 'document_not_found' ||
          type == 'user_not_found' ||
          type == 'team_not_found') {
        return AdminNotFoundFailure(
          '${context}Requested resource was not found.',
          technicalDetails: 'Appwrite 404 ($type): $message',
          cause: error,
        );
      }

      if (code == 401 ||
          code == 403 ||
          type == 'user_unauthorized' ||
          type == 'general_unauthorized_scope' ||
          type == 'user_not_admin') {
        return AdminPermissionFailure(
          '${context}You do not have permission to perform this action.',
          technicalDetails: 'Appwrite $code ($type): $message',
          cause: error,
        );
      }

      if (code == 409 || type == 'document_already_exists') {
        return AdminConflictFailure(
          '${context}A conflicting record already exists.',
          technicalDetails: 'Appwrite 409 ($type): $message',
          cause: error,
        );
      }

      if (code == 429 || type == 'rate_limit_exceeded') {
        return AdminRateLimitFailure(
          '${context}Too many requests. Please wait a moment before trying again.',
          technicalDetails: 'Appwrite 429 ($type): $message',
          cause: error,
        );
      }

      if (code >= 500) {
        return AdminServerFailure(
          '${context}Server error encountered. Please try again later.',
          technicalDetails: 'Appwrite $code ($type): $message',
          cause: error,
        );
      }

      return AdminServerFailure(
        '${context}An unexpected service error occurred.',
        technicalDetails: 'Appwrite $code ($type): $message',
        cause: error,
      );
    }

    if (error is TimeoutException) {
      return AdminTimeoutFailure(
        '${context}The request timed out. Please check your connection.',
        technicalDetails: error.toString(),
        cause: error,
      );
    }

    if (error is SocketException || error is HttpException) {
      return AdminNetworkFailure(
        '${context}Network connection error. Please check your internet connection.',
        technicalDetails: error.toString(),
        cause: error,
      );
    }

    if (error is FormatException) {
      return AdminValidationFailure(
        '${context}Invalid data format provided.',
        technicalDetails: error.toString(),
        cause: error,
      );
    }

    return AdminServerFailure(
      '${context}An unexpected error occurred. Please try again.',
      technicalDetails: error.toString(),
      cause: error,
    );
  }

  /// Whether this failure indicates a confirmed missing record (e.g. 404).
  bool get isNotFound => this is AdminNotFoundFailure;

  /// Whether this failure is safe to retry automatically or via user button.
  bool get isRetryable =>
      this is AdminNetworkFailure ||
      this is AdminTimeoutFailure ||
      this is AdminRateLimitFailure;

  /// Redacts sensitive strings (tokens, API keys, passwords) from diagnostic logs.
  String get sanitizedDetails {
    final raw = technicalDetails ?? userMessage;
    return raw
        .replaceAll(RegExp(r'rzp_(live|test)_[a-zA-Z0-9]+'), 'rzp_***')
        .replaceAll(RegExp(r'standard_[a-zA-Z0-9]+'), 'standard_***')
        .replaceAll(RegExp(r'secret_[a-zA-Z0-9]+'), 'secret_***')
        .replaceAll(RegExp(r'Bearer\s+[a-zA-Z0-9_\-\.]+'), 'Bearer ***');
  }
}

final class AdminNetworkFailure extends AdminFailure {
  const AdminNetworkFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminTimeoutFailure extends AdminFailure {
  const AdminTimeoutFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminPermissionFailure extends AdminFailure {
  const AdminPermissionFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminNotFoundFailure extends AdminFailure {
  const AdminNotFoundFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminConflictFailure extends AdminFailure {
  const AdminConflictFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminValidationFailure extends AdminFailure {
  const AdminValidationFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminRateLimitFailure extends AdminFailure {
  const AdminRateLimitFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminServerFailure extends AdminFailure {
  const AdminServerFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}

final class AdminPartialSuccessFailure extends AdminFailure {
  const AdminPartialSuccessFailure(
    super.userMessage, {
    required this.succeededCount,
    required this.failedCount,
    super.technicalDetails,
    super.cause,
  });

  final int succeededCount;
  final int failedCount;
}

final class AdminUnknownOutcomeFailure extends AdminFailure {
  const AdminUnknownOutcomeFailure(
    super.userMessage, {
    super.technicalDetails,
    super.cause,
  });
}
