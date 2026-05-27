import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'tolerant_local_file_comparator.dart';

/// Configures global test execution, setting up a 4% tolerance threshold
/// for all golden visual regression tests to ensure cross-platform resilience.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (goldenFileComparator is LocalFileComparator) {
    final testUrl = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = TolerantLocalFileComparator(
      Uri.parse('$testUrl/test.dart'),
      0.04,
    );
  }
  await testMain();
}
