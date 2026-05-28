import 'build_version_checker_io.dart'
    if (dart.library.html) 'build_version_checker_html.dart' as impl;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'build_version_status.dart';

Stream<BuildVersionStatus> getBuildVersionStream(Ref ref) => impl.getBuildVersionStream(ref);


