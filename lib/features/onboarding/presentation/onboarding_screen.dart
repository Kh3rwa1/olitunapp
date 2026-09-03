import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/languages/providers/target_language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/widgets/minimum_tap_target.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../rhymes/presentation/widgets/enchanted_visualizer.dart';
import '../providers/onboarding_provider.dart';

part 'onboarding_steps.dart';
part 'onboarding_goals_step.dart';
part 'onboarding_language_steps.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 6;
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Local state for user choices during onboarding.
  // Indigenous target language is permanent: Santali ('sat').
  // Teaching / Mother Tongue language must be selected by the learner.
  String? _selectedTeachingLanguage;
  LearnerLevel _selectedLevel = LearnerLevel.beginner;
  String _selectedScriptMode = 'both';
  int _selectedDailyGoal = 5;
  final List<String> _selectedGoals = [];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectTeachingLanguage(String code) {
    setState(() {
      _selectedTeachingLanguage = code;
    });
  }

  Future<void> _completeOnboarding() async {
    final teachingLang = _selectedTeachingLanguage ?? 'en';

    // Target indigenous language is permanent: Santali ('sat')
    await ref
        .read(targetLanguageCodeProvider.notifier)
        .selectLanguage(kDefaultTargetLanguage);

    // Save teaching/UI language (English, Hindi, Bengali, Odia, Santali)
    updateAppLanguage(ref, teachingLang);
    updateTeachingLanguage(ref, teachingLang);

    // Save choices to local settings
    updateLearnerLevel(ref, _selectedLevel);
    updateScriptMode(ref, _selectedScriptMode);
    updateDailyGoalMinutes(ref, _selectedDailyGoal);

    // Save onboarding preferences to user prefs in Appwrite if logged in
    await ref
        .read(authControllerProvider)
        .syncOnboardingPreferences(
          targetLanguage: kDefaultTargetLanguage,
          teachingLanguage: teachingLang,
          goals: _selectedGoals,
        );

    // Mark onboarding completed
    await ref.read(onboardingProvider.notifier).completeOnboarding();

    if (mounted) {
      context.go('/');
    }
  }

  void _nextStep() {
    // Step 1 is the mandatory Teaching / Mother Tongue language selection step
    if (_currentStep == 1 && _selectedTeachingLanguage == null) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please select your mother tongue / teaching language to continue.',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
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

  void _selectLevel(LearnerLevel level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _selectScriptMode(String mode) {
    setState(() {
      _selectedScriptMode = mode;
    });
  }

  void _selectDailyGoal(int goal) {
    setState(() {
      _selectedDailyGoal = goal;
    });
  }

  void _toggleGoal(String goalId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedGoals.remove(goalId);
      } else {
        _selectedGoals.add(goalId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final reduceVisualEffects = ref.watch(reduceVisualEffectsProvider);

    final showAnimations = !reduceMotion && !reduceVisualEffects;
    final isMandatoryPending =
        _currentStep == 1 && _selectedTeachingLanguage == null;
    final canSkip = _currentStep != 1 || _selectedTeachingLanguage != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Stack(
            children: [
              // Dark/Light Overlay Gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              AppColors.darkBackground.withValues(alpha: 0.3),
                              AppColors.darkBackground.withValues(alpha: 0.8),
                              AppColors.darkBackground,
                            ]
                          : [
                              AppColors.lightBackground.withValues(alpha: 0.6),
                              AppColors.lightBackground.withValues(alpha: 0.9),
                              AppColors.lightBackground,
                            ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Enchanted Visualizer (Blended for Step 0 only)
              if (showAnimations && _currentStep == 0)
                Positioned.fill(
                  child: EnchantedVisualizer(
                    isPlaying: true,
                    color: AppColors.primary.withValues(alpha: 0.3),
                    height: MediaQuery.of(context).size.height,
                  ),
                ),

              // Safe Area UI Elements
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
                                value: (_currentStep + 1) / _totalSteps,
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
                          // Skip Button: Hidden if mandatory language selection is pending
                          if (canSkip && _currentStep < _totalSteps - 1)
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
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 44),
                        ],
                      ),
                    ),

                    // Main Page View (Step content)
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ValuePropStep(isDark: isDark),
                          _TeachingLanguageStep(
                            isDark: isDark,
                            selectedLanguage: _selectedTeachingLanguage,
                            onSelected: _selectTeachingLanguage,
                          ),
                          _LevelStep(
                            isDark: isDark,
                            selectedLevel: _selectedLevel,
                            onSelected: _selectLevel,
                          ),
                          _ScriptStep(
                            isDark: isDark,
                            selectedScriptMode: _selectedScriptMode,
                            onSelected: _selectScriptMode,
                          ),
                          _DailyGoalStep(
                            isDark: isDark,
                            selectedDailyGoal: _selectedDailyGoal,
                            onSelected: _selectDailyGoal,
                          ),
                          _GoalsStep(
                            isDark: isDark,
                            selectedGoals: _selectedGoals,
                            onToggleGoal: _toggleGoal,
                          ),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isMandatoryPending
                                  ? (isDark
                                        ? [Colors.white12, Colors.white10]
                                        : [Colors.black12, Colors.black26])
                                  : (isDark
                                        ? [
                                            AppColors.primary,
                                            AppColors.primaryDark,
                                          ]
                                        : [
                                            AppColors.primary,
                                            AppColors.brandTextLight,
                                          ]),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isMandatoryPending)
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _currentStep == _totalSteps - 1
                                ? 'Start Learning'
                                : (isMandatoryPending
                                      ? 'Select Teaching Language'
                                      : 'Continue'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isMandatoryPending
                                  ? (isDark ? Colors.white60 : Colors.black54)
                                  : Colors.white,
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
        ),
      ),
    );
  }
}
