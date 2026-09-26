import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/providers.dart';

/// Represents a single navigable or actionable command in the Admin Command Palette.
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

/// Helper for indexing and searching command palette actions.
class CommandPaletteIndexer {
  /// Builds the combined list of static routes and dynamic items from providers.
  static List<CommandItem> buildIndex(WidgetRef ref) {
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
        color: AppColors.accentGold,
      ),
      CommandItem(
        title: 'Purchases & Revenue',
        subtitle: 'Course unlocks, revenue KPIs, and refunds',
        category: 'Navigation',
        icon: Icons.shopping_bag_rounded,
        path: '/admin/purchases',
        color: AppColors.accentForest,
      ),
      CommandItem(
        title: 'Platform Analytics',
        subtitle: 'Deep-dive user trends and course engagement',
        category: 'Navigation',
        icon: Icons.analytics_rounded,
        path: '/admin/analytics',
        color: AppColors.brandBlue,
      ),
      CommandItem(
        title: 'Maintenance Controls',
        subtitle: 'Seeding, cache invalidation, DB backups',
        category: 'Navigation',
        icon: Icons.build_rounded,
        path: '/admin/maintenance',
        color: AppColors.accentOchre,
      ),
      CommandItem(
        title: '35 Alphabets Database',
        subtitle:
            'Manage all 35 Ol Chiki letters, pronunciations, audio, and tracing',
        category: 'Navigation',
        icon: Icons.abc_rounded,
        path: '/admin/letters',
        color: AppColors.accentOchre,
      ),
      CommandItem(
        title: 'Access Management',
        subtitle: 'Role assignments, invites, user logs',
        category: 'Navigation',
        icon: Icons.vpn_key_rounded,
        path: '/admin/access',
        color: AppColors.accentPurple,
      ),
    ];

    // 2. Dynamic Content from watched providers (reactive updates)
    final lessons = ref.watch(lessonNotifierProvider).valueOrNull ?? [];
    final words = ref.watch(wordsProvider).valueOrNull ?? [];
    final quizzes = ref.watch(quizzesProvider).valueOrNull ?? [];
    final letterItems =
        ref
            .watch(contentListProvider((ContentKind.letter, null)))
            .valueOrNull ??
        [];
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
          color: AppColors.accentForest,
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
          color: AppColors.brandBlue,
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
          color: AppColors.accentGold,
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
          color: AppColors.accentPurple,
        ),
      );
    }

    if (letterItems.isNotEmpty) {
      for (final item in letterItems) {
        final glyph = item.olChiki ?? item.titleOlChiki ?? '';
        final title = glyph.isNotEmpty ? '$glyph [${item.title}]' : item.title;
        final example = item.subtitle != null && item.subtitle!.isNotEmpty
            ? 'Example: ${item.subtitle}'
            : '35 Alphabet Character';
        dynamicItems.add(
          CommandItem(
            title: title,
            subtitle: example,
            category: 'Alphabet',
            icon: Icons.abc_rounded,
            path: '/admin/letters',
            color: AppColors.accentOchre,
          ),
        );
      }
    } else {
      for (final letter in letters) {
        dynamicItems.add(
          CommandItem(
            title: '${letter.charOlChiki} [${letter.transliterationLatin}]',
            subtitle: letter.exampleWordLatin != null
                ? 'Example: ${letter.exampleWordOlChiki} (${letter.exampleWordLatin})'
                : 'Alphabet Letter',
            category: 'Alphabet',
            icon: Icons.abc_rounded,
            path: '/admin/letters',
            color: AppColors.accentOchre,
          ),
        );
      }
    }

    return [...staticRoutes, ...dynamicItems];
  }

  /// Filters and ranks command items by relevance score for the given query.
  static List<CommandItem> rankAndFilter(
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
}
