import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/presentation/animations/scale_button.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/text_match.dart';
import '../../../../../shared/models/content_models.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../../shared/widgets/bento_grid.dart';
import '../../../domain/entities/lesson_entity.dart';
import 'empty_content_placeholder.dart';
import 'lesson_content_helpers.dart';

/// Grid of Santali number cards for the lesson detail screen.
/// Scoped: only shows numbers that appear in the lesson's blocks.
class NumberGridContent extends ConsumerWidget {
  final String lessonId;

  const NumberGridContent({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allNumbers = ref.watch(learnerNumbersProvider).value ?? [];
    final lessons = ref.watch(learnerLessonsProvider).value ?? [];
    final lesson = lessons.where((l) => l.id == lessonId).firstOrNull;

    final numbers = _scopeNumbers(allNumbers, lesson);

    if (numbers.isEmpty) {
      return EmptyContentPlaceholder(
        message: 'No numbers in this lesson. Add content blocks in admin.',
        isDark: isDark,
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: getResponsiveCrossAxisCount(context),
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.85,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final number = numbers[index];
        return ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/number/$lessonId/${number.id}');
          },
          child: BentoCell(
            padding: const EdgeInsets.all(14),
            borderRadius: 20,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1.5,
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        number.numeral,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${number.value}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        number.nameLatin,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Extract numbers referenced by lesson blocks.
  /// Returns only matched numbers — empty list triggers the placeholder.
  List<NumberModel> _scopeNumbers(
    List<NumberModel> allNumbers,
    LessonEntity? lesson,
  ) {
    if (lesson == null) {
      return const [];
    }

    final blockTexts = lesson.blocks
        .where((b) => b.type == 'text' && b.textOlChiki != null)
        .map((b) => b.textOlChiki!.trim())
        .toSet();

    if (blockTexts.isNotEmpty) {
      final scoped = allNumbers
          .where(
            (n) =>
                n.isActive &&
                blockTexts.any(
                  (t) =>
                      isTextMatch(t, n.numeral) ||
                      isTextMatch(t, n.value.toString()) ||
                      isTextMatch(t, n.nameOlChiki) ||
                      isTextMatch(t, n.nameLatin),
                ),
          )
          .toList();

      if (scoped.isNotEmpty) {
        return scoped..sort((a, b) => a.order.compareTo(b.order));
      }
    }

    // Fallback: If no blocks or no matching numbers were found, fallback to category/range mapping
    final title = lesson.titleLatin.toLowerCase();
    List<NumberModel> fallbackList = [];
    if (title.contains('0-9') ||
        title.contains('single') ||
        title.contains('basic')) {
      fallbackList = allNumbers
          .where((n) => n.value >= 0 && n.value <= 9 && n.isActive)
          .toList();
    } else if (title.contains('10-99') ||
        title.contains('double') ||
        title.contains('tens') ||
        title.contains('10 to 99')) {
      fallbackList = allNumbers
          .where((n) => n.value >= 10 && n.value <= 99 && n.isActive)
          .toList();
    } else if (title.contains('100') ||
        title.contains('hundred') ||
        title.contains('large')) {
      fallbackList = allNumbers
          .where((n) => n.value >= 100 && n.isActive)
          .toList();
    } else {
      fallbackList = allNumbers.where((n) => n.isActive).toList();
    }

    return fallbackList..sort((a, b) => a.order.compareTo(b.order));
  }
}
