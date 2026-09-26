import 'package:flutter/material.dart';

import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class OlChikiLetterPreset {
  final String char;
  final String latin;
  final String exampleWord;
  final int order;

  const OlChikiLetterPreset({
    required this.char,
    required this.latin,
    required this.exampleWord,
    required this.order,
  });

  String get displayChar {
    if (char.runes.any((r) => r == 0x1C78 || r == 0x1C79 || r == 0x1C7A)) {
      return '\u25CC$char';
    }
    return char;
  }
}

const List<OlChikiLetterPreset> kOlChikiPresets = [
  OlChikiLetterPreset(char: 'ᱚ', latin: 'La (a)', exampleWord: 'Ol', order: 0),
  OlChikiLetterPreset(char: 'ᱛ', latin: 'At (t)', exampleWord: 'At', order: 1),
  OlChikiLetterPreset(char: 'ᱜ', latin: 'Ag (g)', exampleWord: 'Ag', order: 2),
  OlChikiLetterPreset(
    char: 'ᱝ',
    latin: 'Ang (ng)',
    exampleWord: 'Ang',
    order: 3,
  ),
  OlChikiLetterPreset(char: 'ᱞ', latin: 'Al (l)', exampleWord: 'Al', order: 4),
  OlChikiLetterPreset(
    char: 'ᱟ',
    latin: 'Laa (aa)',
    exampleWord: 'Aa',
    order: 5,
  ),
  OlChikiLetterPreset(char: 'ᱠ', latin: 'Ak (k)', exampleWord: 'Ka', order: 6),
  OlChikiLetterPreset(char: 'ᱡ', latin: 'Aj (j)', exampleWord: 'Ja', order: 7),
  OlChikiLetterPreset(char: 'ᱢ', latin: 'Am (m)', exampleWord: 'Ma', order: 8),
  OlChikiLetterPreset(char: 'ᱣ', latin: 'Aw (w)', exampleWord: 'Wa', order: 9),
  OlChikiLetterPreset(char: 'ᱤ', latin: 'Li (i)', exampleWord: 'Ir', order: 10),
  OlChikiLetterPreset(char: 'ᱥ', latin: 'Is (s)', exampleWord: 'Si', order: 11),
  OlChikiLetterPreset(char: 'ᱦ', latin: 'Ih (h)', exampleWord: 'Ha', order: 12),
  OlChikiLetterPreset(
    char: 'ᱧ',
    latin: 'Iny (ny)',
    exampleWord: 'Ny',
    order: 13,
  ),
  OlChikiLetterPreset(char: 'ᱨ', latin: 'Ir (r)', exampleWord: 'Ra', order: 14),
  OlChikiLetterPreset(char: 'ᱩ', latin: 'Lu (u)', exampleWord: 'Ul', order: 15),
  OlChikiLetterPreset(char: 'ᱪ', latin: 'Uc (c)', exampleWord: 'Ca', order: 16),
  OlChikiLetterPreset(char: 'ᱫ', latin: 'Ud (d)', exampleWord: 'Da', order: 17),
  OlChikiLetterPreset(
    char: 'ᱬ',
    latin: 'Unn (nn)',
    exampleWord: 'Nn',
    order: 18,
  ),
  OlChikiLetterPreset(char: 'ᱭ', latin: 'Uy (y)', exampleWord: 'Ya', order: 19),
  OlChikiLetterPreset(char: 'ᱮ', latin: 'Le (e)', exampleWord: 'En', order: 20),
  OlChikiLetterPreset(char: 'ᱯ', latin: 'Ep (p)', exampleWord: 'Pa', order: 21),
  OlChikiLetterPreset(
    char: 'ᱰ',
    latin: 'Edd (dd)',
    exampleWord: 'Dd',
    order: 22,
  ),
  OlChikiLetterPreset(char: 'ᱱ', latin: 'En (n)', exampleWord: 'Na', order: 23),
  OlChikiLetterPreset(
    char: 'ᱲ',
    latin: 'Err (rr)',
    exampleWord: 'Rr',
    order: 24,
  ),
  OlChikiLetterPreset(char: 'ᱳ', latin: 'Lo (o)', exampleWord: 'Ol', order: 25),
  OlChikiLetterPreset(
    char: 'ᱴ',
    latin: 'Ott (tt)',
    exampleWord: 'Tt',
    order: 26,
  ),
  OlChikiLetterPreset(
    char: 'ᱵ',
    latin: 'Obb (b)',
    exampleWord: 'Ba',
    order: 27,
  ),
  OlChikiLetterPreset(char: 'ᱶ', latin: 'Ov (v)', exampleWord: 'Va', order: 28),
  OlChikiLetterPreset(char: 'ᱷ', latin: 'Oh (h)', exampleWord: 'Ha', order: 29),
  OlChikiLetterPreset(
    char: 'ᱸ',
    latin: 'Mu Tudag',
    exampleWord: 'ᱦᱮᱸ',
    order: 30,
  ),
  OlChikiLetterPreset(
    char: 'ᱹ',
    latin: 'Gahla Tudag',
    exampleWord: 'ᱟᱹᱛᱩ',
    order: 31,
  ),
  OlChikiLetterPreset(
    char: 'ᱺ',
    latin: 'Mu-Gahla Tudag',
    exampleWord: 'ᱥᱟᱺᱜᱤᱧ',
    order: 32,
  ),
  OlChikiLetterPreset(
    char: 'ᱽ',
    latin: 'Ohod',
    exampleWord: 'ᱢᱟᱹᱡᱷᱤ',
    order: 33,
  ),
  OlChikiLetterPreset(
    char: 'ᱻ',
    latin: 'Ahd (Rela)',
    exampleWord: 'ᱮᱻ',
    order: 34,
  ),
];

class OlChikiQuickPicker extends StatelessWidget {
  final bool isDark;
  final String? selectedChar;
  final void Function(OlChikiLetterPreset preset) onSelect;

  const OlChikiQuickPicker({
    super.key,
    required this.isDark,
    this.selectedChar,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Pick Alphabet Character',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AdminTokens.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              Text(
                'Auto-fills glyph & name',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AdminTokens.textTertiary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kOlChikiPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final preset = kOlChikiPresets[index];
                final isSelected = selectedChar == preset.char;

                return InkWell(
                  borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                  onTap: () => onSelect(preset),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AdminTokens.raised(isDark),
                      borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AdminTokens.border(isDark),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      preset.displayChar,
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : AdminTokens.textPrimary(isDark),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
