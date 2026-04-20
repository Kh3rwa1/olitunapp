import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../shared/widgets/lottie_display.dart';
import '../../../core/presentation/animations/scale_button.dart';
import '../../../core/presentation/animations/fade_in_slide.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);

    // Watch these content providers to ensure data is available for dynamic block matching
    final letters = ref.watch(lettersProvider);
    final numbers = ref.watch(numbersProvider);
    final words = ref.watch(wordsProvider);
    final sentences = ref.watch(sentencesProvider);

    final allLoaded =
        letters.hasValue &&
        numbers.hasValue &&
        words.hasValue &&
        sentences.hasValue;

    final countsString =
        'Letters: ${letters.value?.length ?? 'null'} (loading: ${letters.isLoading}, hasError: ${letters.hasError})\n'
        'Numbers: ${numbers.value?.length ?? 'null'} (loading: ${numbers.isLoading}, hasError: ${numbers.hasError})\n'
        'Words: ${words.value?.length ?? 'null'} (loading: ${words.isLoading}, hasError: ${words.hasError})\n'
        'Sentences: ${sentences.value?.length ?? 'null'} (loading: ${sentences.isLoading}, hasError: ${sentences.hasError})';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return lessons.when(
      loading: () => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: Center(child: Text('Error: $e')),
      ),
      data: (data) {
        if (data.isEmpty) {
          return Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text('No lessons available')),
          );
        }

        final lesson = data.firstWhere(
          (l) => l.id == lessonId,
          orElse: () => data.first,
        );

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              lesson.titleLatin,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.titleLatin,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),

                      if (lesson.titleOlChiki.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            lesson.titleOlChiki,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildChip(
                            Icons.timer_rounded,
                            '${lesson.estimatedMinutes} min',
                          ),
                          const SizedBox(width: 12),
                          _buildChip(
                            Icons.signal_cellular_alt_rounded,
                            lesson.level,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description section
                if (lesson.description != null &&
                    lesson.description!.isNotEmpty) ...[
                  Text(
                    'About this lesson',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lesson.description!,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Content section based on category
                FadeInSlide(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getSectionTitle(lesson.categoryId),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Tooltip(
                            message: countsString,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: allLoaded ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Build content based on category
                      _buildContent(
                        context,
                        ref,
                        lesson.categoryId,
                        lesson.id,
                        isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80),
                const SizedBox(height: 32),
              ],
            ),
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            width: double.infinity,
            child: FloatingActionButton.extended(
              onPressed: () {
                final notifier = ref.read(progressProvider.notifier);
                notifier.completeLesson(lessonId);
                notifier.addStars(15);
                context.pop();
              },
              backgroundColor: AppColors.primary,
              label: const Text(
                'Complete Lesson',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getSectionTitle(String categoryId) {
    switch (categoryId) {
      case 'alphabets':
      case 'cat_alphabet':
      case 'seed_alphabet':
        return 'Letters to Learn';
      case 'numbers':
      case 'cat_numbers':
      case 'seed_numbers':
        return 'Numbers to Learn';
      case 'words':
      case 'cat_words':
      case 'seed_words':
        return 'Vocabulary';
      case 'sentences':
      case 'cat_sentences':
      case 'seed_sentences':
      case 'phrases':
        return 'Common Phrases';
      default:
        return 'Content';
    }
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    String categoryId,
    String lessonId,
    bool isDark,
  ) {
    // 1. Try to load lesson data from provider to check for blocks
    final lessons = ref.read(lessonsProvider).value ?? [];
    LessonModel? lesson;
    try {
      lesson = lessons.firstWhere((l) => l.id == lessonId);
    } catch (_) {}

    // 2. If valid blocks exist, render them dynamically
    if (lesson != null && lesson.blocks.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lesson.blocks.map((block) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildDynamicBlock(context, ref, lessonId, block, isDark),
          );
        }).toList(),
      );
    }

    // 3. Fallback to provider-based grids
    switch (categoryId) {
      case 'alphabets':
      case 'cat_alphabet':
      case 'seed_alphabet':
        return _buildLetterGrid(context, ref, lessonId, isDark);
      case 'numbers':
      case 'cat_numbers':
      case 'seed_numbers':
        return _buildNumberGrid(context, ref, lessonId, isDark);
      case 'sentences':
      case 'cat_sentences':
      case 'seed_sentences':
        return _buildSentenceList(context, ref, lessonId, isDark);
      default:
        return _buildVocabularyList(context, ref, lessonId, isDark);
    }
  }

  Widget _buildDynamicBlock(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    LessonBlock block,
    bool isDark,
  ) {
    switch (block.type) {
      case 'text':
        final textOlChiki = block.textOlChiki?.trim();
        if (textOlChiki == null || textOlChiki.isEmpty) {
          return const SizedBox.shrink();
        }

        // Try to find matching entity for navigation
        String? navRoute;

        // Robust fuzzy matching helper
        bool isFuzzyMatch(String target, String entityText) {
          if (entityText.isEmpty) return false;
          final t = target.trim().toLowerCase();
          final e = entityText.trim().toLowerCase();

          if (t == e) return true;

          // Match at start with common separators
          final separators = [' ', '-', '–', '—', '−', '.', '!', '?', ':', ';'];
          for (final s in separators) {
            if (t.startsWith('$e$s')) return true;
          }

          // Check if e is the first token
          final tokens = t.split(RegExp(r'[\s\-\–\—\−\.\!\?\:\;]'));
          if (tokens.isNotEmpty && tokens.first == e) return true;

          // Punctuation-stripped check
          final tClean = t
              .replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '')
              .trim();
          final eClean = e
              .replaceAll(RegExp(r'[^\w\s\u1C50-\u1C7F]'), '')
              .trim();
          if (tClean == eClean && tClean.isNotEmpty) return true;

          return false;
        }

        debugPrint('DynamicBlock CHECK: "$textOlChiki"');

        // 1. Check Letters
        final letters = ref.read(lettersProvider).value ?? [];
        final matchedLetter = letters
            .where((l) => isFuzzyMatch(textOlChiki, l.charOlChiki))
            .firstOrNull;
        if (matchedLetter != null) {
          navRoute = '/letter/$lessonId/${matchedLetter.charOlChiki}';
          debugPrint(
            'Matched Letter: ${matchedLetter.charOlChiki} -> $navRoute',
          );
        }

        // 2. Check Numbers
        if (navRoute == null) {
          final numbers = ref.read(numbersProvider).value ?? [];
          final matchedNumber = numbers.where((n) {
            return isFuzzyMatch(textOlChiki, n.numeral) ||
                isFuzzyMatch(textOlChiki, n.value.toString());
          }).firstOrNull;
          if (matchedNumber != null) {
            navRoute = '/number/$lessonId/${matchedNumber.id}';
            debugPrint('Matched Number: ${matchedNumber.numeral} -> $navRoute');
          }
        }

        // 3. Check Words
        if (navRoute == null) {
          final words = ref.read(wordsProvider).value ?? [];
          final matchedWord = words
              .where((w) => isFuzzyMatch(textOlChiki, w.wordOlChiki))
              .firstOrNull;
          if (matchedWord != null) {
            navRoute = '/word/$lessonId/${matchedWord.id}';
            debugPrint('Matched Word: ${matchedWord.wordOlChiki} -> $navRoute');
          }
        }

        // 4. Check Sentences
        if (navRoute == null) {
          final sentences = ref.read(sentencesProvider).value ?? [];
          final matchedSentence = sentences
              .where((s) => isFuzzyMatch(textOlChiki, s.sentenceOlChiki))
              .firstOrNull;
          if (matchedSentence != null) {
            navRoute = '/sentence/$lessonId/${matchedSentence.id}';
            debugPrint('Matched Sentence: ${matchedSentence.id} -> $navRoute');
          }
        }

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
                    if (block.textLatin != null &&
                        block.textLatin!.isNotEmpty) ...[
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ScaleButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(navRoute!);
              },
              child: content,
            ),
          );
        }
        return content;

      case 'image':
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
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded),
                    ),
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

      case 'quiz':
        // This is the key fix for "specailly the quiz"
        return ScaleButton(
          onPressed: () {
            // Navigate to actual quiz screen using quiz ID
            if (block.quizRefId != null) {
              // Assuming route is /quiz/:quizId
              context.push('/quiz/${block.quizRefId}');
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

      case 'lottie':
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
              if (block.animationUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LottieDisplay(
                    url: block.animationUrl!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.contain,
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

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLetterGrid(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    bool isDark,
  ) {
    final allLetters = ref.read(lettersProvider).value ?? [];
    final letters = allLetters.where((l) => l.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (letters.isEmpty) {
      return _buildEmptyContent('No letters available yet', isDark);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return ScaleButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/letter/$lessonId/${letter.charOlChiki}');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        letter.charOlChiki,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        letter.transliterationLatin.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                          letterSpacing: 1.5,
                        ),
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
                      size: 12,
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

  Widget _buildNumberGrid(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    bool isDark,
  ) {
    final allNumbers = ref.read(numbersProvider).value ?? [];
    final numbers = allNumbers.where((n) => n.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (numbers.isEmpty) {
      return _buildEmptyContent('No numbers available yet', isDark);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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

  Widget _buildVocabularyList(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    bool isDark,
  ) {
    final allWords = ref.read(wordsProvider).value ?? [];
    final words = allWords.where((w) => w.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (words.isEmpty) {
      return _buildEmptyContent('No words available yet', isDark);
    }

    return Column(
      children: words
          .map(
            (word) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ScaleButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/word/$lessonId/${word.id}');
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
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
                              word.wordOlChiki,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              word.wordLatin,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildSentenceList(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    bool isDark,
  ) {
    final allSentences = ref.read(sentencesProvider).value ?? [];
    final sentences = allSentences.where((s) => s.isActive).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (sentences.isEmpty) {
      return _buildEmptyContent('No sentences available yet', isDark);
    }

    return Column(
      children: sentences
          .map(
            (sentence) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ScaleButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/sentence/$lessonId/${sentence.id}');
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
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
                              sentence.sentenceOlChiki,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sentence.sentenceLatin,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sentence.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyContent(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
