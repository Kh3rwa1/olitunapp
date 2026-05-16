import 'package:flutter/material.dart';
import '../../../../../../core/theme/admin_tokens.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../widgets/admin_form_widgets.dart';

class McqOptionEditor extends StatelessWidget {
  final bool isDark;
  final int correctIndex;
  final ValueChanged<int> onCorrectIndexChanged;
  final List<TextEditingController> optOlChikiCtrls;
  final List<TextEditingController> optLatinCtrls;

  const McqOptionEditor({
    super.key,
    required this.isDark,
    required this.correctIndex,
    required this.onCorrectIndexChanged,
    required this.optOlChikiCtrls,
    required this.optLatinCtrls,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options (4 choices)', style: AdminTokens.label(isDark)),
        const SizedBox(height: 10),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => onCorrectIndexChanged(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      correctIndex == i
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: correctIndex == i
                          ? AppColors.primary
                          : AdminTokens.border(isDark),
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: optOlChikiCtrls[i],
                    decoration: InputDecoration(
                      hintText: 'Option ${i + 1} (Ol Chiki)',
                      filled: true,
                      fillColor: AdminTokens.sunken(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: correctIndex == i
                              ? AppColors.primary
                              : AdminTokens.border(isDark),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style:
                        AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: optLatinCtrls[i],
                    decoration: InputDecoration(
                      hintText: 'Option ${i + 1} (Latin)',
                      filled: true,
                      fillColor: AdminTokens.sunken(isDark),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: correctIndex == i
                              ? AppColors.primary
                              : AdminTokens.border(isDark),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style:
                        AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
        Text(
          '● Radio = correct answer',
          style: TextStyle(
            fontSize: 11,
            color: AdminTokens.textTertiary(isDark),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class FillBlankOptionEditor extends StatelessWidget {
  final bool isDark;
  final TextEditingController blankOlChiki;
  final TextEditingController blankLatin;
  final TextEditingController correctAnswer;
  final List<TextEditingController> distractorCtrls;

  const FillBlankOptionEditor({
    super.key,
    required this.isDark,
    required this.blankOlChiki,
    required this.blankLatin,
    required this.correctAnswer,
    required this.distractorCtrls,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.2),
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Use ___ (three underscores) as the blank placeholder',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminTextField(
          controller: blankOlChiki,
          label: 'Sentence with blank (Ol Chiki)',
          hint: 'e.g., ᱤᱧ ᱫᱚ ___ ᱠᱟᱱᱟ',
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        AdminTextField(
          controller: blankLatin,
          label: 'Sentence with blank (Latin)',
          hint: 'e.g., Ing do ___ kana',
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        AdminTextField(
          controller: correctAnswer,
          label: 'Correct Answer',
          hint: 'The word that fills the blank',
          prefixIcon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: 14),
        Text('Distractors (wrong choices)', style: AdminTokens.label(isDark)),
        const SizedBox(height: 8),
        ...List.generate(
          3,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: distractorCtrls[i],
              decoration: InputDecoration(
                hintText: 'Wrong option ${i + 1}',
                filled: true,
                fillColor: AdminTokens.sunken(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AdminTokens.border(isDark)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: AdminTokens.bodyStrong(isDark).copyWith(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}
