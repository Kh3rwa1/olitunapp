import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/storage/hive_service.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/providers/providers.dart';
import '../../../../categories/domain/entities/category_entity.dart';
import 'admin_brand_mark.dart';

class AdminSidebar extends ConsumerWidget {
  final bool isCompact;
  const AdminSidebar({super.key, this.isCompact = false});

  void _navigate(BuildContext context, String path) {
    context.go(path);
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.isDrawerOpen) {
      scaffold.closeDrawer();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentUri = GoRouterState.of(context).uri;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoriesAsync = ref.watch(categoryNotifierProvider);

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
                // OVERVIEW
                _CollapsibleNavGroup(
                  label: 'OVERVIEW',
                  persistenceKey: 'overview',
                  isCompact: isCompact,
                  hasActiveChild: location == '/admin',
                  children: [
                    AdminNavItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isSelected: location == '/admin',
                      onTap: () => _navigate(context, '/admin'),
                      isCompact: isCompact,
                    ),
                  ],
                ),

                // CONTENT
                _CollapsibleNavGroup(
                  label: 'CONTENT',
                  persistenceKey: 'content',
                  isCompact: isCompact,
                  hasActiveChild:
                      location == '/admin/categories' ||
                      location == '/admin/affirmations' ||
                      location == '/admin/banners' ||
                      location == '/admin/lessons',
                  children: [
                    AdminNavItem(
                      icon: Icons.category_rounded,
                      label: 'Categories',
                      isSelected: location == '/admin/categories',
                      onTap: () => _navigate(context, '/admin/categories'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Daily Affirmations',
                      isSelected: location == '/admin/affirmations',
                      onTap: () => _navigate(context, '/admin/affirmations'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.featured_play_list_rounded,
                      label: 'Banners',
                      isSelected: location == '/admin/banners',
                      onTap: () => _navigate(context, '/admin/banners'),
                      isCompact: isCompact,
                    ),

                    // Dynamic Categories List
                    categoriesAsync.when(
                      data: (categories) {
                        final sortedCategories = List<CategoryEntity>.from(
                          categories,
                        )..sort((a, b) => a.order.compareTo(b.order));
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: sortedCategories.map((category) {
                            final id = category.id;
                            final iconName = category.iconName?.toLowerCase();
                            final route = '/admin/lessons?categoryId=$id';
                            IconData icon;

                            switch (iconName) {
                              case 'alphabet':
                                icon = Icons.abc_rounded;
                                break;
                              case 'numbers':
                                icon = Icons.pin_rounded;
                                break;
                              case 'words':
                                icon = Icons.text_fields_rounded;
                                break;
                              case 'sentences':
                                icon = Icons.format_quote_rounded;
                                break;
                              case 'arithmetic':
                                icon = Icons.calculate_rounded;
                                break;
                              case 'stories':
                                icon = Icons.auto_stories_rounded;
                                break;
                              default:
                                icon = Icons.category_rounded;
                            }

                            final currentId =
                                currentUri.queryParameters['categoryId'];
                            final isSelected =
                                currentUri.path == '/admin/lessons' &&
                                currentId == id;

                            return AdminNavItem(
                              icon: icon,
                              label: category.titleLatin,
                              isSelected: isSelected,
                              onTap: () => _navigate(context, route),
                              isCompact: isCompact,
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      error: (error, stackTrace) => const SizedBox(),
                    ),
                  ],
                ),

                // GLOBAL TABLES
                _CollapsibleNavGroup(
                  label: 'GLOBAL TABLES',
                  persistenceKey: 'global_tables',
                  isCompact: isCompact,
                  hasActiveChild:
                      location == '/admin/letters' ||
                      location == '/admin/numbers' ||
                      location == '/admin/words' ||
                      location == '/admin/sentences' ||
                      location == '/admin/rhymes' ||
                      location == '/admin/quizzes',
                  children: [
                    AdminNavItem(
                      icon: Icons.text_fields_rounded,
                      label: 'Letters Database',
                      isSelected: location == '/admin/letters',
                      onTap: () => _navigate(context, '/admin/letters'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.pin_rounded,
                      label: 'Numbers Database',
                      isSelected: location == '/admin/numbers',
                      onTap: () => _navigate(context, '/admin/numbers'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Words Database',
                      isSelected: location == '/admin/words',
                      onTap: () => _navigate(context, '/admin/words'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.format_quote_rounded,
                      label: 'Sentences Database',
                      isSelected: location == '/admin/sentences',
                      onTap: () => _navigate(context, '/admin/sentences'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.music_note_rounded,
                      label: 'Bakhed & Stories',
                      isSelected: location == '/admin/rhymes',
                      onTap: () => _navigate(context, '/admin/rhymes'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.quiz_rounded,
                      label: 'Quizzes',
                      isSelected: location == '/admin/quizzes',
                      onTap: () => _navigate(context, '/admin/quizzes'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.fact_check_rounded,
                      label: 'Content Review',
                      isSelected: location == '/admin/review',
                      onTap: () => _navigate(context, '/admin/review'),
                      isCompact: isCompact,
                    ),
                  ],
                ),

                // MONETIZATION
                _CollapsibleNavGroup(
                  label: 'MONETIZATION',
                  persistenceKey: 'monetization',
                  isCompact: isCompact,
                  hasActiveChild:
                      location == '/admin/purchases' ||
                      location == '/admin/binti-waitlist',
                  children: [
                    AdminNavItem(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Purchases & Revenue',
                      isSelected: location == '/admin/purchases',
                      onTap: () => _navigate(context, '/admin/purchases'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.event_note_rounded,
                      label: 'Binti Waitlist',
                      isSelected: location == '/admin/binti-waitlist',
                      onTap: () => _navigate(context, '/admin/binti-waitlist'),
                      isCompact: isCompact,
                    ),
                  ],
                ),

                // OPERATIONS
                _CollapsibleNavGroup(
                  label: 'OPERATIONS',
                  persistenceKey: 'operations',
                  isCompact: isCompact,
                  hasActiveChild:
                      location.startsWith('/admin/gamification') ||
                      location == '/admin/analytics' ||
                      location == '/admin/audit-logs' ||
                      location == '/admin/maintenance' ||
                      location == '/admin/settings' ||
                      location == '/admin/access',
                  children: [
                    AdminNavItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Gamification',
                      isSelected: location.startsWith('/admin/gamification'),
                      onTap: () => _navigate(context, '/admin/gamification'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.analytics_rounded,
                      label: 'Analytics',
                      isSelected: location == '/admin/analytics',
                      onTap: () => _navigate(context, '/admin/analytics'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.history_rounded,
                      label: 'Audit Logs',
                      isSelected: location == '/admin/audit-logs',
                      onTap: () => _navigate(context, '/admin/audit-logs'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.health_and_safety_rounded,
                      label: 'Maintenance',
                      isSelected: location == '/admin/maintenance',
                      onTap: () => _navigate(context, '/admin/maintenance'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      isSelected: location == '/admin/settings',
                      onTap: () => _navigate(context, '/admin/settings'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Admin Access',
                      isSelected: location == '/admin/access',
                      onTap: () => _navigate(context, '/admin/access'),
                      isCompact: isCompact,
                    ),
                  ],
                ),

                // MEDIA
                _CollapsibleNavGroup(
                  label: 'MEDIA',
                  persistenceKey: 'media',
                  isCompact: isCompact,
                  hasActiveChild:
                      location == '/admin/media' || location == '/admin/audio',
                  children: [
                    AdminNavItem(
                      icon: Icons.perm_media_rounded,
                      label: 'Media Library',
                      isSelected: location == '/admin/media',
                      onTap: () => _navigate(context, '/admin/media'),
                      isCompact: isCompact,
                    ),
                    AdminNavItem(
                      icon: Icons.audiotrack_rounded,
                      label: 'Audio Files',
                      isSelected: location == '/admin/audio',
                      onTap: () => _navigate(context, '/admin/audio'),
                      isCompact: isCompact,
                    ),
                  ],
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
          onPressed: () => _navigate(context, '/'),
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
              onTap: () => _navigate(context, '/'),
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

class _CollapsibleNavGroup extends ConsumerStatefulWidget {
  final String label;
  final String persistenceKey;
  final bool isCompact;
  final bool hasActiveChild;
  final List<Widget> children;

  const _CollapsibleNavGroup({
    required this.label,
    required this.persistenceKey,
    required this.isCompact,
    this.hasActiveChild = false,
    required this.children,
  });

  @override
  ConsumerState<_CollapsibleNavGroup> createState() =>
      _CollapsibleNavGroupState();
}

class _CollapsibleNavGroupState extends ConsumerState<_CollapsibleNavGroup> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final stored = prefs.getBool(
        'admin_sidebar_group_${widget.persistenceKey}',
      );
      if (stored != null && mounted) {
        setState(() => _isExpanded = stored);
      }
    } catch (_) {}
  }

  Future<void> _toggle() async {
    final next = !_isExpanded;
    setState(() => _isExpanded = next);
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool('admin_sidebar_group_${widget.persistenceKey}', next);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SectionLabel(label: widget.label, isCompact: true),
          ...widget.children,
          const SizedBox(height: 12),
        ],
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivelyExpanded = _isExpanded || widget.hasActiveChild;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: '${widget.label} navigation section',
          button: true,
          expanded: effectivelyExpanded,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.label,
                    style: AdminTokens.eyebrow(isDark).copyWith(
                      fontSize: 10.5,
                      color: AdminTokens.textMuted(isDark),
                      letterSpacing: 1.6,
                    ),
                  ),
                  Icon(
                    effectivelyExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AdminTokens.textMuted(isDark),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (effectivelyExpanded) ...widget.children,
        const SizedBox(height: 12),
      ],
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

    Widget navItem = Padding(
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

    if (widget.isCompact) {
      navItem = Tooltip(
        message: widget.label,
        waitDuration: const Duration(milliseconds: 300),
        child: navItem,
      );
    }

    return Semantics(
      label: widget.label,
      selected: selected,
      button: true,
      child: navItem,
    );
  }
}
