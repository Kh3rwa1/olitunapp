import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/animations/scale_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/typing_practice_controller.dart';

class OlChikiKeyboard extends ConsumerWidget {
  final TypingPracticeArgs args;

  // Optimized via selective state provider watching (needsDigits select)
  // to completely avoid entire keyboard rebuilds on every single keystroke.
  const OlChikiKeyboard({
    super.key,
    required this.args,
  });

  static const List<String> vowels = ['ᱚ', 'ᱟ', 'ᱤ', 'ᱩ', 'ᱮ', 'ᱳ'];
  static const List<String> consonantsR1 = ['ᱛ', 'ᱜ', 'ᱝ', 'ᱞ', 'ᱠ', 'ᱡ'];
  static const List<String> consonantsR2 = ['ᱢ', 'ᱣ', 'ᱥ', 'ᱦ', 'ᱧ', 'ᱨ'];
  static const List<String> consonantsR3 = ['ᱪ', 'ᱫ', 'ᱬ', 'ᱭ', 'ᱯ', 'ᱰ'];
  static const List<String> consonantsR4 = ['ᱱ', 'ᱲ', 'ᱴ', 'ᱵ', 'ᱶ', 'ᱷ'];
  static const List<String> digits = [
    '0', // ᱐ mapped in _getA11yLabel and dynamic layout
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
  ];

  static const List<String> olChikiDigits = [
    '᱐',
    '᱑',
    '᱒',
    '᱓',
    '᱔',
    '᱕',
    '᱖',
    '᱗',
    '᱘',
    '᱙',
  ];

