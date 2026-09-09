import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// SDK boundary that lets widget tests exercise real loading/ownership logic
/// with a synthetic view instead of skipping the entire ad lifecycle.
class AdWidgetRuntime {
  const AdWidgetRuntime();

  bool get isSupported =>
      !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  Future<AdSize> adaptiveBannerSize(int width) async =>
      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width) ??
      AdSize.banner;

  Widget buildAd(AdWithView ad) => AdWidget(ad: ad);
}

final adWidgetRuntimeProvider = Provider<AdWidgetRuntime>(
  (ref) => const AdWidgetRuntime(),
);
