import 'package:flutter/material.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';

/// Configuration for a single column in [AdminDataTable].
class AdminColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;
  final int flex;
  final Comparator<T>? comparator;

  const AdminColumn({
    required this.label,
    required this.cellBuilder,
    this.flex = 1,
    this.comparator,
  });
}

/// Reusable paginated/searchable data table for admin screens.
///
/// Accepts a typed list of items and column definitions. Handles
/// pagination, live-search filtering, and optional column sorting
/// internally so each admin screen only declares its schema.
class AdminDataTable<T> extends StatefulWidget {
  final List<T> items;
  final List<AdminColumn<T>> columns;
  final String searchHint;
  final bool Function(T item, String query) searchPredicate;
  final void Function(T item)? onRowTap;
  final Widget Function(T item)? trailingBuilder;
  final int pageSize;

  const AdminDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.searchPredicate,
    this.searchHint = 'Search…',
    this.onRowTap,
    this.trailingBuilder,
    this.pageSize = 15,
  });

  @override
  State<AdminDataTable<T>> createState() => _AdminDataTableState<T>();
}

class _AdminDataTableState<T> extends State<AdminDataTable<T>> {
  final _searchController = TextEditingController();
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<T> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    final list = query.isEmpty
        ? List<T>.from(widget.items)
        : widget.items
              .where((item) => widget.searchPredicate(item, query))
              .toList();

    if (_sortColumnIndex != null) {
      final comparator = widget.columns[_sortColumnIndex!].comparator;
      if (comparator != null) {
        list.sort(
          _sortAscending ? comparator : (a, b) => comparator(b, a),
        );
      }
    }
    return list;
  }

  int get _totalPages => (_filtered.length / widget.pageSize).ceil().clamp(1, 9999);

  List<T> get _pageItems {
    final start = _currentPage * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  @override
  void didUpdateWidget(covariant AdminDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= _totalPages) {
      _currentPage = (_totalPages - 1).clamp(0, 9999);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildSearchBar(isDark),
        const SizedBox(height: 12),
        _buildHeader(isDark),
        Expanded(
          child: _pageItems.isEmpty
              ? Center(
                  child: Text(
                    'No results found',
                    style: AdminTokens.body(isDark).copyWith(
                      color: AdminTokens.textTertiary(isDark),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _pageItems.length,
                  itemBuilder: (context, index) =>
                      _buildRow(_pageItems[index], isDark),
                ),
        ),
        _buildPagination(isDark),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() => _currentPage = 0),
      style: AdminTokens.bodyStrong(isDark),
      decoration: InputDecoration(
        hintText: widget.searchHint,
        hintStyle: AdminTokens.body(isDark).copyWith(
          color: AdminTokens.textTertiary(isDark),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: AdminTokens.textTertiary(isDark),
          size: 20,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  size: 18,
                  color: AdminTokens.textTertiary(isDark),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _currentPage = 0);
                },
              )
            : null,
        filled: true,
        fillColor: AdminTokens.sunken(isDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          borderSide: BorderSide(color: AdminTokens.border(isDark)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          borderSide: BorderSide(color: AdminTokens.border(isDark)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
          borderSide: const BorderSide(color: AdminTokens.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < widget.columns.length; i++)
            Expanded(
              flex: widget.columns[i].flex,
              child: InkWell(
                onTap: widget.columns[i].comparator != null
                    ? () => setState(() {
                          if (_sortColumnIndex == i) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortColumnIndex = i;
                            _sortAscending = true;
                          }
                        })
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.columns[i].label.toUpperCase(),
                      style: AdminTokens.eyebrow(isDark).copyWith(
                        fontSize: 10.5,
                      ),
                    ),
                    if (_sortColumnIndex == i)
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          if (widget.trailingBuilder != null) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildRow(T item, bool isDark) {
    return InkWell(
      onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AdminTokens.divider(isDark)),
          ),
        ),
        child: Row(
          children: [
            for (final col in widget.columns)
              Expanded(flex: col.flex, child: col.cellBuilder(item)),
            if (widget.trailingBuilder != null) widget.trailingBuilder!(item),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(bool isDark) {
    final total = _filtered.length;
    final start = _currentPage * widget.pageSize + 1;
    final end = (start + widget.pageSize - 1).clamp(1, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        border: Border(top: BorderSide(color: AdminTokens.border(isDark))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            total == 0 ? '0 items' : '$start–$end of $total',
            style: AdminTokens.label(isDark).copyWith(
              color: AdminTokens.textTertiary(isDark),
              fontSize: 12,
              letterSpacing: 0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed:
                    _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                tooltip: 'Previous',
                iconSize: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed:
                    _currentPage < _totalPages - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                tooltip: 'Next',
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
