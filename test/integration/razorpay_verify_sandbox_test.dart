import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class AppwriteAdminClient {
  final String endpoint;
  final String projectId;
  final String apiKey;

  AppwriteAdminClient({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
  });

  Map<String, String> get headers => {
    'X-Appwrite-Project': projectId,
    'X-Appwrite-Key': apiKey,
    'Content-Type': 'application/json',
  };

  Future<http.Response> createDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse(
      '$endpoint/databases/$databaseId/collections/$collectionId/documents',
    );
    return http.post(
      url,
      headers: headers,
      body: jsonEncode({'documentId': documentId, 'data': data}),
    );
  }

  Future<http.Response> getDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    final url = Uri.parse(
      '$endpoint/databases/$databaseId/collections/$collectionId/documents/$documentId',
    );
    return http.get(url, headers: headers);
  }

  Future<http.Response> deleteDocument({
    required String databaseId,
    required String collectionId,
    required String documentId,
  }) async {
    final url = Uri.parse(
      '$endpoint/databases/$databaseId/collections/$collectionId/documents/$documentId',
    );
    return http.delete(url, headers: headers);
  }

  Future<http.Response> createExecution({
    required String functionId,
    required String body,
    bool async = false,
    Map<String, String>? executionHeaders,
  }) async {
    final url = Uri.parse('$endpoint/functions/$functionId/executions');
    return http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'body': body,
        'async': async,
        'headers': executionHeaders,
      }),
    );
  }
}

void main() {
  const endpoint = String.fromEnvironment('STAGING_APPWRITE_ENDPOINT');
  const projectId = String.fromEnvironment('STAGING_APPWRITE_PROJECT_ID');
  const apiKey = String.fromEnvironment('STAGING_APPWRITE_API_KEY');
  const razorpaySecret = String.fromEnvironment('STAGING_RAZORPAY_KEY_SECRET');

  test('Razorpay verification sandbox execution', () async {
    if (endpoint.isEmpty ||
        projectId.isEmpty ||
        apiKey.isEmpty ||
        razorpaySecret.isEmpty) {
      markTestSkipped(
        'Staging credentials not set. Set STAGING_APPWRITE_ENDPOINT, STAGING_APPWRITE_PROJECT_ID, STAGING_APPWRITE_API_KEY, and STAGING_RAZORPAY_KEY_SECRET to run this integration test.',
      );
      return;
    }

    final admin = AppwriteAdminClient(
      endpoint: endpoint,
      projectId: projectId,
      apiKey: apiKey,
    );

    const testUserId = 'test_integration_user';
    const testCategoryId = 'test_integration_category';
    const databaseId = 'olitun_db';

    // 1. Setup mock Category doc if it does not exist
    final createCatRes = await admin.createDocument(
      databaseId: databaseId,
      collectionId: 'categories',
      documentId: testCategoryId,
      data: {
        'titleLatin': 'Test Staging Category',
        'titleOlChiki': 'Test Staging Ol Chiki',
        'unlockMode': 'paid_only',
        'priceInr': 499,
        'isActive': true,
      },
    );
    if (createCatRes.statusCode != 201 && createCatRes.statusCode != 409) {
      fail('Failed to create test category: ${createCatRes.body}');
    }

    // 2. Generate a valid Razorpay signature using the test secret
    const orderId = 'order_test123';
    const paymentId = 'pay_test123';
    const payload = '$orderId|$paymentId';
    final key = utf8.encode(razorpaySecret);
    final bytes = utf8.encode(payload);
    final hmacSha256 = Hmac(sha256, key);
    final signature = hmacSha256.convert(bytes).toString();

    // 3. Trigger verifyCoursePurchase Appwrite Cloud Function
    try {
      final execRes = await admin.createExecution(
        functionId: 'verifyCoursePurchase',
        body: jsonEncode({
          'unlockMethod': 'razorpay',
          'categoryId': testCategoryId,
          'razorpayPaymentId': paymentId,
          'razorpayOrderId': orderId,
          'razorpaySignature': signature,
        }),
        executionHeaders: {'x-appwrite-user-id': testUserId},
      );

      expect(execRes.statusCode, equals(201));

      final execBody = jsonDecode(execRes.body);
      expect(execBody['responseStatusCode'], equals(200));

      final resBody = jsonDecode(execBody['responseBody']);
      expect(resBody['ok'], isTrue);
      expect(resBody['purchase'], isNotNull);
      expect(resBody['purchase']['status'], equals('verified'));

      // 4. Verify that the document was created in course_purchases database
      final purchaseId = sha256
          .convert(utf8.encode('$testUserId:$testCategoryId'))
          .toString()
          .substring(0, 32);
      final docRes = await admin.getDocument(
        databaseId: databaseId,
        collectionId: 'course_purchases',
        documentId: purchaseId,
      );

      expect(docRes.statusCode, equals(200));
      final docData = jsonDecode(docRes.body);
      expect(
        docData['userId'] ?? docData['data']?['userId'],
        equals(testUserId),
      );
      expect(
        docData['categoryId'] ?? docData['data']?['categoryId'],
        equals(testCategoryId),
      );
      expect(
        docData['status'] ?? docData['data']?['status'],
        equals('verified'),
      );
      expect(
        docData['razorpayOrderId'] ?? docData['data']?['razorpayOrderId'],
        equals(orderId),
      );
      expect(
        docData['razorpayPaymentId'] ?? docData['data']?['razorpayPaymentId'],
        equals(paymentId),
      );
    } finally {
      // 5. Clean up: Delete created test purchase document and test category
      final purchaseId = sha256
          .convert(utf8.encode('$testUserId:$testCategoryId'))
          .toString()
          .substring(0, 32);
      await admin.deleteDocument(
        databaseId: databaseId,
        collectionId: 'course_purchases',
        documentId: purchaseId,
      );
      await admin.deleteDocument(
        databaseId: databaseId,
        collectionId: 'categories',
        documentId: testCategoryId,
      );
    }
  });
}
