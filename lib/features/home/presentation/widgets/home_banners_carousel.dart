import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content_models.dart';
import '../../../../shared/providers/providers.dart';

class HomeBannersCarousel extends ConsumerStatefulWidget {
  final bool isDark;
  final bool autoScroll;

  const HomeBannersCarousel({
    super.key,
    required this.isDark,
    this.autoScroll = true,
  });

  @override
  ConsumerState<HomeBannersCarousel> createState() =>
      _HomeBannersCarouselState();
}

class _HomeBannersCarouselState extends ConsumerState<HomeBannersCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _autoScrollTimer?.cancel();
    if (count <= 1) return;
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  LinearGradient _gradient(String preset) {
    switch (preset) {
      case 'peach':
        return AppColors.peachGradient;
      case 'mint':
        return AppColors.mintGradient;
      case 'sunset':
        return AppColors.sunsetGradient;
      case 'purple':
        return AppColors.premiumPurple;
      case 'skyBlue':
      default:
        return AppColors.skyBlueGradient;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(featuredBannersProvider);

    return bannersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
      data: (all) {
        final banners = all.where((b) => b.isActive).toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        if (banners.isEmpty) return const SizedBox.shrink();

        // Start / restart the timer whenever banner list changes if autoScroll is enabled
        if (widget.autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startAutoScroll(banners.length);
          });
        }

        return Column(
          children: [
            SizedBox(
              height: 148,
              child: PageView.builder(
                controller: _pageController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _BannerSlide(
                      banner: banners[index],
                      gradient: _gradient(banners[index].gradientPreset),
                      isDark: widget.isDark,
                      index: index,
                    ),
                  );
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 12),
              _DotIndicator(
                count: banners.length,
                current: _currentPage,
                isDark: widget.isDark,
              ),
            ],
          ],
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06, end: 0);
      },
    );
  }
}

// ─── Individual slide ────────────────────────────────────────────────────────

class _BannerSlide extends StatelessWidget {
  final FeaturedBannerModel banner;
  final LinearGradient gradient;
  final bool isDark;
  final int index;

  const _BannerSlide({
    required this.banner,
    required this.gradient,
    required this.isDark,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final hasRoute =
        banner.targetRoute != null && banner.targetRoute!.isNotEmpty;

    return PressableScale(
      onTap: hasRoute ? () => context.push(banner.targetRoute!) : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient orb — top-right
            Positioned(
              right: -32,
              top: -32,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            // Ambient orb — bottom-left
            Positioned(
              left: -24,
              bottom: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),

            // Optional network image with vignette
            if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        banner.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                      // dark vignette so text stays readable
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Text content
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (banner.subtitle != null &&
                      banner.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      banner.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (hasRoute) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Learn more',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dot indicators ──────────────────────────────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final bool isDark;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: MotionTokens.short,
          curve: MotionTokens.standard,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.12)),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
