import 'dart:async';
import 'package:flutter/material.dart';

import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';

class ContentFilterBar extends StatefulWidget {
  final String title;
  final bool isDark;
  final bool supportsCategory;
  final bool supportsPublished;
  final bool supportsPremium;
  final List<CategoryEntity> categories;
  final String? selectedCategoryId;
  final String publishFilter;
  final String premiumFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onPublishFilterChanged;
  final ValueChanged<String> onPremiumFilterChanged;

  const ContentFilterBar({
    super.key,
    required this.title,
    required this.isDark,
    required this.supportsCategory,
    required this.supportsPublished,
    required this.supportsPremium,
    required this.categories,
    required this.selectedCategoryId,
    required this.publishFilter,
    required this.premiumFilter,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onPublishFilterChanged,
    required this.onPremiumFilterChanged,
  });

  @override
  State<ContentFilterBar> createState() => _ContentFilterBarState();
}

class _ContentFilterBarState extends State<ContentFilterBar> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchInput(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                onChanged: _onSearchInput,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${widget.title}...',
                  hintStyle: TextStyle(
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: widget.isDark ? Colors.white30 : Colors.black26,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (widget.supportsPublished) ...[
              const SizedBox(width: 12),
              _buildDropdown(
                value: widget.publishFilter,
                items: const ['All', 'Published', 'Draft'],
                onChanged: (v) {
                  if (v != null) widget.onPublishFilterChanged(v);
                },
                isDark: widget.isDark,
              ),
            ],
            if (widget.supportsPremium) ...[
              const SizedBox(width: 8),
              _buildDropdown(
                value: widget.premiumFilter,
                items: const ['All', 'Premium', 'Free'],
                onChanged: (v) {
                  if (v != null) widget.onPremiumFilterChanged(v);
                },
                isDark: widget.isDark,
              ),
            ],
          ],
        ),
        if (widget.supportsCategory && widget.categories.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Categories',
                  isSelected: widget.selectedCategoryId == null,
                  onTap: () => widget.onCategoryChanged(null),
                  isDark: widget.isDark,
                ),
                ...widget.categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _buildFilterChip(
                      label: cat.titleLatin,
                      isSelected: widget.selectedCategoryId == cat.id,
                      onTap: () => widget.onCategoryChanged(cat.id),
                      isDark: widget.isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Semantics(
      label: 'Dropdown filter for $value',
      button: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            onChanged: onChanged,
            items: items.map((String val) {
              return DropdownMenuItem<String>(value: val, child: Text(val));
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Semantics(
      label: 'Category chip: $label',
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
