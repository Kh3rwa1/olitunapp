import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import '../theme/app_colors.dart';
import 'ad_service.dart';
import 'ad_state.dart';

/// Template styling shared by on-the-spot and preloaded native ads.
NativeTemplateStyle olitunNativeTemplateStyle({
  required TemplateType templateType,
  required bool isDark,
  Color? accentColor,
  Color? backgroundColor,
  double cornerRadius = 20,
}) {
  final accent = accentColor ?? const Color(0xFF6C5CE7);
  return NativeTemplateStyle(
    templateType: templateType,
    mainBackgroundColor: olitunNativeBackground(isDark, backgroundColor),
    cornerRadius: cornerRadius - 4,
    callToActionTextStyle: NativeTemplateTextStyle(
      textColor: accent.computeLuminance() > 0.5
          ? Colors.black87
          : Colors.white,
      backgroundColor: accent,
      style: NativeTemplateFontStyle.bold,
      size: 13.0,
    ),
    primaryTextStyle: NativeTemplateTextStyle(
      textColor: isDark ? Colors.white : Colors.black87,
      style: NativeTemplateFontStyle.bold,
      size: 13.0,
    ),
    secondaryTextStyle: NativeTemplateTextStyle(
      textColor: isDark ? Colors.white70 : Colors.black54,
      size: 12.0,
    ),
    tertiaryTextStyle: NativeTemplateTextStyle(
      textColor: isDark ? Colors.white54 : Colors.black45,
      size: 11.0,
    ),
  );
}

Color olitunNativeBackground(bool isDark, [Color? override]) =>
    override ??
    (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface);

/// Keeps one ready-to-show native ad per (template, brightness) in default
/// styling. Slots in short visits (AI Studio, Voice, Translator) take one
/// instantly instead of depending on a single request at that moment; the
/// pool then refills in the background.
class NativeAdPool {
  NativeAdPool(this._service);

  final AdService _service;
  final Map<String, ({NativeAd ad, DateTime loadedAt})> _ready = {};
  final Set<String> _loading = {};

  static String keyFor(TemplateType type, bool isDark) =>
      '${type.name}-${isDark ? 'dark' : 'light'}';

  /// A preloaded ad, or null. The caller owns (and must dispose) it.
  NativeAd? take(TemplateType type, bool isDark) {
    final entry = _ready.remove(keyFor(type, isDark));
    if (entry == null) return null;
    if (DateTime.now().difference(entry.loadedAt) > AdConfig.fullScreenAdTtl) {
      _service.releaseAd(entry.ad);
      return null;
    }
    return entry.ad;
  }

  /// Start a background load for this slot shape unless one is ready or in
  /// flight, or native demand is paused after no-fills.
  void warm(TemplateType type, bool isDark) {
    final key = keyFor(type, isDark);
    if (_ready.containsKey(key) || _loading.contains(key)) return;
    if (_service.noFillWait('native') > Duration.zero) return;
    _loading.add(key);
    final ad = _service.createNativeAd(
      nativeTemplateStyle: olitunNativeTemplateStyle(
        templateType: type,
        isDark: isDark,
      ),
      onLoaded: (ad) {
        _loading.remove(key);
        _service.takeOwnership(ad);
        _service.recordFill('native');
        _ready[key] = (ad: ad as NativeAd, loadedAt: DateTime.now());
      },
      onFailed: (ad, error) {
        _loading.remove(key);
        if (AdService.isNoFill(error)) _service.recordNoFill('native');
      },
      // A click leaves the app; coming back is not a new visit.
      onClicked: (_) => _service.skipNextAppOpen(),
    );
    if (ad == null) _loading.remove(key);
  }

  void clear() {
    for (final entry in _ready.values) {
      _service.releaseAd(entry.ad);
    }
    _ready.clear();
    _loading.clear();
  }
}

final nativeAdPoolProvider = Provider<NativeAdPool>((ref) {
  final pool = NativeAdPool(ref.read(adServiceProvider));
  ref.onDispose(pool.clear);
  return pool;
});

/// Preloads one medium and one small native ad a few seconds after ads
/// become available, in the device's current brightness. Watched once from
/// the app root.
final nativeAdPoolWarmupProvider = Provider<void>((ref) {
  ref.listen<AdState>(adStateProvider, (previous, next) {
    if (!next.shouldShowAds || previous?.shouldShowAds == true) return;
    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!ref.read(adStateProvider).shouldShowAds) return;
      final isDark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
      ref.read(nativeAdPoolProvider)
        ..warm(TemplateType.medium, isDark)
        ..warm(TemplateType.small, isDark);
    });
  }, fireImmediately: true);
});
