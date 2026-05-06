import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../shared/widgets/lottie_display.dart';
import '../../../../core/presentation/animations/scale_button.dart';
import '../../domain/entities/lesson_entity.dart';

/// Robust fuzzy matching for Ol Chiki text against entity labels.
bool _isFuzzyMatch(String target, String entityText) {
  if (entityText.isEmpty) return false;
  final t = target.trim().toLowerCase();
  final e = entityText.trim().toLowerCase();

  if (t == e) return true;

  final separators = [' ', '-', '–', '—', '−', '.', '!', '?', ':', ';'];
  for (final s in separators) {
    if (t.startsWith('$e$s')) return true;
  }

  final tokens = t.split(RegExp(r'[\s\-\–\—\−\.\!\?\:\;]'));
  if (tokens.isNotEmpty && tokens.first == e) return true;

  final tClean = t.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  final eClean = e.replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '').trim();
  if (tClean == eClean && tClean.isNotEmpty) return true;

  return false;
}

/// Renders a single dynamic content block (text, image, quiz, lottie).
class DynamicBlockBuilder extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;

  const DynamicBlockBuilder({
    super.key,
    required this.lessonId,
    required this.block,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (block.type) {
      case 'text':
        return _TextBlock(lessonId: lessonId, block: block, isDark: isDark);
      case 'image':
        return _ImageBlock(block: block, isDark: isDark);
      case 'quiz':
        return _QuizBlock(block: block);
      case 'lottie':
        return _LottieBlock(block: block, isDark: isDark);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Text block with fuzzy-match navigation to letters/numbers/words/sentences.
class _TextBlock extends ConsumerWidget {
  final String lessonId;
  final LessonBlockEntity block;
  final bool isDark;

  const _TextBlock({
    required this.lessonId,
    required this.block,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textOlChiki = block.textOlChiki?.trim();
    if (textOlChiki == null || textOlChiki.isEmpty) {
      return const SizedBox.shrink();
    }

    final navRoute = _resolveNavRoute(ref, lessonId, textOlChiki);

    final content = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: navRoute != null
              ? AppColors.primary.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.1),
          width: navRoute != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.textOlChiki!,
                  style: TextStyle(
                    fontSize: (block.textOlChiki!.length < 5) ? 36 : 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1.2,
                  ),
                ),
                if (block.textLatin != null && block.textLatin!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    block.textLatin!,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (navRoute != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );

    if (navRoute != null) {
      final route = navRoute;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(route);
          },
          child: content,
        ),
      );
    }
    return content;
  }

  String? _resolveNavRoute(WidgetRef ref, String lessonId, String text) {
    // Check Letters
    final letters = ref.read(lettersProvider).value ?? [];
    final matchedLetter = letters
        .where((l) => _isFuzzyMatch(text, l.charOlChiki))
        .firstOrNull;
    if (matchedLetter != null) {
      return '/letter/$lessonId/${matchedLetter.charOlChiki}';
    }

    // Check Numbers
    final numbers = ref.read(numbersProvider).value ?? [];
    final matchedNumber = numbers.where((n) {
      return _isFuzzyMatch(text, n.numeral) ||
          _isFuzzyMatch(text, n.value.toString());
    }).firstOrNull;
    if (matchedNumber != null) {
      return '/number/$lessonId/${matchedNumber.id}';
    }

    // Check Words
    final words = ref.read(wordsProvider).value ?? [];
    final matchedWord = words
        .where((w) => _isFuzzyMatch(text, w.wordOlChiki))
        .firstOrNull;
    if (matchedWord != null) {
      return '/word/$lessonId/${matchedWord.id}';
    }

    // Check Sentences
    final sentences = ref.read(sentencesProvider).value ?? [];
    final matchedSentence = sentences
        .where((s) => _isFuzzyMatch(text, s.sentenceOlChiki))
        .firstOrNull;
    if (matchedSentence != null) {
      return '/sentence/$lessonId/${matchedSentence.id}';
    }

    return null;
  }
}

/// Image content block with caption.
class _ImageBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _ImageBlock({required this.block, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Image.network(
            block.imageUrl!,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                color: Colors.grey.withValues(alpha: 0.1),
                child: const Center(child: Icon(Icons.broken_image_rounded)),
              );
            },
          ),
          if (block.textLatin != null) ...[
            const SizedBox(height: 8),
            Text(
              block.textLatin!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Quiz CTA block that navigates to the quiz screen.
class _QuizBlock extends StatelessWidget {
  final LessonBlockEntity block;

  const _QuizBlock({required this.block});

  @override
  Widget build(BuildContext context) {
    final quizRefId = block.data?['quizRefId'] as String?;
    return ScaleButton(
      onPressed: () {
        if (quizRefId != null) {
          context.push('/quiz/$quizRefId');
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.premiumPurple,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.quiz_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Take a Quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Test your knowledge now!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Lottie animation block with optional caption.
class _LottieBlock extends StatelessWidget {
  final LessonBlockEntity block;
  final bool isDark;

  const _LottieBlock({required this.block, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final animationUrl = block.data?['animationUrl'] as String?;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          if (animationUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LottieDisplay(
                url: animationUrl,
                width: double.infinity,
                height: 200,
              ),
            ),
          if (block.textLatin != null) ...[
            const SizedBox(height: 8),
            Text(
              block.textLatin!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
