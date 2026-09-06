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
        list.sort(_sortAscending ? comparator : (a, b) => comparator(b, a));
      }
    }
    return list;
  }

  int get _totalPages =>
      (_filtered.length / widget.pageSize).ceil().clamp(1, 9999);

  List<T> get _pageItems {
    final start = _currentPage * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, _filtered.length);
    if (start >= _filtered.length) return [];
    return _filtered.sublist(start, end);
  }

  bool _preferTableView = false;

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final isCardMode = isMobile && !_preferTableView;

        final double minTableWidth = widget.columns.fold<double>(
          widget.trailingBuilder != null ? 60.0 : 0.0,
          (sum, col) => sum + (col.flex * 120.0).clamp(90.0, 320.0),
        );

        Widget contentList;
        if (_pageItems.isEmpty) {
          contentList = Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            child: Text(
              'No results found',
              style: AdminTokens.body(
                isDark,
              ).copyWith(color: AdminTokens.textTertiary(isDark)),
            ),
          );
        } else if (isCardMode) {
          contentList = ListView.builder(
            shrinkWrap: !hasBoundedHeight,
            physics: !hasBoundedHeight
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            itemCount: _pageItems.length,
            itemBuilder: (context, index) =>
                _buildMobileCard(_pageItems[index], isDark),
          );
        } else if (isMobile) {
          // Mobile table view with horizontal scrolling
          contentList = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minTableWidth > constraints.maxWidth
                  ? minTableWidth
                  : constraints.maxWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isDark),
                  if (hasBoundedHeight)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pageItems.length,
                        itemBuilder: (context, index) =>
                            _buildRow(_pageItems[index], isDark),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pageItems.length,
                      itemBuilder: (context, index) =>
                          _buildRow(_pageItems[index], isDark),
                    ),
                ],
              ),
            ),
          );
        } else {
          // Desktop table view
          contentList = ListView.builder(
            shrinkWrap: !hasBoundedHeight,
            physics: !hasBoundedHeight
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            itemCount: _pageItems.length,
            itemBuilder: (context, index) =>
                _buildRow(_pageItems[index], isDark),
          );
        }

        return Column(
          mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSearchBar(isDark, isMobile),
            if (isMobile && isCardMode) ...[
              const SizedBox(height: 8),
              _buildMobileSortChips(isDark),
            ],
            if (!isMobile) ...[
              const SizedBox(height: 12),
              _buildHeader(isDark),
            ],
            const SizedBox(height: 8),
            if (hasBoundedHeight)
              Expanded(child: contentList)
            else
              contentList,
            const SizedBox(height: 8),
            _buildPagination(isDark),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(bool isDark, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _currentPage = 0),
            style: AdminTokens.bodyStrong(isDark),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: AdminTokens.body(
                isDark,
              ).copyWith(color: AdminTokens.textTertiary(isDark)),
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
                      tooltip: 'Clear search',
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
                borderSide:
                    const BorderSide(color: AdminTokens.accent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        if (isMobile) ...[
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AdminTokens.sunken(isDark),
              borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
              border: Border.all(color: AdminTokens.border(isDark)),
            ),
            child: IconButton(
              icon: Icon(
                _preferTableView
                    ? Icons.view_agenda_rounded
                    : Icons.table_rows_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              tooltip: _preferTableView
                  ? 'Switch to Card view'
                  : 'Switch to Horizontal Table view',
              onPressed: () =>
                  setState(() => _preferTableView = !_preferTableView),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileSortChips(bool isDark) {
    final sortableColumns = widget.columns
        .asMap()
        .entries
        .where((e) => e.value.comparator != null)
        .toList();

    if (sortableColumns.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text(
              'SORT:',
              style: AdminTokens.eyebrow(isDark).copyWith(fontSize: 10),
            ),
          ),
          ...sortableColumns.map((entry) {
            final idx = entry.key;
            final col = entry.value;
            final isSelected = _sortColumnIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                avatar: isSelected
                    ? Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
                label: Text(
                  col.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AdminTokens.textSecondary(isDark),
                  ),
                ),
                backgroundColor: isSelected
                    ? AppColors.primary
                    : AdminTokens.sunken(isDark),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AdminTokens.border(isDark),
                ),
                onPressed: () {
                  setState(() {
                    if (_sortColumnIndex == idx) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortColumnIndex = idx;
                      _sortAscending = true;
                    }
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMobileCard(T item, bool isDark) {
    final firstCol = widget.columns.isNotEmpty ? widget.columns.first : null;
    final otherCols =
        widget.columns.length > 1 ? widget.columns.sublist(1) : <AdminColumn<T>>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AdminTokens.raised(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        border: Border.all(color: AdminTokens.border(isDark)),
        boxShadow: AdminTokens.raisedShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AdminTokens.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onRowTap != null ? () => widget.onRowTap!(item) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (firstCol != null)
                      Expanded(child: firstCol.cellBuilder(item)),
                    if (widget.trailingBuilder != null)
                      widget.trailingBuilder!(item),
                  ],
                ),
                if (otherCols.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Divider(height: 1, color: AdminTokens.divider(isDark)),
                  const SizedBox(height: 8),
                  for (final col in otherCols)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              col.label,
                              style: AdminTokens.label(isDark).copyWith(
                                fontSize: 11,
                                color: AdminTokens.textTertiary(isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: col.cellBuilder(item)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
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
                    Flexible(
                      child: Text(
                        widget.columns[i].label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: AdminTokens.eyebrow(
                          isDark,
                        ).copyWith(fontSize: 10.5),
                      ),
                    ),
                    if (_sortColumnIndex == i) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
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
                onPressed: _currentPage > 0
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
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: _currentPage < _totalPages - 1
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
