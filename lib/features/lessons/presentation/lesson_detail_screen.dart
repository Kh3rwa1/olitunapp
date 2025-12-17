import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/bubble_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/animated_buttons.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/repositories/content_repository.dart';
import '../../../shared/models/content_models.dart';

final lessonDetailProvider = FutureProvider.family<LessonModel?, String>((ref, lessonId) async {
  final contentRepo = ContentRepository();
  return contentRepo.getLesson(lessonId);
});

class LessonDetailScreen extends ConsumerStatefulWidget {
  final String lessonId;

  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen> {
  int _currentBlockIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BubbleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: CircleIconButton(
            icon: Icons.close_rounded,
            onPressed: () => context.pop(),
          ),
          title: lessonAsync.when(
            data: (lesson) => lesson != null
                ? Text(lesson.titleLatin)
                : const Text('Lesson'),
            loading: () => const ShimmerText(width: 100),
            error: (_, __) => const Text('Lesson'),
          ),
          actions: [
            CircleIconButton(
              icon: Icons.volume_up_rounded,
              onPressed: () {
                // Toggle sound
              },
            ),
            const SizedBox(width: AppConstants.spacingS),
          ],
        ),
        body: lessonAsync.when(
          data: (lesson) {
            if (lesson == null) {
              return const Center(child: Text('Lesson not found'));
            }

            if (lesson.blocks.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.construction_rounded,
                      size: 64,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    const SizedBox(height: AppConstants.spacingM),
                    Text(
                      'Lesson content coming soon!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingM,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceVariant
                                : AppColors.lightSurfaceVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (_currentBlockIndex + 1) / lesson.blocks.length,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.spacingS),
                      Text(
                        '${_currentBlockIndex + 1}/${lesson.blocks.length}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.spacingL),

                // Block content
                Expanded(
                  child: PageView.builder(
                    itemCount: lesson.blocks.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBlockIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildBlock(context, lesson.blocks[index]);
                    },
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingM),
                  child: Row(
                    children: [
                      if (_currentBlockIndex > 0)
                        Expanded(
                          child: SecondaryButton(
                            text: 'Previous',
                            onPressed: () {
                              setState(() {
                                _currentBlockIndex--;
                              });
                            },
                          ),
                        ),
                      if (_currentBlockIndex > 0)
                        const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: PrimaryButton(
                          text: _currentBlockIndex < lesson.blocks.length - 1
                              ? 'Next'
                              : 'Complete',
                          onPressed: () {
                            if (_currentBlockIndex < lesson.blocks.length - 1) {
                              setState(() {
                                _currentBlockIndex++;
                              });
                            } else {
                              // Complete lesson
                              _showCompletionDialog(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildBlock(BuildContext context, LessonBlock block) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (block.type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: SoftCard(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (block.textOlChiki != null && block.textOlChiki!.isNotEmpty)
                  Text(
                    block.textOlChiki!,
                    style: const TextStyle(
                      fontFamily: 'OlChiki',
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (block.textLatin != null && block.textLatin!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    block.textLatin!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );

      case 'image':
        return Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (block.imageUrl != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    child: CachedNetworkImage(
                      imageUrl: block.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const ShimmerCard(height: 200),
                      errorWidget: (_, __, ___) => const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              if (block.textLatin != null) ...[
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  block.textLatin!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );

      case 'quiz':
        if (block.quizRefId != null) {
          return Center(
            child: PrimaryButton(
              text: 'Start Quiz',
              
              icon: Icons.quiz_rounded,
              onPressed: () => context.pushNamed(
                'quiz',
                pathParameters: {'quizId': block.quizRefId!},
              ),
            ),
          );
        }
        return const Center(child: Text('Quiz not available'));

      default:
        return Center(
          child: Text('Unknown block type: ${block.type}'),
        );
    }
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.sunsetGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Text(
              'Lesson Complete!',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Great job! You earned 10 stars.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingL),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    text: 'Back',
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pop();
                    },
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: PrimaryButton(
                    text: 'Continue',
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
