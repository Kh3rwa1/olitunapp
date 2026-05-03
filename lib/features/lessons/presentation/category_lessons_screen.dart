import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import 'providers/lesson_notifier.dart';

class CategoryLessonsScreen extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryLessonsScreen({super.key, required this.categoryId});

  @override
  ConsumerState<CategoryLessonsScreen> createState() =>
      _CategoryLessonsScreenState();
}

class _CategoryLessonsScreenState extends ConsumerState<CategoryLessonsScreen> {
  @override
  void initState() {
    super.initState();
    // Force refresh lessons from API every time this screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lessonNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(lessonNotifierProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final lessons = ref.watch(lessonsByCategoryProvider(widget.categoryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: categories.when(
          data: (data) {
            final category = data.firstWhere(
              (c) => c.id == widget.categoryId,
              orElse: () => data.first,
            );
            return Text(
              category.titleLatin,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            );
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: lessons.when(
        data: (data) => data.isEmpty
            ? _buildEmptyState(isDark)
            : BrandedRefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final lesson = data[index];
                    return _LessonCard(
                      lesson: lesson,
                      isDark: isDark,
                      index: index,
                      onTap: () => context.push('/lesson/${lesson.id}'),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load lessons',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => ref.read(lessonNotifierProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.school_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No lessons yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for new content',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final dynamic lesson;
  final bool isDark;
  final int index;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lesson,
    required this.isDark,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: PressableScale(
            onTap: onTap,
            child: Hero(
              tag: MotionTokens.heroTag('lesson', lesson.id),
              child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.titleLatin,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        if (lesson.titleOlChiki.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              lesson.titleOlChiki,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'OlChiki',
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                        if (lesson.description != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              lesson.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.play_circle_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ],
              ),
            ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index * 80).ms, duration: 400.ms)
        .slideX(begin: 0.1);
  }
}
