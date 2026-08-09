import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async => '.';
}

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    return client;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const endpoint = String.fromEnvironment('STAGING_APPWRITE_ENDPOINT');
  const projectId = String.fromEnvironment('STAGING_APPWRITE_PROJECT_ID');

  test('staging Appwrite endpoint responds to ping', () async {
    PathProviderPlatform.instance = _FakePathProvider();
    HttpOverrides.global = _RealHttpOverrides();

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
