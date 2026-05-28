import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'build_version_status.dart';

Stream<BuildVersionStatus> getBuildVersionStream(Ref ref) {
  return Stream.value(const BuildVersionMatch());
}


