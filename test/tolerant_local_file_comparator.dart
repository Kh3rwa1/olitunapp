import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A custom golden file comparator that permits a small percentage of difference.
/// This prevents golden tests from failing due to minor platform rendering artifacts
/// (such as anti-aliasing or font differences between local macOS and Linux CI).
class TolerantLocalFileComparator extends LocalFileComparator {
  final double tolerance;

  TolerantLocalFileComparator(super.testFile, this.tolerance)
    : assert(tolerance >= 0 && tolerance <= 1);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= tolerance) {
      if (!result.passed) {
        debugPrint(
          'Accepted golden difference: ${(result.diffPercent * 100).toStringAsFixed(2)}%',
        );
      }
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
