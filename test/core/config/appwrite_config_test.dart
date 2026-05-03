import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/appwrite_config.dart';

void main() {
  test('validate() throws when endpoint/projectId are missing', () {
    // Tests run without --dart-define values, so these fields are empty —
    // proving there are no hardcoded fallbacks left in the codebase.
    expect(AppwriteConfig.endpoint, isEmpty);
    expect(AppwriteConfig.projectId, isEmpty);
    expect(AppwriteConfig.validate, throwsStateError);
  });

  test('adminTeamId defaults to "admins"', () {
    expect(AppwriteConfig.adminTeamId, 'admins');
  });
}
