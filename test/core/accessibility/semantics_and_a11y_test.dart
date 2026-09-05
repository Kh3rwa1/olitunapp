import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/accessibility/wcag_audit.dart';
import 'package:itun/features/quiz/presentation/widgets/quiz_option_tile.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/widgets/buttons/animated_buttons.dart';
import 'package:itun/shared/widgets/minimum_tap_target.dart';

void main() {
  group('Accessibility & Semantics Invariants', () {
    testWidgets(
      'CircleIconButton provides >=48dp tap target and button semantics',
      (tester) async {
        final handle = tester.ensureSemantics();
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircleIconButton(
                  icon: Icons.play_arrow,
                  semanticLabel: 'Play Audio',
                  size:
                      32, // configured smaller than 48, but should be bounded to 48dp min touch target
                  onPressed: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(
          find.byType(CircleIconButton),
        );
        expect(
          WcagAudit.hasMinimumTapTarget(renderBox.size),
          isTrue,
          reason:
              'CircleIconButton must satisfy WCAG 48x48dp minimum touch target',
        );

        // Verify semantics
        expect(
          tester.getSemantics(find.byType(CircleIconButton)),
          matchesSemantics(
            isButton: true,
            label: 'Play Audio',
            hasTapAction: true,
          ),
        );

        await tester.tap(find.byType(CircleIconButton));
        expect(tapped, isTrue);
        handle.dispose();
      },
    );

    testWidgets(
      'PrimaryButton provides button semantics and reflects enabled/disabled',
      (tester) async {
        final handle = tester.ensureSemantics();
        try {
          for (final disabled in [false, true]) {
            var taps = 0;
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: PrimaryButton(
                      text: 'Continue Lesson',
                      isDisabled: disabled,
                      onPressed: () => taps++,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(
              tester.getSemantics(find.byType(ElevatedButton)),
              matchesSemantics(
                isButton: true,
                label: 'Continue Lesson',
                hasTapAction: !disabled,
                hasEnabledState: true,
                isEnabled: !disabled,
                isFocusable: !disabled,
                hasFocusAction: !disabled,
              ),
            );

            await tester.tap(find.byType(PrimaryButton), warnIfMissed: false);
            await tester.pumpAndSettle();
            expect(taps, disabled ? 0 : 1);
          }
        } finally {
          handle.dispose();
        }
      },
    );

    testWidgets('DuoButton has focusable tap semantics', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: DuoButton(
                  text: 'Check Answer',
                  onPressed: () => tapped = true,
                ),
              ),
            ),
          ),
        );

        expect(
          tester.getSemantics(find.byType(ElevatedButton)),
          matchesSemantics(
            isButton: true,
            label: 'Check Answer',
            hasTapAction: true,
            hasEnabledState: true,
            isEnabled: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );

        await tester.tap(find.byType(DuoButton));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets(
      'MinimumTapTarget enforces minimum 48x48 dimensions on small widgets',
      (tester) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: MinimumTapTarget(
                  semanticLabel: 'Small icon action',
                  onTap: () {},
                  child: const Icon(Icons.star, size: 16),
                ),
              ),
            ),
          ),
        );

        final renderBox = tester.renderObject<RenderBox>(
          find.byType(MinimumTapTarget),
        );
        expect(renderBox.size.width, greaterThanOrEqualTo(48));
        expect(renderBox.size.height, greaterThanOrEqualTo(48));

        expect(
          tester.getSemantics(find.byType(MinimumTapTarget)),
          matchesSemantics(
            isButton: true,
            label: 'Small icon action',
            hasTapAction: true,
            isFocusable: true,
            hasFocusAction: true,
          ),
        );
        handle.dispose();
      },
    );

    testWidgets(
      'QuizOptionTile announces option index, selection and correct status',
      (tester) async {
        final handle = tester.ensureSemantics();
        final question = QuizQuestion(
          promptOlChiki: 'ᱚ',
          promptLatin: 'LA',
          optionsOlChiki: ['ᱚ', 'ᱛ', 'ᱜ', 'ᱝ'],
          optionsLatin: ['LA', 'AT', 'AG', 'ANG'],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QuizOptionTile(
                index: 0,
                currentQuestion: 0,
                question: question,
                isSelected: true,
                isAnswered: true,
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final semanticsWidget = tester.widget<Semantics>(
          find.byKey(const ValueKey('quiz-option-semantics-0')),
        );
        expect(semanticsWidget.properties.label, contains('Answer A, LA'));
        expect(semanticsWidget.properties.label, contains('selected'));
        expect(semanticsWidget.properties.label, contains('correct'));
        expect(semanticsWidget.properties.selected, isTrue);
        handle.dispose();
      },
    );
  });
}
