import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/admin_tokens.dart';
import '../../../../core/theme/app_colors.dart';
import 'admin_command_item.dart';

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

  void _navigate(CommandItem item) {
    Navigator.pop(context);
    context.go(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = CommandPaletteIndexer.buildIndex(ref);
    _filteredItems = CommandPaletteIndexer.rankAndFilter(
      allItems,
      _searchController.text,
    );

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
