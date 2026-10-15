import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_edge_client.dart';
import 'edge_json_client.dart';

/// One page of `/api/v1/admin/purchases` (D1 purchase ledger).
class AdminPurchasePage {
  const AdminPurchasePage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  /// Purchase documents in the shape `PurchaseModel.fromJson` reads.
  final List<Map<String, dynamic>> items;
  final bool hasMore;

  /// Opaque keyset cursor for the next page; null on the last page.
  final String? nextCursor;
}

/// Admin purchase list/export over the Worker. Filters match the admin
/// purchases screen: `all`, `razorpay`, `review`, `refunded`, plus a
/// category id substring search.
class AdminPurchasesApi {
  AdminPurchasesApi(this._client);

  static const int maxExportPage = 1000;

  final AdminEdgeClient _client;

  Future<AdminPurchasePage> list({
    required String filter,
    String search = '',
    String? cursor,
    int limit = 50,
    bool export = false,
  }) async {
    final uri =
        AdminEdgeClient.adminUri(export ? 'purchases/export' : 'purchases', {
          'filter': filter,
          'limit': '$limit',
          if (search.isNotEmpty) 'search': search,
          if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        });
    final body = await _client.getOk(uri);
    final rows = body['purchases'];
    if (rows is! List) {
      throw EdgeApiException('Missing "purchases" list from ${uri.path}');
    }
    final next = body['nextCursor'];
    return AdminPurchasePage(
      items: rows
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList(growable: false),
      hasMore: body['hasMore'] == true,
      nextCursor: next is String && next.isNotEmpty ? next : null,
    );
  }
}

final adminPurchasesApiProvider = Provider<AdminPurchasesApi>(
  (ref) => AdminPurchasesApi(ref.watch(adminEdgeClientProvider)),
);
