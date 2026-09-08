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

class NativeAdWidget extends ConsumerStatefulWidget {
  final String placement;
  final double height;
  final TemplateType templateType;

  const NativeAdWidget({
    super.key,
    this.placement = 'list_inline',
    this.height = 100,
    this.templateType = TemplateType.small,
  });

  @override
  ConsumerState<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget>
    with WidgetsBindingObserver {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _hasPersistentError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;
  late final AdService _adService;
  late final AdWidgetRuntime _runtime;
  int _generation = 0;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    _adService = ref.read(adServiceProvider);
    _runtime = ref.read(adWidgetRuntimeProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNativeAd();
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
    final ad = _nativeAd;
    _nativeAd = null;
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
    final ad = _nativeAd;
    _nativeAd = null;
    if (ad != null) _adService.releaseAd(ad);
    super.dispose();
  }

  void _loadNativeAd() {
    if (!mounted || !_runtime.isSupported) return;

    final adState = ref.read(adStateProvider);
    if (!adState.shouldShowAds || _hasPersistentError) return;

    _clearAd();
    final generation = _generation;

    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final templateStyle = NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurface,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF6C5CE7),
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

      _nativeAd = _adService.createNativeAd(
        nativeTemplateStyle: templateStyle,
        onLoaded: (ad) {
          _adService.takeOwnership(ad);
          if (!_accepts(generation)) {
            _releaseAfterFrame(ad);
            return;
          }
          final previous = _nativeAd;
          if (previous != null && !identical(previous, ad)) {
            _releaseAfterFrame(previous);
          }
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
            _retryCount = 0;
            _hasPersistentError = false;
          });
          try {
            ref
                .read(learningAnalyticsServiceProvider)
                .logAdEvent(
                  AdEvent(
                    type: AdEventType.impression,
                    adFormat: 'native',
                    placement: widget.placement,
                  ),
                );
          } catch (e) {
            AppLogger.warning(
              'NativeAdWidget: failed to log impression event: $e',
            );
          }
        },
        onFailed: (ad, error) {
          AppLogger.debug(
            'NativeAdWidget: Failed to load: ${error.message} (code: ${error.code})',
          );
          if (!_accepts(generation)) return;
          _generation++;
          setState(() {
            _nativeAd = null;
            _isLoaded = false;
          });
          try {
            ref
                .read(learningAnalyticsServiceProvider)
                .logAdEvent(
                  AdEvent(
                    type: AdEventType.loadFail,
                    adFormat: 'native',
                    placement: widget.placement,
                    errorCode: error.code.toString(),
                  ),
                );
          } catch (e) {
            AppLogger.warning(
              'NativeAdWidget: failed to log load-fail event: $e',
            );
          }
          _scheduleRetry();
        },
        onClicked: (ad) {
          if (!_accepts(generation)) return;
          try {
            ref
                .read(learningAnalyticsServiceProvider)
                .logAdEvent(
                  AdEvent(
                    type: AdEventType.click,
                    adFormat: 'native',
                    placement: widget.placement,
                  ),
                );
          } catch (e) {
            AppLogger.warning('NativeAdWidget: failed to log click event: $e');
          }
        },
      );

      if (_nativeAd == null) {
        _scheduleRetry();
      }
    } catch (error, stack) {
      CrashReporting.recordError(error, stack);
      if (_accepts(generation)) _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!mounted || !ref.read(adStateProvider).shouldShowAds) return;
    if (_retryCount >= _maxRetries) {
      setState(() => _hasPersistentError = true);
      AppLogger.debug('NativeAdWidget: Max retries exceeded. Hiding ad.');
      return;
    }

    _retryCount++;
    final delaySeconds = 1 << (_retryCount - 1); // 1s, 2s, 4s
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
    final ad = _nativeAd;
    if (!adState.shouldShowAds || !_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
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
        borderRadius: BorderRadius.circular(20),
        child: KeyedSubtree(key: ObjectKey(ad), child: _runtime.buildAd(ad)),
      ),
    );
  }
}
