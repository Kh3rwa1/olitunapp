import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';

class CommandItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final String path;
  final Color color;

  CommandItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.path,
    required this.color,
  });
}

class AdminCommandPalette extends ConsumerStatefulWidget {
  const AdminCommandPalette({super.key});

  @override
  ConsumerState<AdminCommandPalette> createState() =>
      _AdminCommandPaletteState();
}

class _AdminCommandPaletteState extends ConsumerState<AdminCommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<CommandItem> _filteredItems = [];
  List<CommandItem> _allItems = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _buildIndex();
    _filterItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _buildIndex() {
    // 1. Static Navigation Routes
    final staticRoutes = [
      CommandItem(
        title: 'Dashboard Cockpit',
        subtitle: 'Main metrics, activity logs, and status',
        category: 'Navigation',
        icon: Icons.dashboard_customize_rounded,
        path: '/admin',
        color: AppColors.primary,
      ),
      CommandItem(
        title: 'App Settings',
        subtitle: 'Payment gateways, system states, collection syncs',
        category: 'Navigation',
        icon: Icons.settings_rounded,
        path: '/admin/settings',
        color: AppColors.duoYellow,
      ),
      CommandItem(
        title: 'Platform Analytics',
        subtitle: 'Deep-dive user trends and course engagement',
        category: 'Navigation',
        icon: Icons.analytics_rounded,
        path: '/admin/analytics',
        color: AppColors.duoBlue,
      ),
      CommandItem(
        title: 'Maintenance Controls',
        subtitle: 'Seeding, cache invalidation, DB backups',
        category: 'Navigation',
        icon: Icons.build_rounded,
        path: '/admin/maintenance',
        color: AppColors.duoOrange,
      ),
      CommandItem(
        title: 'Access Management',
        subtitle: 'Role assignments, invites, user logs',
        category: 'Navigation',
        icon: Icons.vpn_key_rounded,
        path: '/admin/access',
        color: AppColors.duoPurple,
      ),
    ];

    // 2. Dynamic Content from providers
    final lessons = ref.read(lessonNotifierProvider).valueOrNull ?? [];
    final words = ref.read(wordsProvider).valueOrNull ?? [];
    final quizzes = ref.read(quizzesProvider).valueOrNull ?? [];
    final letters = ref.read(lettersProvider).valueOrNull ?? [];
    final categories = ref.read(categoryNotifierProvider).valueOrNull ?? [];

    final dynamicItems = <CommandItem>[];

    for (final cat in categories) {
      dynamicItems.add(
        CommandItem(
          title: cat.titleLatin,
          subtitle: cat.description ?? 'Curriculum Category',
          category: 'Category',
          icon: Icons.category_rounded,
          path: '/admin/categories',
          color: AppColors.duoGreen,
        ),
      );
    }

    for (final lesson in lessons) {
      dynamicItems.add(
        CommandItem(
          title: lesson.titleLatin,
          subtitle: lesson.description ?? '',
          category: 'Lesson',
          icon: Icons.school_rounded,
          path: '/admin/lessons/content/${lesson.id}',
          color: AppColors.duoBlue,
        ),
      );
    }

    for (final word in words) {
      dynamicItems.add(
        CommandItem(
          title: '${word.wordOlChiki} (${word.wordLatin})',
          subtitle: word.meaning,
          category: 'Vocabulary',
          icon: Icons.menu_book_rounded,
          path: '/admin/words',
          color: AppColors.duoYellow,
        ),
      );
    }

    for (final quiz in quizzes) {
      dynamicItems.add(
        CommandItem(
          title: quiz.title ?? 'Quiz Level: ${quiz.level.toUpperCase()}',
          subtitle:
              '${quiz.questions.length} Questions - Pass score ${quiz.passingScore}%',
          category: 'Quiz',
          icon: Icons.quiz_rounded,
          path: '/admin/quizzes',
          color: AppColors.duoPurple,
        ),
      );
    }

    for (final letter in letters) {
      dynamicItems.add(
        CommandItem(
          title: '${letter.charOlChiki} [${letter.transliterationLatin}]',
          subtitle: letter.exampleWordLatin != null
              ? 'Example: ${letter.exampleWordOlChiki} (${letter.exampleWordLatin})'
              : 'Alphabet Letter',
          category: 'Alphabet',
          icon: Icons.text_fields_rounded,
          path: '/admin/letters',
          color: AppColors.duoOrange,
        ),
      );
    }

    _allItems = [...staticRoutes, ...dynamicItems];
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems.take(8).toList(); // Quick dashboard default
      } else {
        _filteredItems = _allItems.where((item) {
          return item.title.toLowerCase().contains(query) ||
              item.subtitle.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query);
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _navigate(CommandItem item) {
    Navigator.pop(context);
    context.go(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            setState(() {
              if (_filteredItems.isNotEmpty) {
                _selectedIndex = (_selectedIndex + 1) % _filteredItems.length;
              }
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            setState(() {
              if (_filteredItems.isNotEmpty) {
                _selectedIndex =
                    (_selectedIndex - 1 + _filteredItems.length) %
                    _filteredItems.length;
              }
            });
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.enter) {
            if (_filteredItems.isNotEmpty &&
                _selectedIndex < _filteredItems.length) {
              _navigate(_filteredItems[_selectedIndex]);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Center(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 460),
          margin: const EdgeInsets.only(top: 80),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xE00F1524)
                : Colors.white.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 50,
                offset: const Offset(0, 20),
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Input Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: AdminTokens.textTertiary(isDark),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        onChanged: (_) => _filterItems(),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AdminTokens.textPrimary(isDark),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search course content or type a command...',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AdminTokens.textMuted(isDark),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AdminTokens.border(isDark)),
                        ),
                        child: Text(
                          'ESC',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AdminTokens.textTertiary(isDark),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Results Area
              Flexible(
                child: _filteredItems.isEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: AdminTokens.textMuted(isDark),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No matching commands or content found',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AdminTokens.textSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () => _navigate(item),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AdminTokens.accent.withValues(
                                        alpha: isDark ? 0.12 : 0.08,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AdminTokens.accent.withValues(
                                          alpha: 0.28,
                                        )
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? item.color
                                          : item.color.withValues(
                                              alpha: isDark ? 0.15 : 0.10,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      item.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : item.color,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AdminTokens.textPrimary(
                                              isDark,
                                            ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.subtitle,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? AdminTokens.textSecondary(
                                                    isDark,
                                                  )
                                                : AdminTokens.textMuted(isDark),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                        color: AdminTokens.textSecondary(
                                          isDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Footer shortcut row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.01)
                      : Colors.black.withValues(alpha: 0.01),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Navigate',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AdminTokens.textMuted(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.keyboard_return_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Select',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AdminTokens.textMuted(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
