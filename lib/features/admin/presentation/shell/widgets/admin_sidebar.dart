import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                _SectionLabel(label: 'OVERVIEW', isCompact: isCompact),
                AdminNavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  isSelected: location == '/admin',
                  onTap: () => _navigate(context, '/admin'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'CONTENT', isCompact: isCompact),
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

                        final isStandard = const {
                          'cat_vocab',
                          'cat_words',
                          'seed_words',
                          'cat_sentences',
                          'seed_sentences',
                          'cat_alphabets',
                          'cat_letters',
                          'letters',
                          'cat_numbers',
                        }.contains(id);

                        String route;
                        IconData icon;

                        if (isStandard) {
                          if (id == 'cat_vocab' ||
                              id == 'cat_words' ||
                              id == 'seed_words') {
                            route = '/admin/words?categoryId=$id';
                            icon = Icons.menu_book_rounded;
                          } else if (id == 'cat_sentences' ||
                              id == 'seed_sentences') {
                            route = '/admin/sentences?categoryId=$id';
                            icon = Icons.format_quote_rounded;
                          } else if (id == 'cat_alphabets' ||
                              id == 'cat_letters' ||
                              id == 'letters') {
                            route = '/admin/letters?categoryId=$id';
                            icon = Icons.text_fields_rounded;
                          } else {
                            route = '/admin/numbers?categoryId=$id';
                            icon = Icons.pin_rounded;
                          }
                        } else {
                          // Custom categories ALWAYS route to their dedicated subcategories screen
                          route = '/admin/lessons?categoryId=$id';
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
                        }

                        final targetUri = Uri.parse(route);
                        final currentUri = GoRouterState.of(context).uri;

                        bool isSelected = currentUri.path == targetUri.path;
                        if (isSelected) {
                          final currentId =
                              currentUri.queryParameters['categoryId'];
                          final targetId =
                              targetUri.queryParameters['categoryId'];
                          if (currentId != targetId) {
                            final isDefaultWord =
                                targetUri.path == '/admin/words' &&
                                (targetId == 'cat_vocab' ||
                                    targetId == 'cat_words' ||
                                    targetId == 'seed_words') &&
                                currentId == null;
                            final isDefaultSentence =
                                targetUri.path == '/admin/sentences' &&
                                (targetId == 'cat_sentences' ||
                                    targetId == 'seed_sentences') &&
                                currentId == null;
                            final isDefaultLetter =
                                targetUri.path == '/admin/letters' &&
                                (targetId == 'cat_alphabets' ||
                                    targetId == 'cat_letters' ||
                                    targetId == 'letters') &&
                                currentId == null;
                            final isDefaultNumber =
                                targetUri.path == '/admin/numbers' &&
                                targetId == 'cat_numbers' &&
                                currentId == null;

                            isSelected =
                                isDefaultWord ||
                                isDefaultSentence ||
                                isDefaultLetter ||
                                isDefaultNumber;
                          }
                        }

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

                AdminNavItem(
                  icon: Icons.music_note_rounded,
                  label: 'Bakhed & Stories',
                  isSelected: location == '/admin/rhymes',
                  onTap: () => _navigate(context, '/admin/rhymes'),
                  isCompact: isCompact,
                ),
                AdminNavItem(
                  icon: Icons.library_books_rounded,
                  label: 'Bakhed Learning CMS',
                  isSelected: location.startsWith('/admin/gamification/bakhed'),
                  onTap: () =>
                      _navigate(context, '/admin/gamification/bakhed/lyrics'),
                  isCompact: isCompact,
                  indent: !isCompact,
                ),
                AdminNavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Quizzes',
                  isSelected: location == '/admin/quizzes',
                  onTap: () => _navigate(context, '/admin/quizzes'),
                  isCompact: isCompact,
                ),
                const SizedBox(height: 18),
                _SectionLabel(label: 'MONETIZATION', isCompact: isCompact),
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
                const SizedBox(height: 18),
                _SectionLabel(label: 'OPERATIONS', isCompact: isCompact),
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
                const SizedBox(height: 18),
                _SectionLabel(label: 'MEDIA', isCompact: isCompact),
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
