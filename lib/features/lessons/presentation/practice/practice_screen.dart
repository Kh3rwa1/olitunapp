import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/animations/scale_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/content/letter_model.dart';
import '../../../../shared/models/content/number_model.dart';
import '../../../../shared/providers/providers.dart';
import 'stroke_order_view.dart';
import 'practice_guide.dart';
import 'tracing_view.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  final String letterChar;
  final String letterName;
  final bool startInTrace;

  const PracticeScreen({
    super.key,
    required this.letterChar,
    required this.letterName,
    this.startInTrace = false,
  });

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  late int _selectedIndex;
  bool _hasCompletedPractice = false;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.startInTrace ? 1 : 0;
  }

  void _onPracticeComplete() {
    final practiceChar = normalizePracticeCharacter(widget.letterChar);

    if (!_hasCompletedPractice) {
      _hasCompletedPractice = true;
      ref.read(userStatsProvider.notifier).practiceLetter(practiceChar);
      ref.read(userStatsProvider.notifier).addStars(10);
    }

    if (_isAdvancing) return;
    _isAdvancing = true;
    _advanceAfterCompletion(practiceChar);
  }

  Future<void> _advanceAfterCompletion(String practiceChar) async {
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final target = _nextPracticeTarget(practiceChar);
    if (target != null) {
      final encodedChar = Uri.encodeComponent(target.character);
      final encodedName = Uri.encodeComponent(target.name);
      context.pushReplacement('/practice/$encodedChar/$encodedName?mode=trace');
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  _PracticeTarget? _nextPracticeTarget(String currentChar) {
    final letters = [
      for (final letter
          in ref.read(lettersProvider).valueOrNull ?? const <LetterModel>[])
        if (letter.isActive && letter.charOlChiki.isNotEmpty) letter,
    ]..sort((a, b) => a.order.compareTo(b.order));

    final letterIndex = letters.indexWhere(
      (letter) => normalizePracticeCharacter(letter.charOlChiki) == currentChar,
    );
    if (letterIndex >= 0 && letterIndex < letters.length - 1) {
      final next = letters[letterIndex + 1];
      return _PracticeTarget(
        character: next.charOlChiki,
        name: next.transliterationLatin.isNotEmpty
            ? next.transliterationLatin
            : next.charOlChiki,
      );
    }

    final numbers = [
      for (final number
          in ref.read(numbersProvider).valueOrNull ?? const <NumberModel>[])
        if (number.isActive && number.numeral.isNotEmpty) number,
    ]..sort((a, b) => a.order.compareTo(b.order));

    final numberIndex = numbers.indexWhere(
      (number) => normalizePracticeCharacter(number.numeral) == currentChar,
    );
    if (numberIndex >= 0 && numberIndex < numbers.length - 1) {
      final next = numbers[numberIndex + 1];
      return _PracticeTarget(
        character: next.numeral,
        name: next.nameLatin.isNotEmpty ? next.nameLatin : next.numeral,
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final practiceChar = normalizePracticeCharacter(widget.letterChar);
    final practiceName = widget.letterName.contains('%')
        ? Uri.decodeComponent(widget.letterName)
        : widget.letterName;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF070A12), Color(0xFF101A2B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [Color(0xFFF5FAFF), Color(0xFFEAF4FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    ScaleButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      child: _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Practice • ${_selectedIndex == 0 ? 'Watch' : 'Trace'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : Colors.black54,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            '$practiceName  $practiceChar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: 'OlChiki',
                            ),
                          ),
                        ],
                      ),
                    ),
                    _XpBadge(isDark: isDark),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _SegmentedSwitcher(
                  selectedIndex: _selectedIndex,
                  isDark: isDark,
                  onChanged: (value) {
                    if (value != _selectedIndex) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIndex = value);
                    }
                  },
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.28 : 0.08,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: _selectedIndex == 0
                          ? StrokeOrderView(
                              key: const ValueKey('watch_view'),
                              letterChar: practiceChar,
                            )
                          : TracingView(
                              key: const ValueKey('trace_view'),
                              letterChar: practiceChar,
                              onComplete: _onPracticeComplete,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PracticeTarget {
  final String character;
  final String name;

  const _PracticeTarget({required this.character, required this.name});
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const _GlassIconButton({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black12,
        ),
      ),
      child: Icon(icon, size: 22, color: isDark ? Colors.white : Colors.black),
    );
  }
}

class _XpBadge extends StatelessWidget {
  final bool isDark;

  const _XpBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF41D1FF), Color(0xFF4F5CFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF4F5CFF,
            ).withValues(alpha: isDark ? 0.35 : 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            '+10 XP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedSwitcher extends StatelessWidget {
  final bool isDark;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedSwitcher({
    required this.isDark,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              title: 'Watch & Learn',
              icon: Icons.ondemand_video_rounded,
              active: selectedIndex == 0,
              isDark: isDark,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentButton(
              title: 'Letter Tracing',
              icon: Icons.gesture_rounded,
              active: selectedIndex == 1,
              isDark: isDark,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.title,
    required this.icon,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF6E7DFF), Color(0xFF41D1FF)],
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: active
                  ? Colors.white
                  : (isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
