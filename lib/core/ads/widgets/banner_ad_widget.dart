import 'dart:async';
import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../analytics/analytics_service.dart';
import '../../logging/app_logger.dart';
import '../../network/network_info.dart';
import '../../theme/app_colors.dart';
import '../ad_service.dart';
import '../ad_state.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  final String placement;

  const BannerAdWidget({super.key, this.placement = 'default_bottom'});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _hasPersistentError = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  Timer? _retryTimer;
  Orientation? _lastOrientation;
  double? _lastWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadAd();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (kIsWeb || !mounted) return;
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) return;

    final adState = ref.read(adStateProvider);
    if (!adState.shouldShowAds || _hasPersistentError) {
      return;
    }

    final width = MediaQuery.of(context).size.width.truncate();
    if (width <= 0) return;

    _lastWidth = width.toDouble();
    _lastOrientation = MediaQuery.of(context).orientation;

    try {
      // Sizing: adaptive anchored banner or standard banner
      final adSize =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            width,
          ) ??
          AdSize.banner;

      if (!mounted) return;

      _bannerAd?.dispose();
      _bannerAd = null;

      final adService = ref.read(adServiceProvider);
      _bannerAd = adService.createBannerAd(
        size: adSize,
        onLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
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
          if (!mounted) return;
          setState(() => _isLoaded = false);
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
    } catch (e) {
      AppLogger.debug('BannerAdWidget: Error loading banner ad: $e');
    }
  }

  void _scheduleRetry() {
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
    if (kIsWeb) return const SizedBox.shrink();

    ref.listen<AdState>(adStateProvider, (previous, next) {
      if (previous?.shouldShowAds != next.shouldShowAds) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (next.shouldShowAds) {
            _loadAd();
          } else {
            _bannerAd?.dispose();
            _bannerAd = null;
            setState(() => _isLoaded = false);
          }
        });
      }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAd();
      });
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
          setState(() {
            _hasPersistentError = false;
            _retryCount = 0;
          });
          _loadAd();
        }
      },
    );

    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
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
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
