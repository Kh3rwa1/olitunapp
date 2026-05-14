import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import 'admin_brand_mark.dart';

class AdminSidebar extends StatelessWidget {
  final bool isCompact;
  const AdminSidebar({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          _buildBrand(isDark),
          Container(height: 1, color: AdminTokens.divider(isDark)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 14,
                vertical: 16,
              ),
              children: [
                _SectionLabel(label: 'OVERVIEW', isCompact: isCompact),
                AdminNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/admin',
                  onTap: () => context.go('/admin'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'CONTENT', isCompact: isCompact),
                AdminNavItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  isSelected: location == '/admin/categories',
                  onTap: () => context.go('/admin/categories'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.featured_play_list_rounded,
                  label: 'Banners',
                  isSelected: location == '/admin/banners',
                  onTap: () => context.go('/admin/banners'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Letters & Alphabet',
                  isSelected: location == '/admin/letters',
                  onTap: () => context.go('/admin/letters'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.pin_rounded,
                  label: 'Numbers',
                  isSelected: location == '/admin/numbers',
                  onTap: () => context.go('/admin/numbers'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'Words & Vocabulary',
                  isSelected: location == '/admin/words',
                  onTap: () => context.go('/admin/words'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.format_quote_rounded,
                  label: 'Sentences',
                  isSelected: location == '/admin/sentences',
                  onTap: () => context.go('/admin/sentences'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.school_rounded,
                  label: 'Lessons',
                  isSelected: location.startsWith('/admin/lessons'),
                  onTap: () => context.go('/admin/lessons'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.music_note_rounded,
                  label: 'Bakhed & Stories',
                  isSelected: location == '/admin/rhymes',
                  onTap: () => context.go('/admin/rhymes'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Bakhed Categories',
                  isSelected: location == '/admin/rhymes/categories',
                  onTap: () => context.go('/admin/rhymes/categories'),
                  isCompact: isCompact,
                  indent: !isCompact,
                ),
                AdminNavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  isSelected: location == '/admin/quizzes',
                  onTap: () => context.go('/admin/quizzes'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'MEDIA', isCompact: isCompact),
                AdminNavItem(
                  icon: Icons.perm_media_rounded,
                  label: 'Media Library',
                  isSelected: location == '/admin/media',
                  onTap: () => context.go('/admin/media'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio Files',
                  isSelected: location == '/admin/audio',
                  onTap: () => context.go('/admin/audio'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.videocam_rounded,
                  label: 'Video Files',
                  isSelected: location == '/admin/video',
                  onTap: () => context.go('/admin/video'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'SYSTEM', isCompact: isCompact),
                AdminNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: location == '/admin/settings',
                  onTap: () => context.go('/admin/settings'),
                  isCompact: isCompact,
                ),
              ],
            ),
          ),
          _buildFooter(context, isDark),
        ],
      ),
    );
  }

  Widget _buildBrand(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 18,
      ),
      child: Row(
        mainAxisAlignment: isCompact
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          AdminBrandMark(size: isCompact ? 38 : 42),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Olitun',
                    style: AdminTokens.cardTitle(
                      isDark,
                    ).copyWith(letterSpacing: -0.3, fontSize: 18),
                  ),
                  Text(
                    'Content Studio',
                    style: AdminTokens.label(isDark).copyWith(
                      color: AdminTokens.textTertiary(isDark),
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AdminTokens.accentSoft(isDark),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AdminTokens.accentBorder(isDark)),
              ),
              child: const Text(
                'v2',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: IconButton(
          tooltip: 'Back to app',
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AdminTokens.accentSoft(isDark),
                    shape: BoxShape.circle,
                    border: Border.all(color: AdminTokens.accentBorder(isDark)),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Administrator',
                        style: AdminTokens.bodyStrong(
                          isDark,
                        ).copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Appwrite Teams',
                        style: AdminTokens.label(isDark).copyWith(
                          color: AdminTokens.textTertiary(isDark),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
                  boxShadow: AdminTokens.brandGlow(
                    AppColors.primary,
                    strength: 0.7,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Back to App',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isCompact;
  const _SectionLabel({required this.label, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            width: 18,
            height: 2,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white12
                  : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Text(
        label,
        style: AdminTokens.eyebrow(isDark).copyWith(
          fontSize: 10.5,
          color: AdminTokens.textMuted(isDark),
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

class AdminNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;
  final bool indent;

  const AdminNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
    this.indent = false,
  });

  @override
  State<AdminNavItem> createState() => _AdminNavItemState();
}

class _AdminNavItemState extends State<AdminNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = widget.isSelected;

    final fg = selected
        ? AppColors.primary
        : (_hovering
              ? AdminTokens.textPrimary(isDark)
              : AdminTokens.textSecondary(isDark));

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            child: Stack(
              children: [
                if (selected)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.fromLTRB(
                    widget.isCompact ? 10 : (widget.indent ? 30 : 14),
                    10,
                    14,
                    10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AdminTokens.accentSoft(isDark)
                        : (_hovering
                              ? AdminTokens.sunken(isDark)
                              : Colors.transparent),
                    borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: widget.isCompact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      Icon(widget.icon, size: 19, color: fg),
                      if (!widget.isCompact) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13.5,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: fg,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
