import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';

class AdminLessonsScreen extends ConsumerWidget {
  const AdminLessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isWideScreen
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              leading: CircleIconButton(
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.go('/admin'),
              ),
              title: const Text('Lessons'),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add lesson creation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lesson editor coming soon!')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWideScreen)
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lessons',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'Manage lesson content and blocks',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    PrimaryButton(
                      text: 'Add Lesson',
                      
                      icon: Icons.add_rounded,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lesson editor coming soon!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.construction_rounded,
                        size: 48,
                        color: AppColors.primaryCyan,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingL),
                    Text(
                      'Lesson Editor',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppConstants.spacingS),
                    Text(
                      'Advanced lesson block editor\ncoming soon!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingXL),
                    SoftCard(
                      padding: const EdgeInsets.all(AppConstants.spacingL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planned Features:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          _FeatureItem(
                            icon: Icons.text_fields_rounded,
                            text: 'Text blocks with Ol Chiki/Latin',
                          ),
                          _FeatureItem(
                            icon: Icons.image_rounded,
                            text: 'Image blocks with captions',
                          ),
                          _FeatureItem(
                            icon: Icons.audiotrack_rounded,
                            text: 'Audio pronunciation',
                          ),
                          _FeatureItem(
                            icon: Icons.quiz_rounded,
                            text: 'Embedded quiz questions',
                          ),
                          _FeatureItem(
                            icon: Icons.drag_indicator_rounded,
                            text: 'Drag & drop reordering',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryCyan),
          const SizedBox(width: AppConstants.spacingS),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