  String _getA11yLabel(String char) {
    switch (char) {
      // Digits
      case '᱐': return 'Ol Chiki digit zero';
      case '᱑': return 'Ol Chiki digit one';
      case '᱒': return 'Ol Chiki digit two';
      case '᱓': return 'Ol Chiki digit three';
      case '᱔': return 'Ol Chiki digit four';
      case '᱕': return 'Ol Chiki digit five';
      case '᱖': return 'Ol Chiki digit six';
      case '᱗': return 'Ol Chiki digit seven';
      case '᱘': return 'Ol Chiki digit eight';
      case '᱙': return 'Ol Chiki digit nine';
      // Vowels
      case 'ᱚ': return 'Ol Chiki letter LA';
      case 'ᱟ': return 'Ol Chiki letter LAA';
      case 'ᱤ': return 'Ol Chiki letter LI';
      case 'ᱩ': return 'Ol Chiki letter LU';
      case 'ᱮ': return 'Ol Chiki letter LE';
      case 'ᱳ': return 'Ol Chiki letter O';
      // Consonants
      case 'ᱛ': return 'Ol Chiki letter AT';
      case 'ᱜ': return 'Ol Chiki letter AG';
      case 'ᱝ': return 'Ol Chiki letter ANG';
      case 'ᱞ': return 'Ol Chiki letter AL';
      case 'ᱠ': return 'Ol Chiki letter AAK';
      case 'ᱡ': return 'Ol Chiki letter AAJ';
      case 'ᱢ': return 'Ol Chiki letter AAM';
      case 'ᱣ': return 'Ol Chiki letter AAW';
      case 'ᱥ': return 'Ol Chiki letter IS';
      case 'ᱦ': return 'Ol Chiki letter IH';
      case 'ᱧ': return 'Ol Chiki letter INY';
      case 'ᱨ': return 'Ol Chiki letter IR';
      case 'ᱪ': return 'Ol Chiki letter UC';
      case 'ᱫ': return 'Ol Chiki letter UD';
      case 'ᱬ': return 'Ol Chiki letter UNN';
      case 'ᱭ': return 'Ol Chiki letter UY';
      case 'ᱯ': return 'Ol Chiki letter EP';
      case 'ᱰ': return 'Ol Chiki letter ED';
      case 'ᱱ': return 'Ol Chiki letter EN';
      case 'ᱲ': return 'Ol Chiki letter ERR';
      case 'ᱴ': return 'Ol Chiki letter OT';
      case 'ᱵ': return 'Ol Chiki letter OB';
      case 'ᱶ': return 'Ol Chiki letter OV';
      case 'ᱷ': return 'Ol Chiki letter OH';
      // Modifiers & Punctuation
      case 'ᱸ': return 'Ol Chiki MU TTUDDAG';
      case 'ᱹ': return 'Ol Chiki GAAHLAA TTUDAAG';
      case 'ᱺ': return 'Ol Chiki MU-GAAHLAA TTUDAAG';
      case 'ᱻ': return 'Ol Chiki RELAA';
      case 'ᱼ': return 'Ol Chiki PHAARKAA';
      case 'ᱽ': return 'Ol Chiki AHAD';
      case '᱾': return 'Ol Chiki punctuation MUCAAD';
      case '᱿': return 'Ol Chiki punctuation DOUBLE MUCAAD';
      default: return 'Ol Chiki character $char';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final needsDigits = ref.watch(
      typingPracticeControllerProvider(args).select((s) => s.needsDigits),
    );

    final keyboardBg = isDark
        ? Colors.black.withValues(alpha: 0.85)
        : Colors.grey.shade100.withValues(alpha: 0.9);
    final borderCol = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: keyboardBg,
        border: Border(
          top: BorderSide(color: borderCol, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            // Smooth dynamic digit row
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: needsDigits
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _buildKeyRow(context, ref, olChikiDigits, isDigit: true),
                    )
                  : const SizedBox.shrink(),
            ),
            _buildKeyRow(context, ref, vowels),
            const SizedBox(height: 6),
            _buildKeyRow(context, ref, consonantsR1),
            const SizedBox(height: 6),
            _buildKeyRow(context, ref, consonantsR2),
            const SizedBox(height: 6),
            _buildKeyRow(context, ref, consonantsR3),
            const SizedBox(height: 6),
            _buildKeyRow(context, ref, consonantsR4),
            const SizedBox(height: 6),
            _buildActionRow(context, ref),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(
    BuildContext context,
    WidgetRef ref,
    List<String> keys, {
    bool isDigit = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: _buildKeyButton(context, ref, key, isDigit: isDigit),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton(
    BuildContext context,
    WidgetRef ref,
    String char, {
    bool isDigit = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyColor = isDark ? AppColors.charcoal : Colors.white;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final a11yLabel = _getA11yLabel(char);

    return Semantics(
      label: a11yLabel,
      hint: 'Double-tap to type',
      button: true,
      excludeSemantics: true,
      child: ScaleButton(
        onPressed: () {
          ref
              .read(typingPracticeControllerProvider(args).notifier)
              .appendChar(char);
        },
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: keyColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            char,
            style: TextStyle(
              fontFamily: 'OlChiki',
              fontSize: isDigit ? 16 : 21,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final actionTextColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Backspace Key
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Semantics(
                label: 'Backspace',
                hint: 'Double-tap to delete last character',
                button: true,
                excludeSemantics: true,
                child: ScaleButton(
                  onPressed: () {
                    ref
                        .read(typingPracticeControllerProvider(args).notifier)
                        .deleteLastChar();
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: actionColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.backspace_outlined,
                      color: actionTextColor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Space Key
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Semantics(
                label: 'Space',
                hint: 'Double-tap to type space',
                button: true,
                excludeSemantics: true,
                child: ScaleButton(
                  onPressed: () {
                    ref
                        .read(typingPracticeControllerProvider(args).notifier)
                        .appendChar(' ');
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'SPACE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: actionTextColor.withValues(alpha: 0.6),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // । Danda Key
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Semantics(
                label: 'Ol Chiki punctuation MUCAAD',
                hint: 'Double-tap to type punctuation',
                button: true,
                excludeSemantics: true,
                child: ScaleButton(
                  onPressed: () {
                    ref
                        .read(typingPracticeControllerProvider(args).notifier)
                        .appendChar('।');
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '।',
                      style: TextStyle(
                        fontFamily: 'OlChiki',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Done Key
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Semantics(
                label: 'Done',
                hint: 'Double-tap to complete practice',
                button: true,
                excludeSemantics: true,
                child: ScaleButton(
                  onPressed: () {
                    final controller = ref.read(
                      typingPracticeControllerProvider(args).notifier,
                    );
                    final state = ref.read(
                      typingPracticeControllerProvider(args),
                    );
                    if (state.phase == TypingPhase.complete) {
                      controller.markCelebrationDone();
                    } else {
                      FocusScope.of(context).unfocus();
                    }
                  },
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: AppColors.glowShadow(AppColors.primary),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
