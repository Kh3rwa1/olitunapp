import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const endpoint = String.fromEnvironment('STAGING_APPWRITE_ENDPOINT');
  const projectId = String.fromEnvironment('STAGING_APPWRITE_PROJECT_ID');

  test('staging Appwrite endpoint responds to ping', () async {
    if (endpoint.isEmpty || projectId.isEmpty) {
      markTestSkipped(
        'Set STAGING_APPWRITE_ENDPOINT and STAGING_APPWRITE_PROJECT_ID dart-defines to run this smoke test.',
      );
      return;
    }

    final client = Client().setEndpoint(endpoint).setProject(projectId);

    await client.ping();
  });
}
