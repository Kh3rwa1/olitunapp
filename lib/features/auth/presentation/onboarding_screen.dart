import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _selectedLevel = AppConstants.levelBeginner;
  String _selectedScriptMode = AppConstants.scriptBoth;
  String _selectedThemeMode = AppConstants.themeSystem;
  bool _isLoading = false;

  Future<void> _completeOnboarding() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userRepo = ref.read(userRepositoryProvider);
      
      // Save preferences
      await userRepo.setLocalThemeMode(_selectedThemeMode);
      await userRepo.setLocalScriptMode(_selectedScriptMode);
      await userRepo.completeOnboarding();
      
      // Update Riverpod state
      ref.read(themeModeProvider.notifier).state = _selectedThemeMode;
      ref.read(scriptModeProvider.notifier).state = _selectedScriptMode;
      
      // Update Firebase user preferences
      final currentUser = await userRepo.getCurrentUser();
      if (currentUser != null) {
        await userRepo.updatePreferences(
          currentUser.preferences.copyWith(
            level: _selectedLevel,
            scriptMode: _selectedScriptMode,
            themeMode: _selectedThemeMode,
          ),
        );
      }
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Continue anyway
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppConstants.spacingL),
                
                // Title
                Text(
                  'Personalize Your Experience',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'Let\'s customize Olitun for you',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingXL),

                // Level selection
                _buildSectionTitle(context, 'What\'s your level?'),
                const SizedBox(height: AppConstants.spacingM),
                _buildLevelSelector(),
                const SizedBox(height: AppConstants.spacingXL),

                // Script mode selection
                _buildSectionTitle(context, 'Script Display'),
                const SizedBox(height: AppConstants.spacingS),
                Text(
                  'How would you like to see the Ol Chiki script?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
                _buildScriptModeSelector(),
                const SizedBox(height: AppConstants.spacingXL),

                // Theme selection
                _buildSectionTitle(context, 'Theme'),
                const SizedBox(height: AppConstants.spacingM),
                _buildThemeSelector(),
                const SizedBox(height: AppConstants.spacingXXL),

                // Continue button
                PrimaryButton(
                  text: 'Start Learning',
                  isLoading: _isLoading,
                  onPressed: _completeOnboarding,
                ),
                const SizedBox(height: AppConstants.spacingM),
                
                // Skip
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => context.go('/home'),
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _buildLevelSelector() {
    return Row(
      children: [
        Expanded(
          child: _LevelCard(
            title: 'Beginner',
            icon: Icons.sentiment_satisfied_alt_rounded,
            isSelected: _selectedLevel == AppConstants.levelBeginner,
            onTap: () => setState(() => _selectedLevel = AppConstants.levelBeginner),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        Expanded(
          child: _LevelCard(
            title: 'Intermediate',
            icon: Icons.psychology_rounded,
            isSelected: _selectedLevel == AppConstants.levelIntermediate,
            onTap: () => setState(() => _selectedLevel = AppConstants.levelIntermediate),
          ),
        ),
      ],
    );
  }

  Widget _buildScriptModeSelector() {
    return Column(
      children: [
        _ScriptModeCard(
          title: 'Ol Chiki Only',
          subtitle: 'ᱚᱞ ᱪᱤᱠᱤ',
          isSelected: _selectedScriptMode == AppConstants.scriptOlChiki,
          onTap: () => setState(() => _selectedScriptMode = AppConstants.scriptOlChiki),
        ),
        const SizedBox(height: AppConstants.spacingS),
        _ScriptModeCard(
          title: 'Latin Only',
          subtitle: 'Ol Chiki (Romanized)',
          isSelected: _selectedScriptMode == AppConstants.scriptLatin,
          onTap: () => setState(() => _selectedScriptMode = AppConstants.scriptLatin),
        ),
        const SizedBox(height: AppConstants.spacingS),
        _ScriptModeCard(
          title: 'Both Scripts',
          subtitle: 'ᱚᱞ ᱪᱤᱠᱤ / Ol Chiki',
          isSelected: _selectedScriptMode == AppConstants.scriptBoth,
          onTap: () => setState(() => _selectedScriptMode = AppConstants.scriptBoth),
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    return Row(
      children: [
        Expanded(
          child: _ThemeCard(
            title: 'Light',
            icon: Icons.light_mode_rounded,
            isSelected: _selectedThemeMode == AppConstants.themeLight,
            onTap: () => setState(() => _selectedThemeMode = AppConstants.themeLight),
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: _ThemeCard(
            title: 'Dark',
            icon: Icons.dark_mode_rounded,
            isSelected: _selectedThemeMode == AppConstants.themeDark,
            onTap: () => setState(() => _selectedThemeMode = AppConstants.themeDark),
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: _ThemeCard(
            title: 'System',
            icon: Icons.settings_suggest_rounded,
            isSelected: _selectedThemeMode == AppConstants.themeSystem,
            onTap: () => setState(() => _selectedThemeMode = AppConstants.themeSystem),
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      backgroundColor: isSelected
          ? AppColors.primaryCyan.withValues(alpha: 0.1)
          : null,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryCyan
                  : (isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primaryCyan,
              size: 28,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primaryCyan : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScriptModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScriptModeCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      backgroundColor: isSelected
          ? AppColors.primaryCyan.withValues(alpha: 0.1)
          : null,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.primaryCyan
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryCyan
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primaryCyan : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingM,
      ),
      backgroundColor: isSelected
          ? AppColors.primaryCyan.withValues(alpha: 0.1)
          : null,
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primaryCyan : null,
            size: 28,
          ),
          const SizedBox(height: AppConstants.spacingXS),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.primaryCyan : null,
            ),
          ),
        ],
      ),
    );
  }
}
