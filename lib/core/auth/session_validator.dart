import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';

/// Evaluates whether a stored web session timestamp is valid (non-null, positive,
/// not older than maxDuration, and not implausibly in the future beyond 1 minute skew).
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
    if (error.code == 401 || error.code == 403) return false;
    if (error.code == 0 ||
        error.code == null ||
        (error.code != null && error.code! >= 500) ||
        error.type == 'network_failure' ||
        error.type == 'general_unknown') {
      return true;
    }
  }

  final message = error.toString().toLowerCase();
  return message.contains('socketexception') ||
      message.contains('timeoutexception') ||
      message.contains('clientexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('handshakeexception') ||
      message.contains('timed out') ||
      message.contains('software caused connection abort') ||
      message.contains('no address associated with hostname') ||
      message.contains('network error') ||
      message.contains('offline');
}
