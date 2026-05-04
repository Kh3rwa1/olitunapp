import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/admin_tokens.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/admin_auth_provider.dart';

/// Admin shell — refined sidebar (desktop / tablet) and drawer (mobile) plus
/// a polished page frame: brand mark, grouped navigation with section labels,
/// considered active / hover state, an account footer, and a max-width
/// content container so dense screens never feel stretched.
class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width > 1180;
    final isTablet = width > 760 && width <= 1180;

    final adminAsync = ref.watch(adminAuthProvider);
    if (adminAsync.isLoading) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (adminAsync.value != true) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AdminTokens.accentSoft(isDark),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AdminTokens.accentBorder(isDark)),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text('Admin access required',
                  style: AdminTokens.sectionTitle(isDark)),
            ],
          ),
        ),
      );
    }

    if (isDesktop || isTablet) {
      return Scaffold(
        backgroundColor: AdminTokens.base(isDark),
        body: Stack(
          children: [
            _buildAmbientBackdrop(isDark),
            Row(
              children: [
                Container(
                  width: isDesktop ? 272 : 84,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0A0E15).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.85),
                    border: Border(
                      right: BorderSide(color: AdminTokens.divider(isDark)),
                    ),
                  ),
                  child: _AdminSidebar(isCompact: !isDesktop),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _AdminTopBar(isDark: isDark),
                      Expanded(
                        child: ClipRect(
                          child: Material(
                            color: Colors.transparent,
                            child: child,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mobile
    return Scaffold(
      backgroundColor: AdminTokens.base(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu_rounded,
                color: AdminTokens.textPrimary(isDark)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BrandMark(size: 28),
            const SizedBox(width: 10),
            Text(
              'Olitun CMS',
              style: AdminTokens.cardTitle(isDark),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AdminTokens.raised(isDark),
        width: 288,
        child: const _AdminSidebar(),
      ),
      body: Stack(
        children: [
          _buildAmbientBackdrop(isDark),
          Material(color: Colors.transparent, child: child),
        ],
      ),
    );
  }

  Widget _buildAmbientBackdrop(bool isDark) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.7, -0.9),
              radius: 1.4,
              colors: [
                AppColors.primary
                    .withValues(alpha: isDark ? 0.07 : 0.05),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AdminTokens.brandGlow(AppColors.primary, strength: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/icons/olitun_logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  final bool isDark;
  const _AdminTopBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final crumbs = _crumbsFor(location);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AdminTokens.divider(isDark))),
      ),
      child: Row(
        children: [
          Icon(Icons.dashboard_customize_rounded,
              size: 16, color: AdminTokens.textTertiary(isDark)),
          const SizedBox(width: 8),
          for (var i = 0; i < crumbs.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  size: 16, color: AdminTokens.textMuted(isDark)),
              const SizedBox(width: 8),
            ],
            Text(
              crumbs[i],
              style: AdminTokens.label(isDark).copyWith(
                color: i == crumbs.length - 1
                    ? AdminTokens.textPrimary(isDark)
                    : AdminTokens.textTertiary(isDark),
                fontWeight: i == crumbs.length - 1
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
          const Spacer(),
          _TopBarChip(
            isDark: isDark,
            icon: Icons.bolt_rounded,
            label: 'Live',
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          _TopBarChip(
            isDark: isDark,
            icon: Icons.person_outline_rounded,
            label: 'Admin',
          ),
        ],
      ),
    );
  }

  List<String> _crumbsFor(String location) {
    if (location == '/admin' || location == '/admin/') return ['Dashboard'];
    final segments = location
        .replaceFirst('/admin/', '')
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    return ['Admin', ...segments.map(_titleize)];
  }

  String _titleize(String s) {
    final cleaned = s.replaceAll('-', ' ').replaceAll('_', ' ');
    return cleaned
        .split(' ')
        .map((p) => p.isEmpty
            ? p
            : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _TopBarChip extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color? color;
  const _TopBarChip({
    required this.isDark,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AdminTokens.textSecondary(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: isDark ? 0.14 : 0.1)
            : AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.28)
              : AdminTokens.border(isDark),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 6),
          Text(
            label,
            style: AdminTokens.label(isDark).copyWith(
              color: tint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final bool isCompact;
  const _AdminSidebar({this.isCompact = false});

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
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/admin',
                  onTap: () => context.go('/admin'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'CONTENT', isCompact: isCompact),
                _NavItem(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  isSelected: location == '/admin/categories',
                  onTap: () => context.go('/admin/categories'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.featured_play_list_rounded,
                  label: 'Banners',
                  isSelected: location == '/admin/banners',
                  onTap: () => context.go('/admin/banners'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.text_fields_rounded,
                  label: 'Letters & Alphabet',
                  isSelected: location == '/admin/letters',
                  onTap: () => context.go('/admin/letters'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Lessons',
                  isSelected: location.startsWith('/admin/lessons'),
                  onTap: () => context.go('/admin/lessons'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.music_note_rounded,
                  label: 'Rhymes & Stories',
                  isSelected: location == '/admin/rhymes',
                  onTap: () => context.go('/admin/rhymes'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Rhyme Categories',
                  isSelected: location == '/admin/rhymes/categories',
                  onTap: () => context.go('/admin/rhymes/categories'),
                  isCompact: isCompact,
                  indent: !isCompact,
                ),
                _NavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  isSelected: location == '/admin/quizzes',
                  onTap: () => context.go('/admin/quizzes'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'MEDIA', isCompact: isCompact),
                _NavItem(
                  icon: Icons.perm_media_rounded,
                  label: 'Media Library',
                  isSelected: location == '/admin/media',
                  onTap: () => context.go('/admin/media'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.audiotrack_rounded,
                  label: 'Audio Files',
                  isSelected: location == '/admin/audio',
                  onTap: () => context.go('/admin/audio'),
                  isCompact: isCompact,
                ),
                _NavItem(
                  icon: Icons.videocam_rounded,
                  label: 'Video Files',
                  isSelected: location == '/admin/video',
                  onTap: () => context.go('/admin/video'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'SYSTEM', isCompact: isCompact),
                _NavItem(
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
          _BrandMark(size: isCompact ? 38 : 42),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Olitun',
                    style: AdminTokens.cardTitle(isDark).copyWith(
                      letterSpacing: -0.3,
                      fontSize: 18,
                    ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    border: Border.all(
                      color: AdminTokens.accentBorder(isDark),
                    ),
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
                        style: AdminTokens.bodyStrong(isDark)
                            .copyWith(fontSize: 13),
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
                    Icon(Icons.arrow_back_rounded,
                        size: 18, color: Colors.white),
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

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;
  final bool indent;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
    this.indent = false,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
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
                    widget.isCompact
                        ? 10
                        : (widget.indent ? 30 : 14),
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
                    borderRadius:
                        BorderRadius.circular(AdminTokens.radiusSm),
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
