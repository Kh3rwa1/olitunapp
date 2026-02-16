import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared pagination widget for detail screens (letter, number, word)
/// Eliminates code duplication across 3 screens (~120 lines saved)
class DetailPagination extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final Color accentColor;
  final ValueChanged<int> onIndexChanged;
  final List<String>? labels;
  final bool isDark;

  const DetailPagination({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.accentColor,
    required this.onIndexChanged,
    this.labels,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          final isActive = index == currentIndex;
          final label = labels != null && index < labels!.length
              ? labels![index]
              : '${index + 1}';

          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onIndexChanged(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: isActive ? 44 : 36,
              height: isActive ? 44 : 36,
              decoration: BoxDecoration(
                color: isActive
                    ? accentColor
                    : (isDark ? Colors.white10 : Colors.grey[200]),
                borderRadius: BorderRadius.circular(isActive ? 14 : 12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: accentColor.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isActive ? 18 : 14,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
