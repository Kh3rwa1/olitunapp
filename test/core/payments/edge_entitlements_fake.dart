import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:itun/core/payments/purchase_repository.dart';

/// Stands in for the Worker's `/payments/entitlements` route.
class EdgeEntitlementsFake {
  Future<http.Response> Function() _next = () async => http.Response('{}', 500);
  int calls = 0;

  late final http.Client client = MockClient((_) {
    calls++;
    return _next();
  });

  static http.Response _ok(String userId, List<String> ids) => http.Response(
    jsonEncode({'ok': true, 'userId': userId, 'categoryIds': ids}),
    200,
  );

  void answer(String userId, List<String> ids) =>
      _next = () async => _ok(userId, ids);

  void answerLater(String userId, Completer<List<String>> ids) =>
      _next = () async => _ok(userId, await ids.future);

  void status(int code) => _next = () async => http.Response('{}', code);

  void offline() => _next = () async => throw const SocketException('offline');

  Override get override => purchaseRepositoryProvider.overrideWith((ref) {
    final repo = PurchaseRepository(ref, httpClient: client);
    ref.onDispose(repo.dispose);
    return repo;
  });
}
