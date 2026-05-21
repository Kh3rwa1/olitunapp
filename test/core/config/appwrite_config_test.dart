import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';

void main() {
  test('validate() fails when required Appwrite config is omitted', () {
    expect(AppwriteConfig.endpoint, isEmpty);
    expect(AppwriteConfig.projectId, isEmpty);
    expect(AppwriteConfig.validate, throwsA(isA<StateError>()));
  });

  test('adminTeamId defaults to "admins"', () {
    expect(AppwriteConfig.adminTeamId, 'admins');
  });
}
