import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/lessons/presentation/widgets/category_header_banner_widget.dart';

void main() {
  Future<void> pumpBanner(
    WidgetTester tester, {
    String title = 'Numbers',
    String description = 'Learn to count',
    List<Widget> badges = const [],
    required ValueChanged<String> onAction,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryHeaderBannerWidget(
            title: title,
            description: description,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.purple],
            ),
            iconData: Icons.calculate_rounded,
            onBackPressed: () => onAction('back'),
            badges: badges,
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, description and icon', (tester) async {
    await pumpBanner(tester, onAction: (_) {});

    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('Learn to count'), findsOneWidget);
    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('back button triggers callback', (tester) async {
    final actions = <String>[];
    await pumpBanner(tester, onAction: actions.add);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(actions, ['back']);
  });

  testWidgets('omits description when empty', (tester) async {
    await pumpBanner(tester, description: '', onAction: (_) {});

    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('Learn to count'), findsNothing);
  });

  testWidgets('renders supplied badges', (tester) async {
    await pumpBanner(
      tester,
      onAction: (_) {},
      badges: const [
        Chip(label: Text('4 lessons')),
        Chip(label: Text('Beginner')),
      ],
    );

    expect(find.text('4 lessons'), findsOneWidget);
    expect(find.text('Beginner'), findsOneWidget);
  });
}
