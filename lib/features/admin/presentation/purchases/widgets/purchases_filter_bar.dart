import 'package:flutter/material.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';

class PurchasesFilterBar extends StatelessWidget {
  final String selectedFilter;
  final TextEditingController searchController;
  final bool isDark;
  final ValueChanged<String> onFilterSelected;
  final ValueChanged<String> onSearchSubmitted;

  const PurchasesFilterBar({
    super.key,
    required this.selectedFilter,
    required this.searchController,
    required this.isDark,
    required this.onFilterSelected,
    required this.onSearchSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'razorpay', 'label': 'Verified Paid'},
      {'key': 'review', 'label': 'Reviews'},
      {'key': 'refunded', 'label': 'Refunded'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 850;

        final chips = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: filters.map((f) {
            final isSelected = selectedFilter == f['key'];
            return ChoiceChip(
              label: Text(f['label']!, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              selectedColor: AppColors.primary.withValues(
                alpha: isDark ? 0.35 : 0.20,
              ),
              onSelected: (selected) {
                if (selected) {
                  onFilterSelected(f['key']!);
                }
              },
            );
          }).toList(),
        );

        final searchField = SizedBox(
          width: isNarrow ? double.infinity : 200,
          child: TextField(
            controller: searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search Category...',
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                borderSide: BorderSide(color: AdminTokens.border(isDark)),
              ),
            ),
            onSubmitted: onSearchSubmitted,
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [chips, const SizedBox(height: 8), searchField],
          );
        }

        return Row(
          children: [
            Expanded(child: chips),
            const SizedBox(width: 16),
            searchField,
          ],
        );
      },
    );
  }
}
