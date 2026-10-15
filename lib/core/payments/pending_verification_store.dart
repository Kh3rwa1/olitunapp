import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../logging/app_logger.dart';

/// A paid checkout whose server verification has not succeeded yet.
class PendingVerification {
  const PendingVerification({
    required this.userId,
    required this.categoryId,
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String userId;
  final String categoryId;
  final String orderId;
  final String paymentId;
  final String signature;

  Map<String, String> toJson() => {
    'userId': userId,
    'categoryId': categoryId,
    'orderId': orderId,
    'paymentId': paymentId,
    'signature': signature,
  };

  static PendingVerification? fromJson(Object? json) {
    if (json is! Map) return null;
    String field(String key) => (json[key] ?? '').toString();
    final record = PendingVerification(
      userId: field('userId'),
      categoryId: field('categoryId'),
      orderId: field('orderId'),
      paymentId: field('paymentId'),
      signature: field('signature'),
    );
    final complete =
        record.userId.isNotEmpty &&
        record.orderId.isNotEmpty &&
        record.paymentId.isNotEmpty &&
        record.signature.isNotEmpty;
    return complete ? record : null;
  }
}

/// Persists [PendingVerification]s (keyed by order id) so a verify call that
/// failed after payment is retried on the next app start.
class PendingVerificationStore {
  PendingVerificationStore(this._prefs);

  static const storageKey = 'payments.pending_verifications.v1';

  final SharedPreferences _prefs;

  List<PendingVerification> readAll() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(PendingVerification.fromJson)
          .whereType<PendingVerification>()
          .toList();
    } catch (e) {
      AppLogger.debug('Pending verifications unreadable: $e');
      return const [];
    }
  }

  List<PendingVerification> forUser(String userId) =>
      readAll().where((r) => r.userId == userId).toList();

  Future<void> save(PendingVerification record) async {
    final others = readAll().where((r) => r.orderId != record.orderId);
    await _write([...others, record]);
  }

  Future<void> remove(String orderId) async {
    await _write(readAll().where((r) => r.orderId != orderId).toList());
  }

  Future<void> _write(List<PendingVerification> records) async {
    if (records.isEmpty) {
      await _prefs.remove(storageKey);
      return;
    }
    await _prefs.setString(
      storageKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }
}
