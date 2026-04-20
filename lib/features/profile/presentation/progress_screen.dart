import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/providers.dart';
import '../../../shared/providers/progress_provider.dart';
import '../../../core/presentation/layout/responsive_layout.dart';
import '../../../shared/widgets/bento_grid.dart';
import 'settings_screen.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userName = ref.watch(userNameProvider);
    final progressData = ref.watch(progressProvider);
    final streak = progressData.currentStreak;
    final stars = ref.watch(userStarsProvider);
    final quizzesCompleted = ref.watch(quizzesCompletedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = ResponsiveLayout.isTablet(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final avatarColors = ref.watch(userAvatarColorsProvider);
    final avatarEmoji = ref.watch(userAvatarEmojiProvider);
    final memberSince = ref.watch(memberSinceProvider);
    final quizAccuracy = (progressData.quizAccuracy * 100).round();
    final learningTime = progressData.totalLearningMinutes;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Minimal app bar
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: isDark
                ? AppColors.darkBackground
                : AppColors.lightBackground,
            elevation: 0,
            toolbarHeight: 0,
          ),

          SliverToBoxAdapter(
            child: ResponsivePageContainer(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ═══════════════ PROFILE HERO SECTION ═══════════════
                  _ProfileHeroCard(
                        userName: userName,
                        avatarColors: avatarColors,
                        avatarEmoji: avatarEmoji,
                        level: progressData.learnerLevel,
                        levelIndex: progressData.levelIndex,
                        memberSince: memberSince,
                        overallProgress: progressData.overallProgress,
                        isDark: isDark,
                        onEditName: () =>
                            _showEditNameDialog(context, ref, userName),
                        onEditAvatar: () => _showAvatarPicker(context, ref),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 24),

                  // ═══════════════ CORE STATS ROW ═══════════════
                  _buildSectionHeader('YOUR STATS', isDark),
                  const SizedBox(height: 14),
                  _buildStatsGrid(
                    streak: streak,
                    stars: stars,
                    quizzesCompleted: quizzesCompleted,
                    learningTime: learningTime,
                    isDark: isDark,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 32),

                  // ═══════════════ SKILLS MASTERY ═══════════════
                  _buildSectionHeader('SKILLS MASTERY', isDark),
                  const SizedBox(height: 16),
                  _buildSkillsGrid(context, isDark, isTablet, progressData),
                  const SizedBox(height: 32),

                  // ═══════════════ QUIZ ANALYSIS ═══════════════
                  _buildSectionHeader('QUIZ ANALYSIS', isDark),
                  const SizedBox(height: 16),
                  _QuizPerformanceCard(
                    quizzes: quizzesCompleted,
                    accuracy: quizAccuracy,
                    bestScore: progressData.bestQuizScore,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),

                  // ═══════════════ ACCOUNT ACTIONS ═══════════════
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

  Widget _buildStatsGrid({
    required int streak,
    required int stars,
    required int quizzesCompleted,
    required int learningTime,
    required bool isDark,
    required bool isTablet,
  }) {
    return Column(
      children: [
        // Hero stat — streak spans full width
        AnimatedBentoChild(
          index: 0,
          child: BentoCell(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: [
                AppColors.duoOrange.withValues(alpha: isDark ? 0.15 : 0.08),
                AppColors.duoOrange.withValues(alpha: isDark ? 0.05 : 0.02),
              ],
            ),
            border: Border.all(
              color: AppColors.duoOrange.withValues(alpha: isDark ? 0.2 : 0.12),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.duoOrange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.duoOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$streak',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'DAY STREAK',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.duoOrange,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.duoOrange.withValues(alpha: 0.4),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 3 stat pills in a row
        Row(
          children: [
            Expanded(
              child: AnimatedBentoChild(
                index: 1,
                child: _StatPill(
                  data: _StatData(Icons.star_rounded, '$stars', 'Stars', AppColors.duoYellow),
                  isDark: isDark,
                  delay: 80,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedBentoChild(
                index: 2,
                child: _StatPill(
                  data: _StatData(Icons.quiz_rounded, '$quizzesCompleted', 'Quizzes', AppColors.duoBlue),
                  isDark: isDark,
                  delay: 160,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedBentoChild(
                index: 3,
                child: _StatPill(
                  data: _StatData(Icons.timer_rounded, '${learningTime}m', 'Time', AppColors.primary),
                  isDark: isDark,
                  delay: 240,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkillsGrid(
    BuildContext context,
    bool isDark,
    bool isTablet,
    UserProgressData progressData,
  ) {
    final skills = [
      _SkillData('Alphabet', progressData.alphabetProgress, AppColors.duoBlue),
      _SkillData('Numbers', progressData.numbersProgress, AppColors.duoOrange),
      _SkillData(
        'Vocabulary',
        progressData.vocabularyProgress,
        AppColors.duoGreen,
      ),
      _SkillData('Rhymes', progressData.rhymesProgress, AppColors.primary),
    ];

    return Row(
      children: skills.asMap().entries.map((entry) {
        final i = entry.key;
        final skill = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < skills.length - 1 ? 10 : 0),
            child: _SkillProgressCard(
              label: skill.label,
              progress: skill.progress,
              color: skill.color,
              isDark: isDark,
              delay: i * 100,
            ),
          ),
        );
      }).toList(),
    );
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
    final controller = TextEditingController(text: currentName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 20,
        ),
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
              'Edit Your Name',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black26,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    updateUserName(ref, name); // Fire and forget or await?
                    // Let's await to be safe and provide feedback if it fails?
                    // But the UI closes immediately.
                    // I'll keep it as is but it's now a Future.
                    HapticFeedback.mediumImpact();
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
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
                  children: List.generate(avatarPalettes.length, (i) {
                    final isSelected = i == selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setSheetState(() => selectedColor = i);
                        updateAvatarColorIndex(ref, i);
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: avatarPalettes[i]),
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
                                    color: avatarPalettes[i][0].withValues(
                                      alpha: 0.4,
                                    ),
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
                    itemCount: emojis.length + 1, // +1 for "remove" option
                    itemBuilder: (ctx, i) {
                      if (i == 0) {
                        // Remove emoji option — show initial letter
                        final isSelected = selectedEmoji.isEmpty;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => selectedEmoji = '');
                            updateAvatarEmoji(ref, '');
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
                          updateAvatarEmoji(ref, emoji);
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

// ═══════════════ DATA CLASSES ═══════════════

class _StatData {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatData(this.icon, this.value, this.label, this.color);
}

class _SkillData {
  final String label;
  final double progress;
  final Color color;
  const _SkillData(this.label, this.progress, this.color);
}

// ═══════════════ PROFILE HERO CARD ═══════════════

class _ProfileHeroCard extends StatelessWidget {
  final String userName;
  final List<Color> avatarColors;
  final String avatarEmoji;
  final String level;
  final int levelIndex;
  final String memberSince;
  final double overallProgress;
  final bool isDark;
  final VoidCallback onEditName;
  final VoidCallback onEditAvatar;

  const _ProfileHeroCard({
    required this.userName,
    required this.avatarColors,
    required this.avatarEmoji,
    required this.level,
    required this.levelIndex,
    required this.memberSince,
    required this.overallProgress,
    required this.isDark,
    required this.onEditName,
    required this.onEditAvatar,
  });

  Color _getLevelColor() {
    const colors = [
      Color(0xFF9E9E9E), // Beginner — grey
      Color(0xFF1CB0F6), // Intermediate — blue
      Color(0xFFFF9600), // Advanced — orange
      Color(0xFFFFD700), // Master — gold
    ];
    return colors[levelIndex.clamp(0, 3)];
  }

  String _formatDate(String iso) {
    try {
      final parts = iso.split('-');
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[int.parse(parts[1])]} ${parts[2]}, ${parts[0]}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.white.withValues(alpha: 0.06), Colors.white.withValues(alpha: 0.02)]
              : [Colors.white, Colors.white.withValues(alpha: 0.9)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              GestureDetector(
                onTap: onEditAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: avatarColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: avatarColors[0].withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: avatarEmoji.isNotEmpty
                            ? Text(
                                avatarEmoji,
                                style: const TextStyle(fontSize: 32),
                              )
                            : Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'L',
                                style: GoogleFonts.fredoka(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF161B22)
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Name + Level + Member Since
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: onEditName,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: isDark ? Colors.white30 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor().withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getLevelColor().withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                levelIndex >= 3
                                    ? Icons.workspace_premium_rounded
                                    : levelIndex >= 2
                                    ? Icons.diamond_rounded
                                    : Icons.school_rounded,
                                size: 12,
                                color: _getLevelColor(),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                level,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _getLevelColor(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Since ${_formatDate(memberSince)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isDark ? Colors.white30 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Overall progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                  Text(
                    '${(overallProgress * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: overallProgress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════ STAT PILL ═══════════════

class _StatPill extends StatelessWidget {
  final _StatData data;
  final bool isDark;
  final int delay;

  const _StatPill({
    required this.data,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Icon(data.icon, color: data.color, size: 20),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.3),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().scale(
      delay: Duration(milliseconds: 200 + delay),
      duration: 400.ms,
      curve: Curves.easeOutBack,
    );
  }
}

// ═══════════════ SKILL PROGRESS CARD ═══════════════

class _SkillProgressCard extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;
  final bool isDark;
  final int delay;

  const _SkillProgressCard({
    required this.label,
    required this.progress,
    required this.color,
    required this.isDark,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: Duration(milliseconds: 1000 + delay),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  Text(
                    '${(value * 100).toInt()}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 300 + delay),
      duration: 400.ms,
    );
  }
}

// ═══════════════ QUIZ PERFORMANCE CARD ═══════════════

class _QuizPerformanceCard extends StatelessWidget {
  final int quizzes;
  final int accuracy;
  final int bestScore;
  final bool isDark;

  const _QuizPerformanceCard({
    required this.quizzes,
    required this.accuracy,
    required this.bestScore,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.duoBlue, AppColors.duoBlueDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.duoBlue.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left — accuracy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment Score',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$accuracy%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, left: 4),
                          child: Text(
                            'Avg',
                            style: GoogleFonts.inter(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Right — stats pills
              Column(
                children: [
                  _QuizMiniStat(value: '$quizzes', label: 'Total'),
                  const SizedBox(height: 8),
                  _QuizMiniStat(value: '$bestScore%', label: 'Best'),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: 400.ms, duration: 500.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

class _QuizMiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _QuizMiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
    );
  }
}
