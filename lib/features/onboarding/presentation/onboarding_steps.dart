part of 'onboarding_screen.dart';

// STEP 1: VALUE PROP
class _ValuePropStep extends StatelessWidget {
  const _ValuePropStep({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
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
                    ? [AppColors.darkSurfaceElevated, AppColors.softBlack]
                    : [Colors.white, AppColors.lightBorder],
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
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Start with letters, build words, practice with quizzes, and keep your Santali learning journey alive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// STEP 2: LEARNING LEVEL
class _LevelStep extends StatelessWidget {
  const _LevelStep({
    required this.isDark,
    required this.selectedLevel,
    required this.onSelected,
  });

  final bool isDark;
  final LearnerLevel selectedLevel;
  final ValueChanged<LearnerLevel> onSelected;

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We will tailor your learning path accordingly.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...levels.map((item) {
            final isSelected = selectedLevel == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(item.value as LearnerLevel);
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
                        : (isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white),
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
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textTertiaryLight,
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

// STEP 3: SCRIPT SELECTION
class _ScriptStep extends StatelessWidget {
  const _ScriptStep({
    required this.isDark,
    required this.selectedScriptMode,
    required this.onSelected,
  });

  final bool isDark;
  final String selectedScriptMode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred script display. You can change this anytime.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...scriptModes.map((item) {
            final isSelected = selectedScriptMode == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(item.value as String);
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
                        : (isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white),
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
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textTertiaryLight,
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

// STEP 4: DAILY GOAL
class _DailyGoalStep extends StatelessWidget {
  const _DailyGoalStep({
    required this.isDark,
    required this.selectedDailyGoal,
    required this.onSelected,
  });

  final bool isDark;
  final int selectedDailyGoal;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
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
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting a small daily goal helps build a continuous learning streak.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...dailyGoals.map((item) {
            final isSelected = selectedDailyGoal == item.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(item.value as int);
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
                        : (isDark
                              ? AppColors.darkSurfaceElevated
                              : Colors.white),
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
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white60
                                    : AppColors.textTertiaryLight,
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
