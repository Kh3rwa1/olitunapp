import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

/// Evaluates whether a stored web session timestamp is valid (non-null, positive,
/// not older than maxDuration, and not implausibly in the future beyond 1 minute skew).
@visibleForTesting
bool isWebSessionValidTimestamp(
  int? ts, {
  Duration maxDuration = const Duration(hours: 24),
  DateTime? nowOverride,
}) {
  if (ts == null || ts <= 0) return false;
  final nowMs = (nowOverride ?? DateTime.now()).millisecondsSinceEpoch;
  // Allow up to 1 minute clock skew into the future, otherwise treat as invalid
  if (ts > nowMs + 60000) return false;
  final ageMs = nowMs - ts;
  if (ageMs > maxDuration.inMilliseconds) return false;
  return true;
}

@visibleForTesting
bool isTransientSessionValidationFailure(Object error) {
  if (error is TimeoutException) return true;
  if (error is AppwriteException) {
    return error.code == 0 ||
        error.type == 'network_failure' ||
        error.type == 'general_unknown';
  }

  final message = error.toString();
  return message.contains('SocketException') ||
      message.contains('TimeoutException');
}
