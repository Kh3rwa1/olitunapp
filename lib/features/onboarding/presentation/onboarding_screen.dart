import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
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

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: 'Unlock Your\nChild\'s Potential',
      description:
          'Dive into a world where learning is a delightful journey. From words to numbers, let your child explore.',
      icon: Icons.auto_stories_rounded,
      imagePath: 'assets/images/onboarding_1.png',
      color: const Color(0xFFF0F9FF),
      accentColor: AppColors.duoBlue,
    ),
    OnboardingData(
      title: 'Adventure in\nevery lesson!',
      description:
          'A perfect day at the park. Every lesson is an adventure designed to spark curiosity and joy.',
      icon: Icons.fort_rounded,
      imagePath: 'assets/images/onboarding_2.png',
      color: const Color(0xFFFFF7ED),
      accentColor: AppColors.duoOrange,
    ),
    OnboardingData(
      title: 'Ready to\nStart Journey?',
      description:
          'You\'re just one click away from finding the expertise and knowledge to master Ol Chiki.',
      icon: Icons.rocket_launch_rounded,
      imagePath: 'assets/images/onboarding_3.png',
      color: const Color(0xFFF0FDF4),
      accentColor: AppColors.primary,
      isLast: true,
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int currentPage = _scrollOffset.round();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : _slides[currentPage].color,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return OnboardingSlide(
                data: _slides[index],
                offset: _scrollOffset - index,
              );
            },
          ),

          // Custom Floating Navigation Bar
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.black45 : Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Page Indicators
                  Expanded(
                    child: Row(
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: 300.ms,
                          margin: const EdgeInsets.only(right: 8),
                          height: 8,
                          width: currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: currentPage == index
                                ? _slides[index].accentColor
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Action Button
                  GestureDetector(
                        onTap: () {
                          if (currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: 600.ms,
                              curve: Curves.easeOutQuart,
                            );
                          } else {
                            ref
                                .read(onboardingProvider.notifier)
                                .completeOnboarding();
                            context.go('/home');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _slides[currentPage].accentColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _slides[currentPage].accentColor
                                    .withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                currentPage == _slides.length - 1
                                    ? 'START'
                                    : 'NEXT',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                currentPage == _slides.length - 1
                                    ? Icons.rocket_launch_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate(target: 1)
                      .scale(
                        begin: const Offset(0.9, 0.9),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 1, end: 0),
        ],
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
