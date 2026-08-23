import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tolerant_local_file_comparator.dart';

/// Font families declared in pubspec.yaml, loaded explicitly so that text
/// renders identically on every platform (local macOS, Linux CI) instead of
/// falling back to the placeholder test font.
const Map<String, List<String>> _kTestFontAssets = <String, List<String>>{
  'Poppins': <String>[
    'fonts/Poppins-Regular.ttf',
    'fonts/Poppins-SemiBold.ttf',
    'fonts/Poppins-Bold.ttf',
  ],
  // Material's default family; mapped to a bundled font for deterministic
  // glyph metrics across hosts.
  'Roboto': <String>['fonts/Poppins-Regular.ttf'],
  'OlChiki': <String>['fonts/OlChiki.ttf'],
};

Future<void> _loadTestFonts() async {
  for (final MapEntry<String, List<String>> family
      in _kTestFontAssets.entries) {
    final FontLoader loader = FontLoader(family.key);
    for (final String path in family.value) {
      final File file = File(path);
      if (!file.existsSync()) {
        continue;
      }
      final Uint8List bytes = file.readAsBytesSync();
      loader.addFont(Future<ByteData>.value(bytes.buffer.asByteData()));
    }
    await loader.load();
  }
}

/// Configures global test execution, setting up a 4% tolerance threshold
/// for all golden visual regression tests to ensure cross-platform resilience.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  if (goldenFileComparator is LocalFileComparator) {
    final Uri testUrl = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = TolerantLocalFileComparator(
      Uri.parse('$testUrl/test.dart'),
      0.04,
    );
  }
  await _loadTestFonts();
  await testMain();
}
