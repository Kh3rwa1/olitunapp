import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/bento_grid.dart';
import 'settings_screen.dart';
import 'package:itun/features/profile/presentation/providers/profile_providers.dart';

// Extracted widgets
import 'widgets/profile_hero_card.dart';
import 'widgets/stats_widgets.dart';
import 'widgets/quiz_performance_card.dart';
import 'widgets/edit_name_sheet.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final statsAsync = ref.watch(userStatsProvider);
    final avatarEmoji = ref.watch(userAvatarEmojiProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return statsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (stats) {
        final streak = stats.currentStreak;
        final stars = stats.totalStars;
        final quizzesCompleted = stats.quizzesCompletedCount;
        final avatarColors = [AppColors.primary, AppColors.primaryDark];
        const memberSince = 'April 2024';
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
                // Minimal app bar
                SliverAppBar(
                  expandedHeight: 0,
                  pinned: true,
                  backgroundColor: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  elevation: 0,
                  toolbarHeight: 0,
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
                              avatarEmoji: avatarEmoji,
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

                        // ═══════════════ CORE STATS ROW ═══════════════
                        _buildSectionHeader('YOUR STATS', isDark),
                        const SizedBox(height: 14),
                        StatsGrid(
                          streak: streak,
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
                        const SizedBox(height: 32),

                        _buildSectionHeader('ACCOUNT', isDark),
                        const SizedBox(height: 12),
                        _buildActionTiles(context, ref, isDark),
                        SizedBox(height: isDesktop ? 32 : 120),
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
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.7)
            : AppColors.primaryDark,
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05, end: 0);
  }

  Widget _buildActionTiles(BuildContext context, WidgetRef ref, bool isDark) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        AnimatedBentoChild(
          index: 0,
          child: _BentoActionCard(
            icon: Icons.edit_rounded,
            label: 'Edit Name',
            color: AppColors.duoBlue,
            isDark: isDark,
            onTap: () {
              final name = ref.read(userNameProvider);
              _showEditNameDialog(context, ref, name);
            },
          ),
        ),
        AnimatedBentoChild(
          index: 1,
          child: _BentoActionCard(
            icon: Icons.share_rounded,
            label: 'Share',
            color: AppColors.primary,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Coming soon!'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ),
        AnimatedBentoChild(
          index: 2,
          child: _BentoActionCard(
            icon: Icons.settings_rounded,
            label: 'Settings',
            color: AppColors.duoOrange,
            isDark: isDark,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ),
      ],
    );
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
        onSave: (name) =>
            ref.read(userStatsProvider.notifier).updateName(name),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentColorIndex = ref.read(userAvatarColorIndexProvider);
    final currentEmoji = ref.read(userAvatarEmojiProvider);

    const emojis = [
      '😀',
      '😎',
      '🤓',
      '🧑‍💻',
      '👨‍🎓',
      '👩‍🎓',
      '🦊',
      '🐱',
      '🐶',
      '🐼',
      '🦁',
      '🐸',
      '🦋',
      '🌸',
      '🌺',
      '🌻',
      '🍀',
      '⭐',
      '🔥',
      '💎',
      '🎯',
      '🎵',
      '🎮',
      '🏆',
      '🚀',
      '🌈',
      '🎨',
      '📚',
      '💡',
      '🦄',
    ];

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
          String selectedEmoji = currentEmoji;

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
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Color palette
                Text(
                  'Background Color',
                  style: GoogleFonts.inter(
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
                            .updateAvatar(currentEmoji, i);
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

                // Emoji grid
                Text(
                  'Avatar Emoji',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                    itemCount: emojis.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        final isSelected = selectedEmoji.isEmpty;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedEmoji = '');
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
                            child: Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 24,
                                color: isDark ? Colors.white54 : Colors.black38,
                              ),
                            ),
                          ),
                        );
                      }
                      final emoji = emojis[i - 1];
                      final isSelected = emoji == selectedEmoji;
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() => selectedEmoji = emoji);
                          ref
                              .read(userStatsProvider.notifier)
                              .updateAvatar(emoji, currentColorIndex);
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════ BENTO ACTION CARD ═══════════════

class _BentoActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _BentoActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCell(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
