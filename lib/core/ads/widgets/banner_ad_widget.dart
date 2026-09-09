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

class BannerAdWidget extends ConsumerStatefulWidget {
  final String placement;

  const BannerAdWidget({super.key, this.placement = 'default_bottom'});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget>
    with WidgetsBindingObserver {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasPersistentError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;
  late final AdService _adService;
  late final AdWidgetRuntime _runtime;
  int _generation = 0;
  bool _refreshScheduled = false;
  Orientation? _lastOrientation;
  double? _lastWidth;

  @override
  void initState() {
    super.initState();
    _adService = ref.read(adServiceProvider);
    _runtime = ref.read(adWidgetRuntimeProvider);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAd();
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
    final ad = _bannerAd;
    _bannerAd = null;
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
        _loadAd();
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
    final ad = _bannerAd;
    _bannerAd = null;
    if (ad != null) _adService.releaseAd(ad);
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (!mounted || !_runtime.isSupported) return;

    final adState = ref.read(adStateProvider);
    if (!adState.shouldShowAds || _hasPersistentError) {
      return;
    }

    final width = MediaQuery.of(context).size.width.truncate();
    if (width <= 0) return;

    _clearAd();
    final generation = _generation;

    _lastWidth = width.toDouble();
    _lastOrientation = MediaQuery.of(context).orientation;

    try {
      final adSize = await _runtime.adaptiveBannerSize(width);
      if (!_accepts(generation)) return;

      _bannerAd = _adService.createBannerAd(
        size: adSize,
        onLoaded: (ad) {
          _adService.takeOwnership(ad);
          if (!_accepts(generation)) {
            _releaseAfterFrame(ad);
            return;
          }
          final previous = _bannerAd;
          if (previous != null && !identical(previous, ad)) {
            _releaseAfterFrame(previous);
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _retryCount = 0;
            _hasPersistentError = false;
          });
          ref.read(adStateProvider.notifier).resetErrors('banner');
          try {
            ref
                .read(learningAnalyticsServiceProvider)
                .logAdEvent(
                  AdEvent(
                    type: AdEventType.impression,
                    adFormat: 'banner',
                    placement: widget.placement,
                  ),
                );
          } catch (e) {
            AppLogger.warning(
              'BannerAdWidget: failed to log impression event: $e',
            );
          }
        },
        onFailed: (ad, error) {
          AppLogger.debug('BannerAdWidget: Failed to load: ${error.message}');
          if (!_accepts(generation)) return;
          _generation++;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
          ref.read(adStateProvider.notifier).recordError('banner');
          try {
            ref
                .read(learningAnalyticsServiceProvider)
                .logAdEvent(
                  AdEvent(
                    type: AdEventType.loadFail,
                    adFormat: 'banner',
                    placement: widget.placement,
                    errorCode: error.code.toString(),
                  ),
                );
          } catch (e) {
            AppLogger.warning(
              'BannerAdWidget: failed to log load-fail event: $e',
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
                    adFormat: 'banner',
                    placement: widget.placement,
                  ),
                );
          } catch (e) {
            AppLogger.warning(
              'BannerAdWidget: failed to log impression event: $e',
            );
          }
        },
      );

      if (_bannerAd == null) {
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
      AppLogger.debug('BannerAdWidget: Max retries exceeded. Hiding banner.');
      return;
    }

    _retryCount++;
    final delaySeconds = 1 << (_retryCount - 1); // 1s, 2s, 4s
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (mounted && !_isLoaded) {
        _loadAd();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_runtime.isSupported) return const SizedBox.shrink();

    ref.listen<AdState>(adStateProvider, (previous, next) {
      if (previous?.shouldShowAds != next.shouldShowAds) _scheduleRefresh();
    });
    final adState = ref.watch(adStateProvider);
    if (!adState.shouldShowAds || _hasPersistentError) {
      return const SizedBox.shrink();
    }

    // Reload if orientation changed
    final currentOrientation = MediaQuery.of(context).orientation;
    final currentWidth = MediaQuery.of(context).size.width;
    if (_lastOrientation != null &&
        (_lastOrientation != currentOrientation ||
            (_lastWidth != null && (_lastWidth! - currentWidth).abs() > 50))) {
      _lastOrientation = currentOrientation;
      _lastWidth = currentWidth;
      _scheduleRefresh();
    }

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

    final ad = _bannerAd;
    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: KeyedSubtree(key: ObjectKey(ad), child: _runtime.buildAd(ad)),
    );
  }
}
