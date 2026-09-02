import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/empty_content_placeholder.dart';

void main() {
  Widget wrap(Widget child, [Brightness brightness = Brightness.light]) {
    return MaterialApp(
      theme: brightness == Brightness.light
          ? ThemeData.light()
          : ThemeData.dark(),
      home: Scaffold(body: child),
    );
  }

  group('EmptyContentPlaceholder', () {
    testWidgets('renders inbox icon and message in light mode', (tester) async {
      await tester.pumpWidget(
        wrap(
          const EmptyContentPlaceholder(
            message: 'No items in this lesson.',
            isDark: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
      expect(find.text('No items in this lesson.'), findsOneWidget);
    });

    testWidgets('renders message in dark mode', (tester) async {
      await tester.pumpWidget(
        wrap(
          const EmptyContentPlaceholder(
            message: 'Nothing here yet',
            isDark: true,
          ),
          Brightness.dark,
        ),
      );

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_rounded), findsOneWidget);
    });

    testWidgets('is full width and centered', (tester) async {
      await tester.pumpWidget(
        wrap(const EmptyContentPlaceholder(message: 'Empty', isDark: false)),
      );

      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(EmptyContentPlaceholder),
              matching: find.byType(Container),
            )
            .first,
      );
      expect(container.constraints?.maxWidth, double.infinity);
    });
  });
}
