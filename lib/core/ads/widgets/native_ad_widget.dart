import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../analytics/analytics_service.dart';
import '../../logging/app_logger.dart';
import '../../observability/crash_reporting.dart';
import '../../network/network_info.dart';
import '../../theme/app_colors.dart';
import '../ad_service.dart';
import '../ad_state.dart';
import 'ad_widget_runtime.dart';
import 'near_viewport_loader.dart';

/// Inline native ad. When AdMob has no native ad for the slot, the slot is
/// filled with a banner of matching size instead of staying empty, and
/// no-fill responses are not retried back-to-back.
class NativeAdWidget extends ConsumerStatefulWidget {
  final String placement;
  final double height;
  final TemplateType templateType;

  /// Optional styling so the ad matches the surface it sits in (a lesson
  /// card, a studio panel). The template keeps Google's "Ad" badge.
  final Color? accentColor;
  final Color? backgroundColor;
  final double cornerRadius;

  const NativeAdWidget({
    super.key,
    this.placement = 'list_inline',
    this.height = 100,
    this.templateType = TemplateType.small,
    this.accentColor,
    this.backgroundColor,
    this.cornerRadius = 20,
  });

  /// Larger template with a media view; earns more where there is room.
  const NativeAdWidget.medium({
    super.key,
    required this.placement,
    this.accentColor,
    this.backgroundColor,
    this.cornerRadius = 20,
  }) : height = 320,
       templateType = TemplateType.medium;

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget>
    with WidgetsBindingObserver, NearViewportLoader {
  /// Either the native ad or the fallback banner currently on screen.
  AdWithView? _ad;
  bool _isLoaded = false;
  bool _hasPersistentError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const int _maxNoFillRetries = 2;
  static const Duration _noFillRetryDelay = Duration(seconds: 60);
  Timer? _retryTimer;
  late final AdService _adService;
  late final AdWidgetRuntime _runtime;
  int _generation = 0;
  bool _refreshScheduled = false;

  bool get _isMedium => widget.templateType == TemplateType.medium;

  @override
  void initState() {
    super.initState();
    _adService = ref.read(adServiceProvider);
    _runtime = ref.read(adWidgetRuntimeProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadWhenNearViewport(_loadNativeAd);
    });
  }

  bool _accepts(int generation) =>
      mounted &&
      generation == _generation &&
      ref.read(adStateProvider).shouldShowAds;

  void _releaseAfterFrame(Ad ad) {
    // The old platform view must leave the tree before its native ID is freed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adService.releaseAd(ad);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _clearAd() {
    _generation++;
    _retryTimer?.cancel();
    final ad = _ad;
    _ad = null;
    _isLoaded = false;
    if (mounted) setState(() {});
    if (ad != null) _releaseAfterFrame(ad);
  }

