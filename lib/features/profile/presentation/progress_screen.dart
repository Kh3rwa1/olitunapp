import 'package:flutter/material.dart';
import 'package:itun/core/theme/app_typography.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../domain/entities/user_stats_entity.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';

// Extracted widgets
import 'widgets/profile_hero_card.dart';
import 'widgets/stats_widgets.dart';
import 'widgets/quiz_performance_card.dart';
import 'widgets/edit_name_sheet.dart';
import 'widgets/streak_calendar.dart';
import 'widgets/mastery_chart.dart';
import 'widgets/next_milestone_card.dart';
import 'widgets/progress_screen_sections.dart';
import '../../../core/ads/widgets/native_ad_widget.dart';
import '../../../core/ads/widgets/banner_ad_widget.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final avatarId = ref.watch(userAvatarIdProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return statsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        body: ProgressErrorState(
          isDark: isDark,
          onRetry: () => ref.invalidate(userStatsProvider),
        ),
      ),
      data: (stats) {
        final stars = stats.totalStars;
        final quizzesCompleted = stats.quizzesCompletedCount;
        final avatarColors = [AppColors.primary, AppColors.primaryDark];
        final memberSince = ref
            .watch(accountCreatedAtProvider)
            .value
            ?.toIso8601String()
            .substring(0, 10);
        final learningTime = stats.totalLearningMinutes;

        return Scaffold(
          backgroundColor: isDark
              ? AppColors.darkBackground
              : AppColors.lightBackground,
          body: BrandedRefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userStatsProvider);
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Beautiful App Bar with Settings Gear Button
                SliverAppBar(
                  expandedHeight: kToolbarHeight,
                  pinned: true,
                  backgroundColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'Profile',
                    style: AppTypography.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Settings',
                      icon: Icon(
                        Icons.settings_rounded,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      onPressed: () {
                        context.push('/settings');
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                SliverToBoxAdapter(
                  child: ResponsivePageContainer(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ═══════════════ PROFILE HERO SECTION ═══════════════
                        ProfileHeroCard(
                              userName: userName,
                              avatarColors: avatarColors,
                              avatarId: avatarId,
                              level: stats.learnerLevel,
                              levelIndex: stats.levelIndex,
                              memberSince: memberSince,
                              overallProgress: stats.overallProgress,
                              isDark: isDark,
                              onEditName: () =>
                                  _showEditNameDialog(context, ref, userName),
                              onEditAvatar: () =>
                                  _showAvatarPicker(context, ref),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 24),

                        // ═══════════════ STREAK CALENDAR ═══════════════
                        StreakCalendar(stats: stats),

                        const SizedBox(height: 24),

                        // ═══════════════ NEXT MILESTONE ═══════════════
                        const NextMilestoneCard(),

                        const SizedBox(height: 16),
                        const RepaintBoundary(
                          child: NativeAdWidget(placement: 'profile_native'),
                        ),
                        const SizedBox(height: 24),

                        // ═══════════════ CORE STATS ROW ═══════════════
                        _buildSectionHeader('YOUR STATS', isDark),
                        const SizedBox(height: 14),
                        StatsGrid(
                          stars: stars,
                          quizzesCompleted: quizzesCompleted,
                          learningTime: learningTime,
                          isDark: isDark,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 32),

                        _buildSectionHeader('SKILLS MASTERY', isDark),
                        const SizedBox(height: 16),
                        SkillsGrid(
                          isDark: isDark,
                          isTablet: isTablet,
                          stats: stats,
                        ),
                        const SizedBox(height: 32),

                        _buildSectionHeader('QUIZ ANALYSIS', isDark),
                        const SizedBox(height: 16),
                        QuizPerformanceCard(
                          quizzes: quizzesCompleted,
                          accuracy: (stats.quizAccuracy * 100).round(),
                          bestScore: stats.bestQuizScore,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),
                        MasteryTimelineChart(stats: stats),
                        const SizedBox(height: 32),

                        _buildSectionHeader('MY BINTI GURU BOOKINGS', isDark),
                        const SizedBox(height: 16),
                        BintiGuruBookingsSection(isDark: isDark),
                        const SizedBox(height: 32),

                        _buildSectionHeader('ACCOUNT', isDark),
                        const SizedBox(height: 12),
                        ActionTilesSection(
                          isDark: isDark,
                          onEditName: () {
                            final name = ref.read(userNameProvider);
                            _showEditNameDialog(context, ref, name);
                          },
                          onShare: () =>
                              _shareProgress(context, userName, stats),
                        ),
                        const SizedBox(height: 24),
                        const RepaintBoundary(
                          child: BannerAdWidget(placement: 'profile_bottom'),
                        ),
                        // Clears the floating nav: 80 (nav) + 15 (margin) + viewPadding.bottom
                        // + breathing room, so the last card never sits under it.
                        SizedBox(
                          height: isDesktop
                              ? 32
                              : MediaQuery.of(context).viewPadding.bottom + 135,
                        ),
                      ],
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

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.7)
            : AppColors.primaryDark,
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0);
  }

  Future<void> _shareProgress(
    BuildContext context,
    String userName,
    UserStatsEntity stats,
  ) async {
    final renderObject = context.findRenderObject();
    final origin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;
    final progress = (stats.overallProgress * 100).round();
    final accuracy = (stats.quizAccuracy * 100).round();
    final message = [
      'Johar! 🙏 I just completed the Ol Chiki Script lesson on Olitun! Join me in mastering Santali.',
      '',
      '$userName\'s Progress Dashboard:',
      '• Level: ${stats.learnerLevel}',
      '• Overall progress: $progress%',
      '• Streak: ${stats.currentStreak} days',
      '• Stars earned: ${stats.totalStars}',
      '• Lessons completed: ${stats.lessonsCompletedCount}',
      '• Quiz accuracy: $accuracy%',
    ].join('\n');

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Olitun progress',
          subject: 'My Olitun learning progress',
          text: message,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // Failure is surfaced to the user via the snackbar below.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open share sheet'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => EditNameSheet(
        initialName: currentName,
        isDark: isDark,
        onSave: (name) => ref.read(userStatsProvider.notifier).updateName(name),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColorIndex = ref.read(userAvatarColorIndexProvider);
    final currentAvatarId = ref.read(userAvatarIdProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          int selectedColor = currentColorIndex;
          String selectedAvatar = currentAvatarId;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose Your Avatar',
                  style: AppTypography.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Color palette
                Text(
                  'Background Color',
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(AppColors.avatarPalettes.length, (i) {
                    final isSelected = i == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => selectedColor = i);
                        ref
                            .read(userStatsProvider.notifier)
                            .updateAvatar(selectedAvatar, i);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: AppColors.avatarPalettes[i],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.avatarPalettes[i][0]
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                // Avatar animation grid (bundled Lottie only — no emoji)
                Text(
                  'Avatar Animation',
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 10),
                Consumer(
                  builder: (ctx, ref, _) {
                    final avatarsAsync = ref.watch(availableAvatarsProvider);
                    return avatarsAsync.when(
                      loading: () => const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox(
                        height: 60,
                        child: Center(
                          child: Text('Could not load avatar animations'),
                        ),
                      ),
                      data: (avatars) => SizedBox(
                        height: 264,
                        child: GridView.builder(
                          shrinkWrap: true,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: avatars.length + 1,
                          itemBuilder: (ctx, i) {
                            if (i == 0) {
                              final isSelected = selectedAvatar.isEmpty;
                              return GestureDetector(
                                onTap: () {
                                  setSheetState(() => selectedAvatar = '');
                                  ref
                                      .read(userStatsProvider.notifier)
                                      .updateAvatar('', selectedColor);
                                  HapticFeedback.selectionClick();
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(14),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.primary,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person_rounded, size: 32),
                                  ),
                                ),
                              );
                            }
                            final avatar = avatars[i - 1];
                            final isSelected = avatar.id == selectedAvatar;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() => selectedAvatar = avatar.id);
                                ref
                                    .read(userStatsProvider.notifier)
                                    .updateAvatar(avatar.id, selectedColor);
                                HapticFeedback.selectionClick();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.primary,
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Lottie.asset(
                                      avatar.assetPath,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.person_rounded,
                                                size: 32,
                                              ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      avatar.label,
                                      style: AppTypography.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
