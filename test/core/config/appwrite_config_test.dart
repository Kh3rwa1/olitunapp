import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';

void main() {
  test('validate() accepts the production Appwrite defaults', () {
    expect(AppwriteConfig.endpoint, 'https://sgp.cloud.appwrite.io/v1');
    expect(AppwriteConfig.projectId, '699495910038e39622c5');
    expect(AppwriteConfig.validate, returnsNormally);
  });

  test('adminTeamId defaults to "admins"', () {
    expect(AppwriteConfig.adminTeamId, 'admins');
  });
}
