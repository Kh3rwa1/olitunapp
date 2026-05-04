import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/video_player_widget.dart';
import '../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../providers/onboarding_provider.dart';
import 'widgets/onboarding_slide.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _scrollOffset = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    context.go('/');
  }

  /// Determine if this is a desktop/wide screen where video onboarding is skipped
  bool get _isDesktop {
    if (!kIsWeb) return false;
    final width = MediaQuery.of(context).size.width;
    return width > 900;
  }

  @override
  Widget build(BuildContext context) {
    // On desktop/web wide screens, skip the video onboarding entirely
    if (_isDesktop) {
      // Auto-complete onboarding and redirect
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeOnboarding();
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get dynamic video URL (from admin panel) or fall back to bundled asset
    final remoteVideoUrl = ref.watch(onboardingVideoUrlProvider);
    final videoPath = (remoteVideoUrl != null && remoteVideoUrl.isNotEmpty)
        ? remoteVideoUrl
        : 'assets/videos/onboarding.mp4';

    final slide = OnboardingData(
      title: 'Ultimate Journey into\nOl Chiki Mastery',
      description:
          'Experience learning like never before. Immerse yourself in the script and culture.',
      icon: Icons.rocket_launch_rounded,
      imagePath: videoPath,
      color: const Color(0xFF0F172A),
      accentColor: AppColors.primary,
      isLast: true,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _completeOnboarding,
        child: Stack(
          children: [
            // 1. Background Video (Fullscreen)
            if (videoPath.endsWith('.mp4') || videoPath.startsWith('http'))
              Positioned.fill(
                child: VideoPlayerWidget(
                  assetPath: videoPath,
                ),
              ),

            // 2. Dark Overlay Gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Enchanted Visualizer (Blended)
            Positioned.fill(
              child: EnchantedVisualizer(
                isPlaying: true,
                color: slide.accentColor.withValues(alpha: 0.5),
                height: MediaQuery.of(context).size.height,
              ),
            ),

            // 4. Content
            PageView.builder(
              controller: _pageController,
              itemCount: 1,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return OnboardingSlide(
                  data: slide,
                  offset: _scrollOffset - index,
                  onComplete: _completeOnboarding,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final String? imagePath;
  final Color color;
  final Color accentColor;
  final bool isLast;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    this.imagePath,
    required this.color,
    required this.accentColor,
    this.isLast = false,
  });
}
