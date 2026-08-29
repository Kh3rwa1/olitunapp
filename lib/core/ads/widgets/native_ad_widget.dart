import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../analytics/analytics_service.dart';
import '../../logging/app_logger.dart';
import '../../theme/app_colors.dart';
import '../ad_service.dart';
import '../ad_state.dart';

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

class _NativeAdWidgetState extends ConsumerState<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadNativeAd();
    });
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  void _loadNativeAd() {
    if (kIsWeb || !mounted) return;

    final adState = ref.read(adStateProvider);
    if (!adState.shouldShowAds) return;

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

      final adService = ref.read(adServiceProvider);
      _nativeAd = adService.createNativeAd(
        nativeTemplateStyle: templateStyle,
        onLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _isLoaded = true);
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
          } catch (_) {}
        },
        onFailed: (ad, error) {
          AppLogger.debug(
            'NativeAdWidget: Failed to load: ${error.message} (code: ${error.code})',
          );
          if (!mounted) return;
          setState(() => _isLoaded = false);
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
          } catch (_) {}
        },
        onClicked: (ad) {
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
          } catch (_) {}
        },
      );
    } catch (e) {
      AppLogger.debug('NativeAdWidget: Error loading native ad: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final adState = ref.watch(adStateProvider);
    if (!adState.shouldShowAds || !_isLoaded || _nativeAd == null) {
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
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
