import 'package:flutter/foundation.dart';

const String kOlitunNativeAdFactoryId = 'olitun_list_tile_native_ad';

/// Registers native ad factories if supported on platform.
void registerOlitunNativeAdFactory() {
  if (kIsWeb) return;
  // Platform native factory registration (Android/iOS native side or custom view factory)
}
