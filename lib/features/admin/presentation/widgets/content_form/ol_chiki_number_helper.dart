import 'package:flutter/material.dart';

import 'package:itun/core/theme/admin_tokens.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/utils/santali_numbers.dart';

/// Quick preset helper and auto-fill toolbar for the 100 Numbers admin form.
class OlChikiNumberHelper extends StatelessWidget {
  final bool isDark;
  final TextEditingController titleController;
  final TextEditingController titleOlChikiController;
  final TextEditingController subtitleController;
  final TextEditingController olChikiController;
  final TextEditingController orderController;

  const OlChikiNumberHelper({
    super.key,
    required this.isDark,
    required this.titleController,
    required this.titleOlChikiController,
    required this.subtitleController,
    required this.olChikiController,
    required this.orderController,
  });

  static const List<int> _quickPresets = [0, 1, 5, 10, 20, 21, 25, 30, 50, 100];

  void _applyNumber(int value) {
    if (value < 0 || value > SantaliNumbers.maxValue) return;
    orderController.text = value.toString();
    olChikiController.text = SantaliNumbers.toOlChikiNumeral(value);
    titleController.text = SantaliNumbers.nameLatin(value);
    titleOlChikiController.text = SantaliNumbers.nameOlChiki(value);
    subtitleController.text = SantaliNumbers.englishName(value);
  }

  void _autoFillFromCurrent() {
    int? resolved;
    final orderText = orderController.text.trim();
    if (orderText.isNotEmpty) {
      resolved = int.tryParse(orderText);
    }
    if (resolved == null ||
        resolved < 0 ||
        resolved > SantaliNumbers.maxValue) {
      resolved = SantaliNumbers.tryParseValue(
        olChikiController.text,
        titleController.text,
      );
    }
    if (resolved != null &&
        resolved >= 0 &&
        resolved <= SantaliNumbers.maxValue) {
      _applyNumber(resolved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_fix_high_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '100 Numbers Auto-Fill & Quick Select',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: _autoFillFromCurrent,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 14),
                label: const Text(
                  'Auto-Fill From Value',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickPresets.map((val) {
                final numeral = SantaliNumbers.toOlChikiNumeral(val);
                final latin = SantaliNumbers.nameLatin(val);
                final isCurrent = orderController.text.trim() == val.toString();
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(
                      '$val ($numeral - $latin)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent ? Colors.white : null,
                      ),
                    ),
                    backgroundColor: isCurrent
                        ? AppColors.primary
                        : AdminTokens.raised(isDark),
                    onPressed: () => _applyNumber(val),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
