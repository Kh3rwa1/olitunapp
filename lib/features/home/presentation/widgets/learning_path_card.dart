import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/language_settings_providers.dart';
import '../../../quiz/domain/learning_path_catalog.dart';

/// Phase 7: proficiency-based learning-path card (spec §15).
///
/// Flag-gated by the caller (`audioQuizzesEnabled`); the sequence itself
/// comes from [learningPathFor] config, never hard-coded here (spec line
/// 700). Shows the learner's next recommended step and navigates to that
/// category's lesson list.
class LearningPathCard extends ConsumerWidget {
  const LearningPathCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proficiency = ref.watch(santaliProficiencyProvider);
    final path = learningPathFor(proficiency);
    // Some path stages (tracing, dictation, the audio diagnostic) are served
    // by dedicated surfaces, not a category lesson list — navigate to the
    // first step that actually opens a category today.
    final nextStep = path.firstOpenableStep;
    if (nextStep == null) return const SizedBox.shrink();
    final stepNumber = path.steps.indexOf(nextStep) + 1;

    return Semantics(
      container: true,
      label: 'Learning path. Next step: ${nextStep.id.replaceAll('_', ' ')}.',
      child: ExcludeSemantics(
        child: Material(
          color: isDark ? AppColors.quizDarkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/lessons/${nextStep.categoryId}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR LEARNING PATH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Step $stepNumber of ${path.steps.length}: '
                          '${nextStep.id.replaceAll('_', ' ')}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A guided path matched to your Santali level.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
