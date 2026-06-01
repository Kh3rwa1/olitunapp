import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../categories/domain/entities/category_entity.dart';
import '../../categories/presentation/providers/category_notifier.dart';
import 'providers/lesson_notifier.dart';
import '../../../shared/repositories/content_repository.dart';
import '../../../shared/models/content_item.dart';
import '../../../shared/providers/purchases_provider.dart';
import '../../../shared/widgets/paywall_bottom_sheet.dart';
import '../../../shared/providers/local_settings_provider.dart';
import '../../../shared/utils/localized_content.dart';

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
  }

  Future<void> _onRefresh() async {
    ref.invalidate(contentListProvider((ContentKind.lesson, widget.categoryId)));
    ref.invalidate(contentListProvider((ContentKind.lesson, null)));
  }

  LinearGradient _getGradient(String preset) {
    switch (preset) {
      case 'skyBlue':
        return AppColors.skyBlueGradient;
      case 'peach':
        return AppColors.peachGradient;
      case 'mint':
        return AppColors.mintGradient;
      case 'sunset':
        return AppColors.sunsetGradient;
      case 'purple':
        return AppColors.purpleGradient;
      default:
        return AppColors.heroGradient;
    }
  }

  Widget _buildBackButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: PressableScale(
          onTap: () => context.canPop() ? context.pop() : context.go('/'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBadge({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required Widget card,
    required int index,
    required bool isFirst,
    required bool isLast,
    required bool isDark,
    required bool isLocked,
    required Color themeColor,
    required LinearGradient gradient,
    Widget? stepNodeChild,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 48,
            child: CustomPaint(
              painter: _TimelinePainter(
                isFirst: isFirst,
                isLast: isLast,
                color: themeColor,
                isDark: isDark,
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 14,
                    child: _buildStepNode(
                      index: index,
                      themeColor: themeColor,
                      isDark: isDark,
                      isLocked: isLocked,
                      gradient: gradient,
                      child: stepNodeChild,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Card Column
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: card,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode({
    required int index,
    required Color themeColor,
    required bool isDark,
    required bool isLocked,
    required LinearGradient gradient,
    Widget? child,
  }) {
    if (isLocked) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Center(
          child: Icon(
            Icons.lock_rounded,
            color: isDark ? Colors.white38 : Colors.black38,
            size: 14,
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF0A0E14) : Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Center(
        child:
            child ??
            Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryNotifierProvider);
    final lessons = ref.watch(lessonsByCategoryProvider(widget.categoryId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final purchasedCategories =
        ref.watch(purchasedCategoriesProvider).value ?? {};
    final scriptMode = ref.watch(effectiveScriptModeProvider);

    final category = categories.when(
      data: (data) => _findCategory(data, widget.categoryId),
      loading: () => null,
      error: (err, stack) => null,
    );

    if (category == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final brandGradient = _getGradient(category.gradientPreset);
    final themeColor = brandGradient.colors.first;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
      body: BrandedRefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              expandedHeight: 240.0,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? const Color(0xFF0A0E14) : Colors.white,
              leadingWidth: 72,
              leading: _buildBackButton(context, isDark),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  final isCollapsed =
                      top <=
                      kToolbarHeight + MediaQuery.of(context).padding.top;

                  return FlexibleSpaceBar(
                    centerTitle: true,
                    title: isCollapsed
                        ? Text(
                            category.titleLatin,
                            style: TextStyle(
                              fontFamily: primaryLocalizedFontFamily(
                                scriptMode,
                              ),
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  offset: const Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          )
                        : null,
                    background: Container(
                      decoration: BoxDecoration(gradient: brandGradient),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Decorative ambient overlays
                          Positioned(
                            right: -40,
                            top: -40,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -50,
                            bottom: -30,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                          // Content layout
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              MediaQuery.of(context).padding.top + 48,
                              20,
                              20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (category.titleOlChiki.isNotEmpty) ...[
                                  Text(
                                    category.titleOlChiki,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                      letterSpacing: 1.5,
                                      fontFamily: 'OlChiki',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  category.titleLatin,
                                  style: TextStyle(
                                    fontFamily: primaryLocalizedFontFamily(
                                      scriptMode,
                                    ),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.8,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                if (category.description != null &&
                                    category.description!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    category.description!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontWeight: FontWeight.w400,
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 14),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildHeaderBadge(
                                        icon: Icons.menu_book_rounded,
                                        label:
                                            '${category.totalLessons > 0 ? category.totalLessons : 5} Lessons',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildHeaderBadge(
                                        icon: category.unlockMode == 'free'
                                            ? Icons.stars_rounded
                                            : Icons.workspace_premium_rounded,
                                        label: category.unlockMode == 'free'
                                            ? 'Free Access'
                                            : 'Premium',
                                      ),
                                      const SizedBox(width: 8),
                                      _buildHeaderBadge(
                                        icon: Icons.cloud_done_rounded,
                                        label: 'Offline Ready',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            lessons.when(
              data: (data) {
                if (data.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(isDark, category),
                  );
                }

                final isPremium = category.unlockMode != 'free';
                final isUnlocked = purchasedCategories.contains(category.id);

                const alphabetCategoryIds = {
                  'cat_alphabets_1778594017948',
                  'cat_alphabets',
                  'cat_letters',
                  'letters',
                };
                const numberCategoryIds = {
                  'cat_numbers_1778594019015',
                  'cat_numbers',
                  'numbers',
                };

                final isAlphabet = alphabetCategoryIds.contains(category.id);
                final isNumber = numberCategoryIds.contains(category.id);
                final hasBrowseAll = isAlphabet || isNumber;
                final totalCount = data.length + (hasBrowseAll ? 1 : 0);

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (hasBrowseAll && index == 0) {
                        final cardWidget = _BrowseAllCard(
                          label: isAlphabet ? 'Ol Chiki' : 'Lekha',
                          olChikiLabel: isAlphabet ? 'ᱚᱞ ᱪᱤᱠᱤ' : 'ᱞᱮᱠᱷᱟ',
                          description: isAlphabet
                              ? 'Explore the complete grid dictionary of all letters'
                              : 'Explore the complete grid dictionary of all numbers',
                          onTap: () {
                            if (isAlphabet) {
                              context.push('/letter/standalone/all');
                            } else {
                              context.push('/number/standalone/all');
                            }
                          },
                          isDark: isDark,
                          gradient: brandGradient,
                          themeColor: themeColor,
                        );

                        return _buildTimelineItem(
                              card: cardWidget,
                              index: index,
                              isFirst: true,
                              isLast: totalCount == 1,
                              isDark: isDark,
                              isLocked: false,
                              themeColor: themeColor,
                              gradient: brandGradient,
                              stepNodeChild: const Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 0.ms, duration: 400.ms)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              curve: MotionTokens.emphasized,
                              duration: 450.ms,
                            );
                      }

                      final lessonIndex = hasBrowseAll ? index - 1 : index;
                      final lesson = data[lessonIndex];
                      final isLocked =
                          isPremium &&
                          !isUnlocked &&
                          lessonIndex >= category.previewLessonCount;

                      final primaryTitle = primaryLocalizedText(
                        olChiki: lesson.titleOlChiki,
                        latin: lesson.titleLatin,
                        scriptMode: scriptMode,
                      );
                      final secondaryTitle = secondaryLocalizedText(
                        olChiki: lesson.titleOlChiki,
                        latin: lesson.titleLatin,
                        scriptMode: scriptMode,
                      );

                      final cardWidget = _LessonCard(
                        lesson: lesson,
                        primaryTitle: primaryTitle,
                        secondaryTitle: secondaryTitle ?? '',
                        scriptMode: scriptMode,
                        isDark: isDark,
                        index: lessonIndex,
                        isLocked: isLocked,
                        gradient: brandGradient,
                        themeColor: themeColor,
                        showPreviewBadge:
                            isPremium &&
                            !isUnlocked &&
                            lessonIndex < category.previewLessonCount,
                        onTap: isLocked
                            ? () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      PaywallBottomSheet(category: category),
                                );
                              }
                            : () {
                                context.push('/lesson/${lesson.id}');
                              },
                      );

                      return _buildTimelineItem(
                            card: cardWidget,
                            index: index,
                            isFirst: index == 0,
                            isLast: index == totalCount - 1,
                            isDark: isDark,
                            isLocked: isLocked,
                            themeColor: themeColor,
                            gradient: brandGradient,
                            stepNodeChild: Text(
                              '${lessonIndex + 1}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: (index * 80).ms, duration: 400.ms)
                          .slideY(
                            begin: 0.08,
                            end: 0,
                            curve: MotionTokens.emphasized,
                            duration: 450.ms,
                          );
                    }, childCount: totalCount),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverFillRemaining(
                child: Center(
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
                        onPressed: () {
                          ref.invalidate(
                            contentListProvider((ContentKind.lesson, widget.categoryId)),
                          );
                          ref.invalidate(
                            contentListProvider((ContentKind.lesson, null)),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CategoryEntity? _findCategory(List<CategoryEntity> categories, String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  Widget _buildEmptyState(bool isDark, [dynamic category]) {
    final id = category?.id ?? '';
    final isAlphabet =
        id == 'cat_alphabets' || id == 'cat_letters' || id == 'letters';

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
              isAlphabet ? Icons.translate_rounded : Icons.school_outlined,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isAlphabet ? 'Alphabet Dictionary' : 'No lessons yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAlphabet
                ? 'Browse all available Ol Chiki letters'
                : 'Check back soon for new content',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          if (isAlphabet) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/letter/standalone/all');
              },
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Open Dictionary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;
  final bool isDark;

  _TimelinePainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: isDark ? 0.25 : 0.12)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double startY = isFirst ? 32.0 : 0.0;
    final double endY = isLast ? 32.0 : size.height;

    canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), paint);
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

class _LessonCard extends StatelessWidget {
  final dynamic lesson;
  final String primaryTitle;
  final String secondaryTitle;
  final String scriptMode;
  final bool isDark;
  final int index;
  final VoidCallback onTap;
  final bool isLocked;
  final bool showPreviewBadge;
  final LinearGradient gradient;
  final Color themeColor;

  const _LessonCard({
    required this.lesson,
    required this.primaryTitle,
    required this.secondaryTitle,
    required this.scriptMode,
    required this.isDark,
    required this.index,
    required this.onTap,
    required this.gradient,
    required this.themeColor,
    this.isLocked = false,
    this.showPreviewBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
        : Colors.white;
    final lockedBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.2)
        : const Color(0xFFF8FAFC);

    final activeBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);
    final lockedBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.02);

    return PressableScale(
      onTap: onTap,
      child: Hero(
        tag: MotionTokens.heroTag('lesson', lesson.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLocked ? lockedBgColor : activeBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLocked ? lockedBorderColor : activeBorderColor,
            ),
            boxShadow: isLocked || isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildLevelBadge(lesson.level, isDark),
                        if (showPreviewBadge) ...[
                          const SizedBox(width: 6),
                          _buildPreviewBadge(isDark),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      primaryTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: primaryLocalizedFontFamily(scriptMode),
                        color: isLocked
                            ? (isDark ? Colors.white38 : Colors.black38)
                            : (isDark ? Colors.white : Colors.black87),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (secondaryTitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        secondaryTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'OlChiki',
                          color: isLocked
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : (isDark ? Colors.white54 : Colors.black45),
                        ),
                      ),
                    ],
                    if (lesson.description != null &&
                        lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        lesson.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isLocked
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : (isDark ? Colors.white38 : Colors.black54),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 13,
                          color: isLocked
                              ? (isDark ? Colors.white24 : Colors.black26)
                              : themeColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Available Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isLocked
                                ? (isDark ? Colors.white24 : Colors.black26)
                                : (isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildCTA(isLocked, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level, bool isDark) {
    Color badgeColor;
    String label;
    IconData icon;

    switch (level.toLowerCase()) {
      case 'advanced':
        badgeColor = AppColors.duoRed;
        label = 'Advanced';
        icon = Icons.whatshot_rounded;
        break;
      case 'intermediate':
        badgeColor = AppColors.duoOrange;
        label = 'Intermediate';
        icon = Icons.bolt_rounded;
        break;
      case 'beginner':
      default:
        badgeColor = AppColors.duoGreen;
        label = 'Beginner';
        icon = Icons.star_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.duoYellow.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.duoYellow.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 11,
            color: AppColors.duoYellow,
          ),
          const SizedBox(width: 4),
          Text(
            'FREE PREVIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.duoYellow : AppColors.duoYellowDark,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(bool isLocked, bool isDark) {
    if (isLocked) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : const Color(0xFFE2E8F0),
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.lock_rounded,
            color: isDark ? Colors.white24 : Colors.black26,
            size: 16,
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _BrowseAllCard extends StatelessWidget {
  final String label;
  final String olChikiLabel;
  final String description;
  final VoidCallback onTap;
  final bool isDark;
  final LinearGradient gradient;
  final Color themeColor;

  const _BrowseAllCard({
    required this.label,
    required this.olChikiLabel,
    required this.description,
    required this.onTap,
    required this.isDark,
    required this.gradient,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = isDark
        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
        : Colors.white;
    final activeBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.04);

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: activeBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: activeBorderColor),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeColor.withValues(
                          alpha: isDark ? 0.3 : 0.15,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 11,
                          color: themeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BROWSE VIEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: themeColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (olChikiLabel.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      olChikiLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'OlChiki',
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.black54,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
