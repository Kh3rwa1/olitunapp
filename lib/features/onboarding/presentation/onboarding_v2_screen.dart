import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/auth/appwrite_auth_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/language_settings_providers.dart';
import '../../../shared/providers/local_settings_provider.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../providers/onboarding_provider.dart';

/// Five-step onboarding for the multilingual audio-first experience.
///
/// Steps: interface+teaching language → Santali proficiency → learning
/// goals → lesson audio mode → daily goal / optional sign-in / starter
/// audio. Every choice is written to SharedPreferences at tap time, so
/// guest learners are never blocked and nothing is lost on early exit.
/// Shown only when `onboardingV2Enabled` is on (see `OnboardingGate`).
class OnboardingV2Screen extends ConsumerStatefulWidget {
  /// [onFinished] is a test seam; in production leave null so the screen
  /// navigates home via GoRouter.
  const OnboardingV2Screen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  ConsumerState<OnboardingV2Screen> createState() => _OnboardingV2ScreenState();
}

class _OnboardingV2ScreenState extends ConsumerState<OnboardingV2Screen> {
  static const _stepCount = 5;

  final PageController _pageController = PageController();
  int _step = 0;
  bool _completing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    final reduceMotion = ref.read(reduceVisualEffectsProvider);
    _pageController.animateToPage(
      step,
      duration: Duration(milliseconds: reduceMotion ? 0 : 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _trackSelection(String eventName, Map<String, dynamic> metadata) {
    unawaited(
      ref
          .read(learningAnalyticsServiceProvider)
          .track(eventName, source: 'onboarding_v2', metadata: metadata),
    );
  }

  Future<void> _finish() async {
    if (_completing) return;
    setState(() => _completing = true);

    _trackSelection(LearningAnalyticsEvents.onboardingCompleted, {
      'interfaceLanguage': ref.read(appLanguageProvider),
      'teachingLanguage': ref.read(teachingLanguageProvider),
      'proficiency': ref.read(santaliProficiencyProvider).name,
      'audioMode': ref.read(lessonAudioModeProvider).name,
      'goalCount': ref.read(learningGoalsProvider).length,
      'dailyGoalMinutes': ref.read(dailyGoalMinutesProvider),
      'starterAudio': ref.read(starterAudioDownloadProvider),
    });

    await _syncProfileToAccount();

    // Same completion path as the splash controller.
    ref.read(onboardingProvider.notifier).completeOnboarding();

    if (!mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
    } else {
      context.go('/');
    }
  }

  /// Best-effort copy of the onboarding choices into the Appwrite account
  /// prefs. Guests and offline users simply skip it — local
  /// SharedPreferences stay the source of truth.
  Future<void> _syncProfileToAccount() async {
    try {
      final isAuthed = await ref.read(isAuthenticatedProvider.future);
      if (!isAuthed) return;
      final prefs = ref.read(sharedPreferencesProvider);
      await ref.read(appwriteAuthServiceProvider).updatePrefs({
        'interfaceLanguage': prefs.getString('app_language') ?? 'en',
        'teachingLanguage': prefs.getString(teachingLanguageKey) ?? 'en',
        'santaliProficiency': prefs.getString(santaliProficiencyKey) ?? 'none',
        'lessonAudioMode':
            prefs.getString(lessonAudioModeKey) ?? 'translationOnDemand',
        'learningGoals':
            prefs.getStringList(learningGoalsKey) ?? const <String>[],
        'dailyGoalMinutes': prefs.getInt('daily_goal_minutes') ?? 5,
      });
    } catch (e) {
      // Sync is opportunistic; never block onboarding completion on it,
      // but surface the missed account-prefs write.
      AppLogger.warning(
        'OnboardingV2Screen: account prefs sync failed: $e',
        name: 'OnboardingV2Screen',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  if (_step > 0)
                    IconButton(
                      tooltip: l10n.backButton,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: () => _goToStep(_step - 1),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_step + 1) / _stepCount,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _step = index),
                children: [
                  _buildLanguageStep(l10n, isDark),
                  _buildProficiencyStep(l10n, isDark),
                  _buildGoalsStep(l10n, isDark),
                  _buildAudioModeStep(l10n, isDark),
                  _buildReadyStep(l10n, isDark),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _completing
                      ? null
                      : () {
                          if (_step < _stepCount - 1) {
                            _goToStep(_step + 1);
                          } else {
                            _finish();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _step < _stepCount - 1
                        ? l10n.continueButton
                        : l10n.streakStartLearning,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 1: language you understand best ───

  Widget _buildLanguageStep(AppLocalizations l10n, bool isDark) {
    final current = ref.watch(appLanguageProvider);
    const options = <(String, String)>[
      ('en', 'English'),
      ('hi', 'हिंदी'),
      ('bn', 'বাংলা'),
      ('or', 'ଓଡ଼ିଆ'),
      ('sat', 'ᱥᱟᱱᱛᱟᱲᱤ'),
    ];

    return _StepScaffold(
      title: l10n.onboardingStepLanguageTitle,
      isDark: isDark,
      child: Column(
        children: [
          for (final (code, label) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                title: label,
                icon: Icons.language_rounded,
                selected: current == code,
                isDark: isDark,
                onTap: () {
                  // Normalizes, persists, couples Santali to the Ol Chiki
                  // script mode, and cascades the teaching language until
                  // the learner customizes it.
                  updateAppLanguage(ref, code);
                  _trackSelection(
                    LearningAnalyticsEvents.onboardingLanguageSelected,
                    {'interfaceLanguage': code},
                  );
                  _trackSelection(
                    LearningAnalyticsEvents.teachingLanguageSelected,
                    {
                      'teachingLanguage': ref.read(
                        effectiveTeachingLanguageProvider,
                      ),
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 2: Santali proficiency ───

  Widget _buildProficiencyStep(AppLocalizations l10n, bool isDark) {
    final current = ref.watch(santaliProficiencyProvider);
    final options = <(SantaliProficiency, String)>[
      (SantaliProficiency.none, l10n.proficiencyNone),
      (SantaliProficiency.understandsSome, l10n.proficiencyUnderstandsSome),
      (SantaliProficiency.fluentSpeaker, l10n.proficiencyFluentSpeaker),
      (SantaliProficiency.beginnerReader, l10n.proficiencyBeginnerReader),
      (SantaliProficiency.fluentReader, l10n.proficiencyFluentReader),
    ];

    return _StepScaffold(
      title: l10n.onboardingStepProficiencyTitle,
      isDark: isDark,
      child: Column(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                title: label,
                icon: Icons.record_voice_over_rounded,
                selected: current == value,
                isDark: isDark,
                onTap: () {
                  updateSantaliProficiency(ref, value);
                  _trackSelection(LearningAnalyticsEvents.proficiencySelected, {
                    'proficiency': value.name,
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 3: learning goals (multi-select) ───

  Widget _buildGoalsStep(AppLocalizations l10n, bool isDark) {
    final selected = ref.watch(learningGoalsProvider);
    final options = <(LearningGoal, String)>[
      (LearningGoal.speakSantali, l10n.goalSpeakSantali),
      (LearningGoal.understandSantali, l10n.goalUnderstandSantali),
      (LearningGoal.readOlChiki, l10n.goalReadOlChiki),
      (LearningGoal.writeOlChiki, l10n.goalWriteOlChiki),
      (LearningGoal.learnEverything, l10n.goalLearnEverything),
      (LearningGoal.helpMyChild, l10n.goalHelpMyChild),
      (LearningGoal.prepareForExam, l10n.goalPrepareExam),
    ];

    return _StepScaffold(
      title: l10n.onboardingStepGoalsTitle,
      subtitle: l10n.onboardingStepGoalsSubtitle,
      isDark: isDark,
      child: Column(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                title: label,
                icon: selected.contains(value)
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                selected: selected.contains(value),
                isDark: isDark,
                onTap: () {
                  toggleLearningGoal(ref, value);
                  _trackSelection(
                    LearningAnalyticsEvents.learningGoalSelected,
                    {'goal': value.name, 'selected': !selected.contains(value)},
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 4: lesson audio mode ───

  Widget _buildAudioModeStep(AppLocalizations l10n, bool isDark) {
    final current = ref.watch(lessonAudioModeProvider);
    final options = <(LessonAudioMode, String)>[
      (LessonAudioMode.targetOnly, l10n.audioModeTargetOnly),
      (LessonAudioMode.bilingual, l10n.audioModeBilingual),
      (LessonAudioMode.translationOnDemand, l10n.audioModeTranslationOnDemand),
    ];

    return _StepScaffold(
      title: l10n.onboardingStepAudioTitle,
      isDark: isDark,
      child: Column(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionCard(
                title: label,
                icon: Icons.headphones_rounded,
                selected: current == value,
                isDark: isDark,
                onTap: () {
                  updateLessonAudioMode(ref, value);
                  _trackSelection(LearningAnalyticsEvents.audioModeSelected, {
                    'audioMode': value.name,
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── Step 5: daily goal, starter audio, optional sign-in ───

  Widget _buildReadyStep(AppLocalizations l10n, bool isDark) {
    final dailyGoal = ref.watch(dailyGoalMinutesProvider);
    final starterAudio = ref.watch(starterAudioDownloadProvider);

    return _StepScaffold(
      title: l10n.onboardingStepReadyTitle,
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dailyGoalLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final minutes in const [5, 10, 15, 20])
                ChoiceChip(
                  label: Text(l10n.minutesPerDay(minutes)),
                  selected: dailyGoal == minutes,
                  onSelected: (_) => updateDailyGoalMinutes(ref, minutes),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.downloadStarterAudio,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            subtitle: Text(l10n.downloadStarterAudioSubtitle),
            value: starterAudio,
            onChanged: (value) => updateStarterAudioDownload(ref, value),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.person_outline_rounded),
              label: Text(l10n.guestSignInCta),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.isDark,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.black.withValues(alpha: 0.06)),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected
                      ? AppColors.primary
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
