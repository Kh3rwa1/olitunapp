import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';

void main() {
  test('resolves production default Appwrite endpoint and project ID', () {
    expect(AppwriteConfig.endpoint, isNotEmpty);
    expect(AppwriteConfig.projectId, isNotEmpty);
    expect(AppwriteConfig.validate, returnsNormally);
  });

  test('adminTeamId defaults to "admins"', () {
    expect(AppwriteConfig.adminTeamId, 'admins');
  });
}
