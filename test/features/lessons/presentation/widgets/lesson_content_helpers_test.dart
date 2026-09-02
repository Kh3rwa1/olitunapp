import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/lesson_content_helpers.dart';

void main() {
  Future<double> pumpAndReadCount(WidgetTester tester, Size size) async {
    double result = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: size),
        child: Builder(
          builder: (context) {
            result = getResponsiveCrossAxisCount(context).toDouble();
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return result;
  }

  group('getResponsiveCrossAxisCount', () {
    testWidgets('returns 2 columns on narrow phone widths', (tester) async {
      final result = await pumpAndReadCount(tester, const Size(400, 800));
      expect(result, 2);
    });

    testWidgets('returns 3 columns between 600 and 800', (tester) async {
      final result = await pumpAndReadCount(tester, const Size(700, 900));
      expect(result, 3);
    });

    testWidgets('returns 4 columns between 800 and 1200', (tester) async {
      final result = await pumpAndReadCount(tester, const Size(1000, 900));
      expect(result, 4);
    });

    testWidgets('returns 6 columns above 1200', (tester) async {
      final result = await pumpAndReadCount(tester, const Size(1400, 900));
      expect(result, 6);
    });
  });

  group('contentCardDecoration', () {
    test('adapts surface color to dark mode', () {
      final light = contentCardDecoration(false);
      final dark = contentCardDecoration(true);
      expect(light.color, Colors.white);
      expect(dark.color, isNot(Colors.white));
      expect(light.borderRadius, BorderRadius.circular(20));
    });
  });

  group('ContentNavArrow', () {
    testWidgets('renders a forward arrow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContentNavArrow())),
      );
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
    });
  });
}
