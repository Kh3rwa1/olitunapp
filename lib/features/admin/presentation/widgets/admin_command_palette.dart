import 'dart:async';
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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _selectedIndex = 0);
    });
  }

  List<CommandItem> _buildIndex() {
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
        title: 'Purchases & Revenue',
        subtitle: 'Course unlocks, revenue KPIs, and refunds',
        category: 'Navigation',
        icon: Icons.shopping_bag_rounded,
        path: '/admin/purchases',
        color: AppColors.duoGreen,
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
        title: 'Daily Affirmations',
        subtitle: 'Curated daily Santali wisdom and sync',
        category: 'Navigation',
        icon: Icons.auto_awesome_rounded,
        path: '/admin/affirmations',
        color: AppColors.duoOrange,
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

    // 2. Dynamic Content from watched providers (reactive updates)
    final lessons = ref.watch(lessonNotifierProvider).valueOrNull ?? [];
    final words = ref.watch(wordsProvider).valueOrNull ?? [];
    final quizzes = ref.watch(quizzesProvider).valueOrNull ?? [];
    final letters = ref.watch(lettersProvider).valueOrNull ?? [];
    final categories = ref.watch(categoryNotifierProvider).valueOrNull ?? [];

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

    return [...staticRoutes, ...dynamicItems];
  }

  List<CommandItem> _rankAndFilter(
    List<CommandItem> allItems,
    String rawQuery,
  ) {
    final query = rawQuery.toLowerCase().trim();
    if (query.isEmpty) {
      return allItems.take(8).toList();
    }

    final scored = <MapEntry<CommandItem, int>>[];

    for (final item in allItems) {
      final title = item.title.toLowerCase();
      final sub = item.subtitle.toLowerCase();
      final cat = item.category.toLowerCase();

      var score = 0;
      if (title == query) {
        score = 100;
      } else if (title.startsWith(query)) {
        score = 80;
      } else if (title.contains(query)) {
        score = 60;
      } else if (cat.startsWith(query)) {
        score = 40;
      } else if (cat.contains(query) || sub.contains(query)) {
        score = 20;
      }

      if (score > 0) {
        scored.add(MapEntry(item, score));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  void _navigate(CommandItem item) {
    Navigator.pop(context);
    context.go(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = _buildIndex();
    _filteredItems = _rankAndFilter(allItems, _searchController.text);

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
                : Colors.white.withValues(alpha: 0.95),
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
                  vertical: 12,
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
                    const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AdminTokens.textPrimary(isDark),
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Search actions, content, or jump to route…',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AdminTokens.textMuted(isDark),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ESC to close',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AdminTokens.textMuted(isDark),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: _filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 32,
                              color: AdminTokens.textMuted(isDark),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No matching results found',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AdminTokens.textMuted(isDark),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = index == _selectedIndex;

                          return Semantics(
                            label:
                                '${item.category}: ${item.title}. ${item.subtitle}',
                            selected: isSelected,
                            button: true,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigate(item),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.06,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.04,
                                                ))
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: item.color.withValues(
                                            alpha: isDark ? 0.15 : 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: item.color,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AdminTokens.textPrimary(
                                                  isDark,
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (item.subtitle.isNotEmpty)
                                              Text(
                                                item.subtitle,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 11,
                                                  color: AdminTokens.textMuted(
                                                    isDark,
                                                  ),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.04,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.03,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          item.category,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: AdminTokens.textSecondary(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.keyboard_return_rounded,
                                          size: 14,
                                          color: AdminTokens.textMuted(isDark),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer Quick Hints
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
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
                    Text(
                      'Navigate with ↑ ↓',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AdminTokens.textMuted(isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select with ↵',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AdminTokens.textMuted(isDark),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredItems.length} matching actions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AdminTokens.textMuted(isDark),
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
