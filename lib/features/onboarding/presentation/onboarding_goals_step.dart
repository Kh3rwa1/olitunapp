part of 'onboarding_screen.dart';

// STEP 5: ONBOARDING GOALS
class _GoalsStep extends ConsumerWidget {
  const _GoalsStep({
    required this.isDark,
    required this.selectedGoals,
    required this.onToggleGoal,
  });

  final bool isDark;
  final List<String> selectedGoals;
  final void Function(String goalId, bool isSelected) onToggleGoal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(onboardingGoalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are your learning goals?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply to personalize your learning experience.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ...goals.map((goal) {
            final isSelected = selectedGoals.contains(goal.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MinimumTapTarget(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onToggleGoal(goal.id, isSelected);
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
                          _mapIconStringToIcon(goal.icon),
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (bool? value) {
                          HapticFeedback.selectionClick();
                          onToggleGoal(goal.id, isSelected);
                        },
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

  IconData _mapIconStringToIcon(String iconName) {
    switch (iconName) {
      case 'translate_rounded':
        return Icons.translate_rounded;
      case 'calendar_today_rounded':
        return Icons.calendar_today_rounded;
      case 'trending_up_rounded':
        return Icons.trending_up_rounded;
      case 'event_note_rounded':
        return Icons.event_note_rounded;
      case 'business_center_rounded':
        return Icons.business_center_rounded;
      case 'school_rounded':
        return Icons.school_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'lightbulb_rounded':
        return Icons.lightbulb_rounded;
      case 'language_rounded':
        return Icons.language_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}
