import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Settings must push the legal pages, not `go` to them: `go` replaced the
/// stack, so Back from Terms/Privacy left the app instead of returning to
/// Settings.
void main() {
  test('Settings opens Privacy and Terms with push', () {
    final source = File(
      'lib/features/profile/presentation/widgets/settings_bento_sections.dart',
    ).readAsStringSync();
    for (final path in ['/privacy', '/terms']) {
      expect(source, contains("context.push('$path')"));
      expect(source, isNot(contains("context.go('$path')")));
    }
  });
}
