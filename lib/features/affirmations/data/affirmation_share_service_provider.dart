import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/affirmation_share_service.dart';
import 'affirmation_share_service_io.dart'
    if (dart.library.js_interop) 'affirmation_share_service_web.dart';

final affirmationShareServiceProvider = Provider<AffirmationShareService>((
  ref,
) {
  return AffirmationShareServiceImpl();
});