  void _scheduleRefresh() {
    if (!mounted) return;
    _generation++;
    _retryTimer?.cancel();
    if (_refreshScheduled) return;
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      if (ref.read(adStateProvider).shouldShowAds) {
        _hasPersistentError = false;
        _retryCount = 0;
        _loadNativeAd();
      } else {
        _clearAd();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void didHaveMemoryPressure() {
    if (mounted) _clearAd();
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    _retryTimer?.cancel();
    final ad = _ad;
    _ad = null;
    if (ad != null) _adService.releaseAd(ad);
    super.dispose();
  }

  void _logEvent(AdEventType type, String format, [String? errorCode]) {
    // A click leaves the app; coming back is not a new visit.
    if (type == AdEventType.click) _adService.skipNextAppOpen();
    try {
      ref
          .read(learningAnalyticsServiceProvider)
          .logAdEvent(
            AdEvent(
              type: type,
              adFormat: format,
              placement: widget.placement,
              errorCode: errorCode,
            ),
          );
    } catch (e) {
      AppLogger.warning('NativeAdWidget: failed to log $format event: $e');
    }
  }

  void _onAdLoaded(Ad ad, int generation, String format) {
    _adService.takeOwnership(ad);
    if (!_accepts(generation)) {
      _releaseAfterFrame(ad);
      return;
    }
    _adService.recordFill(format);
    final previous = _ad;
    if (previous != null && !identical(previous, ad)) {
      _releaseAfterFrame(previous);
    }
    setState(() {
      _ad = ad as AdWithView;
      _isLoaded = true;
      _retryCount = 0;
      _hasPersistentError = false;
    });
    _logEvent(AdEventType.impression, format);
  }

  void _loadNativeAd() {
    if (!mounted || !_runtime.isSupported) return;

    final adState = ref.read(adStateProvider);
    if (!adState.shouldShowAds || _hasPersistentError) return;

    // Native demand is paused after repeated no-fills: use the banner slot.
    if (_adService.noFillWait('native') > Duration.zero) {
      _loadFallbackBanner();
      return;
    }

    _clearAd();
    final generation = _generation;

    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final accent = widget.accentColor ?? const Color(0xFF6C5CE7);
      final templateStyle = NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: _background(isDark),
        cornerRadius: widget.cornerRadius - 4,
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

      final nativeAd = _adService.createNativeAd(
        nativeTemplateStyle: templateStyle,
        onLoaded: (ad) => _onAdLoaded(ad, generation, 'native'),
        onFailed: (ad, error) {
          AppLogger.debug(
            'NativeAdWidget: Failed to load: ${error.message} (code: ${error.code})',
          );
          if (!_accepts(generation)) return;
          _generation++;
          setState(() {
            _ad = null;
            _isLoaded = false;
          });
          _logEvent(AdEventType.loadFail, 'native', error.code.toString());
          if (AdService.isNoFill(error)) {
            _adService.recordNoFill('native');
            _loadFallbackBanner();
          } else {
            _scheduleRetry();
          }
        },
        onClicked: (ad) {
          if (_accepts(generation)) _logEvent(AdEventType.click, 'native');
        },
      );
      _ad = nativeAd;

      if (nativeAd == null) {
        _scheduleRetry();
      }
    } catch (error, stack) {
      CrashReporting.recordError(error, stack);
      if (_accepts(generation)) _scheduleRetry();
    }
  }

  Color _background(bool isDark) =>
      widget.backgroundColor ??
      (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface);

  /// Fill the slot with a fixed-size banner when native has no ad.
  void _loadFallbackBanner() {
    if (!mounted || !ref.read(adStateProvider).shouldShowAds) return;
    final bannerWait = _adService.noFillWait('banner');
    if (bannerWait > Duration.zero) {
      _scheduleNoFillRetry(bannerWait);
      return;
    }

    _clearAd();
    final generation = _generation;
    try {
      final banner = _adService.createBannerAd(
        size: _isMedium ? AdSize.mediumRectangle : AdSize.largeBanner,
        onLoaded: (ad) => _onAdLoaded(ad, generation, 'banner'),
        onFailed: (ad, error) {
          if (!_accepts(generation)) return;
          _generation++;
          setState(() {
            _ad = null;
            _isLoaded = false;
          });
          _logEvent(AdEventType.loadFail, 'banner', error.code.toString());
          if (AdService.isNoFill(error)) {
            _adService.recordNoFill('banner');
            _scheduleNoFillRetry(_noFillRetryDelay);
          } else {
            _scheduleRetry();
          }
        },
        onClicked: (ad) {
          if (_accepts(generation)) _logEvent(AdEventType.click, 'banner');
        },
      );
      _ad = banner;
      if (banner == null) _scheduleRetry();
    } catch (error, stack) {
      CrashReporting.recordError(error, stack);
      if (_accepts(generation)) _scheduleRetry();
    }
  }

  /// Nothing to show right now: try once more later instead of hammering.
  void _scheduleNoFillRetry(Duration delay) {
    if (!mounted || !ref.read(adStateProvider).shouldShowAds) return;
    if (_retryCount >= _maxNoFillRetries) {
      setState(() => _hasPersistentError = true);
      return;
    }
    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(
      delay < _noFillRetryDelay ? _noFillRetryDelay : delay,
      () {
        if (mounted && !_isLoaded) _loadNativeAd();
      },
    );
  }

  void _scheduleRetry() {
    if (!mounted || !ref.read(adStateProvider).shouldShowAds) return;
    if (_retryCount >= _maxRetries) {
      setState(() => _hasPersistentError = true);
      AppLogger.debug('NativeAdWidget: Max retries exceeded. Hiding ad.');
      return;
    }

    _retryCount++;
    // Network/internal errors: 5s, 15s, 45s.
    final delaySeconds = 5 * [1, 3, 9][_retryCount - 1];
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted && !_isLoaded) {
        _loadNativeAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_runtime.isSupported) return const SizedBox.shrink();

    ref.listen<AdState>(adStateProvider, (previous, next) {
      if (previous?.shouldShowAds != next.shouldShowAds) _scheduleRefresh();
    });

    // Auto-recover when connectivity restored
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        final wasOffline =
            previous?.value?.contains(ConnectivityResult.none) ?? false;
        final isOnline =
            !(next.value?.contains(ConnectivityResult.none) ?? true);
        if (wasOffline && isOnline && (!_isLoaded || _hasPersistentError)) {
          _scheduleRefresh();
        }
      },
    );
    final adState = ref.watch(adStateProvider);
    final ad = _ad;
    if (!adState.shouldShowAds || !_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (ad is BannerAd) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: KeyedSubtree(key: ObjectKey(ad), child: _runtime.buildAd(ad)),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: widget.height,
      decoration: BoxDecoration(
        color: _background(isDark),
        borderRadius: BorderRadius.circular(widget.cornerRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.cornerRadius),
        child: KeyedSubtree(key: ObjectKey(ad), child: _runtime.buildAd(ad)),
      ),
    );
  }
}
