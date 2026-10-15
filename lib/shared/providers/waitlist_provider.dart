import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:itun/core/auth/edge_auth.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/logging/app_logger.dart';
import 'package:itun/features/auth/presentation/providers/auth_providers.dart';
import 'package:itun/shared/models/content_models.dart';

/// Thrown when the waitlist service rejects a submission; the message is
/// user-facing (validation errors, rate limits, or a generic failure).
class WaitlistSubmissionException implements Exception {
  final String message;
  const WaitlistSubmissionException(this.message);

  @override
  String toString() => message;
}

/// Cloudflare Worker waitlist API. The Worker validates input, rate-limits by
/// caller and phone number, and deduplicates pending submissions; the caller
/// is identified only by the session JWT (guests may join anonymously).
class WaitlistApi {
  WaitlistApi({http.Client? httpClient, EdgeAuth? edgeAuth})
    : _http = httpClient ?? http.Client(),
      _edgeAuth = edgeAuth ?? EdgeAuth.instance;

  final http.Client _http;
  final EdgeAuth _edgeAuth;

  Future<Map<String, String>> _headers() async => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...await _edgeAuth.headers(),
  };

  Future<WaitlistModel> join(WaitlistModel entry) async {
    final http.Response res;
    try {
      res = await _http
          .post(
            Uri.parse(CloudflareConfig.waitlistEndpoint),
            headers: await _headers(),
            body: jsonEncode({
              'fullName': entry.fullName,
              'phoneNumber': entry.phoneNumber,
              'ceremonyType': entry.ceremonyType,
              if (entry.eventDate != null) 'eventDate': entry.eventDate,
              'city': entry.city,
              'state': entry.state,
              if (entry.notes != null) 'notes': entry.notes,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e, stack) {
      AppLogger.warning(
        'Waitlist request failed',
        name: 'Waitlist',
        error: e,
        stackTrace: stack,
      );
      throw const WaitlistSubmissionException(
        'Could not reach the waitlist service. Check your connection and try again.',
      );
    }

    if (res.statusCode == 401) _edgeAuth.clear();
    final data = _decode(res.body);
    if (data == null) {
      throw const WaitlistSubmissionException(
        'Unexpected waitlist service response.',
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300 || data['ok'] != true) {
      throw WaitlistSubmissionException(
        (data['message'] as String?) ??
            'Waitlist submission failed. Please try again.',
      );
    }

    final entryData = Map<String, dynamic>.from(data['entry'] as Map);
    return WaitlistModel.fromJson(entryData, entryData['id'] as String?);
  }

  /// The signed-in user's own entries, newest first.
  Future<List<WaitlistModel>> mine() =>
      _list(CloudflareConfig.waitlistMineEndpoint);

  /// Every entry, newest first (admin team only; enforced by the Worker).
  Future<List<WaitlistModel>> adminList() =>
      _list(CloudflareConfig.adminWaitlistEndpoint);

  /// Sets an entry's status (admin team only).
  Future<void> adminUpdateStatus(String id, String status) async {
    final res = await _http
        .post(
          Uri.parse(
            '${CloudflareConfig.adminWaitlistEndpoint}/'
            '${Uri.encodeComponent(id)}/status',
          ),
          headers: await _headers(),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) _edgeAuth.clear();
    final data = _decode(res.body);
    if (res.statusCode != 200 || data?['ok'] != true) {
      throw http.ClientException(
        'Waitlist status update failed (${res.statusCode})',
      );
    }
  }

  Future<List<WaitlistModel>> _list(String endpoint) async {
    final res = await _http
        .get(Uri.parse(endpoint), headers: await _headers())
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 401) _edgeAuth.clear();
    final data = _decode(res.body);
    if (res.statusCode != 200 || data == null || data['ok'] != true) {
      throw http.ClientException(
        'Waitlist entries request failed (${res.statusCode})',
      );
    }
    return [
      for (final raw in (data['entries'] as List? ?? const []).whereType<Map>())
        WaitlistModel.fromJson(
          Map<String, dynamic>.from(raw),
          raw['id'] as String?,
        ),
    ];
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }
}

final waitlistApiProvider = Provider<WaitlistApi>((ref) => WaitlistApi());

Future<WaitlistModel> joinWaitlist(Ref ref, WaitlistModel entry) =>
    ref.read(waitlistApiProvider).join(entry);

final userWaitlistProvider = FutureProvider<List<WaitlistModel>>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return [];

  try {
    return await ref.read(waitlistApiProvider).mine();
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

/// Admin view of the D1 waitlist — the same store learners submit to.
class AdminWaitlistNotifier extends AsyncNotifier<List<WaitlistModel>> {
  @override
  FutureOr<List<WaitlistModel>> build() async {
    try {
      return await ref.read(waitlistApiProvider).adminList();
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
      await ref.read(waitlistApiProvider).adminUpdateStatus(waitlistId, status);
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
      await joinWaitlist(ref, entry);
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
    final created = await joinWaitlist(ref, entry);
    ref.invalidate(userWaitlistProvider);
    // Refresh the admin list as well if it is currently being listened to.
    ref.invalidate(adminWaitlistProvider);
    return created;
  };
});
