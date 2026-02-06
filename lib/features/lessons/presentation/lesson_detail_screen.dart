import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/models/content_models.dart';
import '../../../core/presentation/animations/scale_button.dart';
import '../../../core/presentation/animations/fade_in_slide.dart';

class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
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
                onPressed: () => context.go('/home'),
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
              onPressed: () => context.go('/home'),
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
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      if (lesson.titleOlChiki.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            lesson.titleOlChiki,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.9),
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
                      Text(
                        _getSectionTitle(lesson.categoryId),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
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

                const SizedBox(height: 100), // Space for button
              ],
            ),
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            width: double.infinity,
            child: FloatingActionButton.extended(
              onPressed: () {
                incrementLessonsCompleted(ref);
                addStars(ref, 10);
                context.go('/home');
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
        color: Colors.white.withOpacity(0.2),
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
        return 'Letters to Learn';
      case 'numbers':
        return 'Numbers to Learn';
      case 'words':
        return 'Vocabulary';
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
            child: _buildDynamicBlock(context, block, isDark),
          );
        }).toList(),
      );
    }

    // 3. Fallback to legacy hardcoded grids
    switch (categoryId) {
      case 'alphabets':
        return _buildLetterGrid(context, lessonId, isDark);
      case 'numbers':
        return _buildNumberGrid(lessonId, isDark);
      default:
        return _buildVocabularyList(context, lessonId, isDark);
    }
  }

  Widget _buildDynamicBlock(
    BuildContext context,
    LessonBlock block,
    bool isDark,
  ) {
    switch (block.type) {
      case 'text':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (block.textOlChiki != null && block.textOlChiki!.isNotEmpty)
                Text(
                  block.textOlChiki!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              if (block.textOlChiki != null && block.textLatin != null)
                const SizedBox(height: 8),
              if (block.textLatin != null && block.textLatin!.isNotEmpty)
                Text(
                  block.textLatin!,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
            ],
          ),
        );

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
                    color: Colors.grey.withOpacity(0.1),
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
                  color: AppColors.primaryPurple.withOpacity(0.3),
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
                    color: Colors.white.withOpacity(0.2),
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
                          color: Colors.white.withOpacity(0.8),
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

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLetterGrid(BuildContext context, String lessonId, bool isDark) {
    final letterData = {
      'alphabets_1': [
        {'char': 'ᱚ', 'latin': 'a', 'name': 'La'},
        {'char': 'ᱟ', 'latin': 'aa', 'name': 'Aah'},
        {'char': 'ᱤ', 'latin': 'i', 'name': 'Li'},
        {'char': 'ᱩ', 'latin': 'u', 'name': 'Lu'},
      ],
      'alphabets_2': [
        {'char': 'ᱚ', 'latin': 'a', 'name': 'A vowel'},
        {'char': 'ᱟ', 'latin': 'aa', 'name': 'AA vowel'},
        {'char': 'ᱤ', 'latin': 'i', 'name': 'I vowel'},
        {'char': 'ᱩ', 'latin': 'u', 'name': 'U vowel'},
        {'char': 'ᱮ', 'latin': 'e', 'name': 'E vowel'},
        {'char': 'ᱳ', 'latin': 'o', 'name': 'O vowel'},
      ],
      'alphabets_3': [
        {'char': 'ᱠ', 'latin': 'k', 'name': 'Ok'},
        {'char': 'ᱜ', 'latin': 'g', 'name': 'Ol'},
        {'char': 'ᱝ', 'latin': 'ng', 'name': 'Ong'},
        {'char': 'ᱪ', 'latin': 'c', 'name': 'Uc'},
        {'char': 'ᱡ', 'latin': 'j', 'name': 'Oj'},
      ],
      'alphabets_4': [
        {'char': 'ᱴ', 'latin': 't', 'name': 'Ot'},
        {'char': 'ᱰ', 'latin': 'd', 'name': 'Od'},
        {'char': 'ᱱ', 'latin': 'n', 'name': 'On'},
        {'char': 'ᱯ', 'latin': 'p', 'name': 'Op'},
        {'char': 'ᱵ', 'latin': 'b', 'name': 'Ob'},
      ],
    };

    final letters = letterData[lessonId] ?? letterData['alphabets_1']!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        return ScaleButton(
          onPressed: () => context.go('/letter/$lessonId/${letter['char']}'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  letter['char']!,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  letter['latin']!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  letter['name']!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberGrid(String lessonId, bool isDark) {
    final numberData = {
      'numbers_1': [
        {'num': '᱑', 'value': '1', 'name': 'Mit'},
        {'num': '᱒', 'value': '2', 'name': 'Bar'},
        {'num': '᱓', 'value': '3', 'name': 'Pe'},
        {'num': '᱔', 'value': '4', 'name': 'Pon'},
        {'num': '᱕', 'value': '5', 'name': 'Mone'},
      ],
      'numbers_2': [
        {'num': '᱖', 'value': '6', 'name': 'Turui'},
        {'num': '᱗', 'value': '7', 'name': 'Eae'},
        {'num': '᱘', 'value': '8', 'name': 'Irel'},
        {'num': '᱙', 'value': '9', 'name': 'Are'},
        {'num': '᱑᱐', 'value': '10', 'name': 'Gel'},
      ],
    };

    final numbers = numberData[lessonId] ?? numberData['numbers_1']!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: numbers.length,
      itemBuilder: (context, index) {
        final num = numbers[index];
        return ScaleButton(
          onPressed: () => context.go('/number/$lessonId/${num['value']}'),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  num['num']!,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  num['value']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  num['name']!,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black45,
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
    String lessonId,
    bool isDark,
  ) {
    final vocabData = {
      'words_1': [
        {'olchiki': 'ᱡᱚᱦᱟᱨ', 'latin': 'Johar', 'meaning': 'Hello / Greetings'},
        {'olchiki': 'ᱥᱮᱨᱢᱟ', 'latin': 'Serma', 'meaning': 'Good morning'},
        {'olchiki': 'ᱵᱳᱭᱤᱱ', 'latin': 'Boyin', 'meaning': 'Goodbye'},
        {'olchiki': 'ᱫᱷᱟᱱᱭᱟᱵᱟᱫ', 'latin': 'Dhanyabad', 'meaning': 'Thank you'},
      ],
      'words_2': [
        {'olchiki': 'ᱟᱯᱟ', 'latin': 'Apa', 'meaning': 'Father'},
        {'olchiki': 'ᱟᱭᱳ', 'latin': 'Ayo', 'meaning': 'Mother'},
        {'olchiki': 'ᱵᱳᱭᱦᱟ', 'latin': 'Boyha', 'meaning': 'Brother'},
        {'olchiki': 'ᱢᱤᱥᱨᱟ', 'latin': 'Misra', 'meaning': 'Sister'},
      ],
      'phrases_1': [
        {
          'olchiki': 'ᱟᱢ ᱪᱮᱫᱟᱜ ᱢᱮᱱᱟᱜ ᱟ?',
          'latin': 'Am chedag menag a?',
          'meaning': 'How are you?',
        },
        {
          'olchiki': 'ᱤᱧ ᱵᱷᱟᱞᱮ ᱢᱮᱱᱟᱜ ᱟ',
          'latin': 'Ing bhale menag a',
          'meaning': 'I am fine',
        },
        {
          'olchiki': 'ᱟᱢ ᱧᱩᱛᱩᱢ ᱪᱮᱫᱟᱜ?',
          'latin': 'Am nyutum chedag?',
          'meaning': 'What is your name?',
        },
        {
          'olchiki': 'ᱤᱧᱟᱜ ᱧᱩᱛᱩᱢ...',
          'latin': 'Ingag nyutum...',
          'meaning': 'My name is...',
        },
      ],
    };

    final vocab = vocabData[lessonId] ?? vocabData['words_1']!;

    return Column(
      children: vocab
          .map(
            (item) => ScaleButton(
              onPressed: () => context.go('/word/$lessonId/${item['olchiki']}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['olchiki']!,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            item['latin']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item['meaning']!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.primary.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
