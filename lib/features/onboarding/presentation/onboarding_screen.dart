import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/minimum_tap_target.dart';
import '../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Local state for user choices during onboarding
  LearnerLevel _selectedLevel = LearnerLevel.beginner;
  String _selectedScriptMode = 'both';
  int _selectedDailyGoal = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    // Save choices to local settings
    updateLearnerLevel(ref, _selectedLevel);
    updateScriptMode(ref, _selectedScriptMode);
    updateDailyGoalMinutes(ref, _selectedDailyGoal);

    // Mark onboarding completed
    await ref.read(onboardingProvider.notifier).completeOnboarding();

    if (mounted) {
      context.go('/');
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Determine if this is a desktop/wide screen where video onboarding is skipped
  bool get _isDesktop {
    if (!kIsWeb) return false;
    final width = MediaQuery.of(context).size.width;
    return width > 900;
  }

  @override
  Widget build(BuildContext context) {
    // On desktop/web wide screens, skip onboarding and complete
    if (_isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeOnboarding();
      });
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);

    final showAnimations = !reduceMotion && !reduceVisualEffects;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B0F19)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [


          // 2. Dark/Light Overlay Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF0B0F19).withValues(alpha: 0.3),
                          const Color(0xFF0B0F19).withValues(alpha: 0.8),
                          const Color(0xFF0B0F19),
                        ]
                      : [
                          const Color(0xFFF8FAFC).withValues(alpha: 0.6),
                          const Color(0xFFF8FAFC).withValues(alpha: 0.9),
                          const Color(0xFFF8FAFC),
                        ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // 3. Enchanted Visualizer (Blended for Step 0 only)
          if (showAnimations && _currentStep == 0)
            Positioned.fill(
              child: EnchantedVisualizer(
                isPlaying: true,
                color: AppColors.primary.withValues(alpha: 0.3),
                height: MediaQuery.of(context).size.height,
              ),
            ),

          // 4. Safe Area UI Elements
          SafeArea(
            child: Column(
              children: [
                // Top Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Back Button (hidden on Step 0)
                      Opacity(
                        opacity: _currentStep > 0 ? 1.0 : 0.0,
                        child: MinimumTapTarget(
                          onTap: _currentStep > 0 ? _prevStep : null,
                          borderRadius: BorderRadius.circular(12),
                          semanticLabel: 'Back',
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: isDark ? Colors.white70 : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Progress Line
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / 4,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? Colors.white10
                                : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? AppColors.brandTextDark
                                  : AppColors.brandTextLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Skip Button
                      MinimumTapTarget(
                        onTap: _completeOnboarding,
                        borderRadius: BorderRadius.circular(12),
                        semanticLabel: 'Skip Onboarding',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Page View (Step content)
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildValuePropStep(isDark),
                      _buildLevelStep(isDark),
                      _buildScriptStep(isDark),
                      _buildDailyGoalStep(isDark),
                    ],
                  ),
                ),

                // Bottom Navigation CTA Button
                Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: MinimumTapTarget(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _nextStep();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [AppColors.primary, const Color(0xFF10B981)]
                              : [AppColors.primary, const Color(0xFF047857)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentStep == 3 ? 'Start Learning' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // STEP 1: VALUE PROP
  Widget _buildValuePropStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Logo/Glyph Container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFE2E8F0)],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ᱚ', // Ol Chiki letter 'Ol'
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Learn Ol Chiki,\none step at a time',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start with letters, build words, practice with quizzes, and keep your Santali learning journey alive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // STEP 2: LEARNING LEVEL
  Widget _buildLevelStep(bool isDark) {
    final levels = [
      _SelectionItem(
        value: LearnerLevel.beginner,
        title: "I'm completely new",
        subtitle: 'Start from the very first letter',
        icon: Icons.baby_changing_station_rounded,
      ),
      _SelectionItem(
        value: LearnerLevel.familiar,
        title: 'I know some letters',
        subtitle: 'Review alphabet and simple characters',
        icon: Icons.auto_awesome_rounded,
      ),
      _SelectionItem(
        value: LearnerLevel.basicReader,
        title: 'I can read basic words',
        subtitle: 'Build vocabulary and short phrases',
        icon: Icons.menu_book_rounded,
      ),
      _SelectionItem(
        value: LearnerLevel.advanced,
        title: 'I want to practice fluency',
        subtitle: 'Advanced sentences, quizzes & culture',
        icon: Icons.school_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How familiar are you with Ol Chiki?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will tailor your learning path accordingly.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ...levels.map((item) {
            final isSelected = _selectedLevel == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedLevel = item.value as LearnerLevel;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.10))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // STEP 3: SCRIPT SELECTION
  Widget _buildScriptStep(bool isDark) {
    final scriptModes = [
      _SelectionItem(
        value: 'both',
        title: 'Ol Chiki + Latin',
        subtitle: 'See phonetic transliterations below the script',
        icon: Icons.chrome_reader_mode_rounded,
      ),
      _SelectionItem(
        value: 'olchiki',
        title: 'Ol Chiki only',
        subtitle: 'Focus entirely on the native script characters',
        icon: Icons.language_rounded,
      ),
      _SelectionItem(
        value: 'latin',
        title: 'Latin only',
        subtitle: 'Read Santali spelled in standard Latin alphabet',
        icon: Icons.abc_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How do you want to see content?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred script display. You can change this anytime.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ...scriptModes.map((item) {
            final isSelected = _selectedScriptMode == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedScriptMode = item.value as String;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.10))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // STEP 4: DAILY GOAL
  Widget _buildDailyGoalStep(bool isDark) {
    final dailyGoals = [
      _SelectionItem(
        value: 3,
        title: '3 minutes',
        subtitle: 'Casual practice - stay active',
        icon: Icons.bolt_rounded,
      ),
      _SelectionItem(
        value: 5,
        title: '5 minutes',
        subtitle: 'Regular practice - steady learning',
        icon: Icons.timer_rounded,
      ),
      _SelectionItem(
        value: 10,
        title: '10 minutes',
        subtitle: 'Serious practice - deep immersion',
        icon: Icons.local_fire_department_rounded,
      ),
      _SelectionItem(
        value: 15,
        title: '15 minutes',
        subtitle: 'Intense practice - hyper fast progress',
        icon: Icons.rocket_launch_rounded,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How much do you want to practice?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting a small daily goal helps build a continuous learning streak.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          ...dailyGoals.map((item) {
            final isSelected = _selectedDailyGoal == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedDailyGoal = item.value as int;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.10))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isDark ? Colors.white10 : Colors.black12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectionItem {
  final dynamic value;
  final String title;
  final String subtitle;
  final IconData icon;

  _SelectionItem({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
