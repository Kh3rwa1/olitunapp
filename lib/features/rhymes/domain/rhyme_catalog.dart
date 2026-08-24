import 'rhyme_category_model.dart';
import 'rhyme_model.dart';

/// Result of splitting a filtered catalogue into the featured hero and the
/// remaining grid items.
class FeaturedSelection {
  final RhymeModel? featured;
  final List<RhymeModel> grid;

  const FeaturedSelection({required this.featured, required this.grid});
}

/// Pure catalogue logic for the Bakhed screen: category collection,
/// filtering, and featured selection. Kept Flutter-free for unit testing.
class RhymeCatalog {
  RhymeCatalog._();

  /// Normalised category key: trimmed + lowercased. Used for dedup and
  /// matching so free-text CMS entries like "Sohrai" / "sohrai " collapse
  /// into one chip.
  static String? normalizeCategory(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim().toLowerCase();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Builds the filter-chip list from the catalogue. Deduplication is
  /// case-insensitive; the display name preserves the first-seen casing.
  static List<RhymeCategoryModel> collectCategories(List<RhymeModel> rhymes) {
    final seen = <String, RhymeCategoryModel>{};
    var order = 0;
    for (final rhyme in rhymes) {
      final key = normalizeCategory(rhyme.category);
      if (key == null || seen.containsKey(key)) continue;
      seen[key] = RhymeCategoryModel(
        id: key,
        nameOlChiki: rhyme.category!,
        nameLatin: rhyme.category!.trim(),
        iconName: 'auto_awesome',
        order: order++,
      );
    }
    return seen.values.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Applies category and tag filters. Category matching is
  /// case-insensitive on both id and display name.
  static List<RhymeModel> filterRhymes(
    List<RhymeModel> rhymes, {
    String? categoryId,
    String? categoryName,
    String? tag,
  }) {
    var filtered = rhymes;
    if (categoryId != null || categoryName != null) {
      final idKey = normalizeCategory(categoryId);
      final nameKey = normalizeCategory(categoryName);
      filtered = filtered
          .where(
            (r) =>
                normalizeCategory(r.categoryId) == idKey && idKey != null ||
                normalizeCategory(r.category) == idKey && idKey != null ||
                normalizeCategory(r.category) == nameKey && nameKey != null,
          )
          .toList();
    }
    if (tag != null) {
      filtered = filtered.where((r) => r.tags.contains(tag)).toList();
    }
    return filtered;
  }

  /// Splits [filtered] into the featured hero and grid items.
  ///
  /// The first entry flagged `isFeatured` wins; otherwise the first item.
  /// The featured item is always excluded from the grid.
  static FeaturedSelection selectFeatured(List<RhymeModel> filtered) {
    if (filtered.isEmpty) {
      return const FeaturedSelection(featured: null, grid: []);
    }
    final featuredIndex = filtered.indexWhere((r) => r.isFeatured);
    final index = featuredIndex >= 0 ? featuredIndex : 0;
    return FeaturedSelection(
      featured: filtered[index],
      grid: [...filtered.sublist(0, index), ...filtered.sublist(index + 1)],
    );
  }
}
