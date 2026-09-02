import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/lessons/widgets/lesson_filter_chip.dart';

void main() {
  Future<void> pumpChip(
    WidgetTester tester, {
    required String label,
    required bool isSelected,
    required bool isDark,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LessonFilterChip(
              label: label,
              isSelected: isSelected,
              onTap: onTap ?? () {},
              isDark: isDark,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders its label and fires onTap when tapped', (tester) async {
    var tapped = false;
    await pumpChip(
      tester,
      label: 'Published',
      isSelected: false,
      isDark: false,
      onTap: () => tapped = true,
    );

    expect(find.text('Published'), findsOneWidget);
    await tester.tap(find.text('Published'));
    expect(tapped, isTrue);
  });

  testWidgets('selected chip uses bolder typography than unselected', (
    tester,
  ) async {
    await pumpChip(tester, label: 'All', isSelected: true, isDark: false);
    final selected = tester.widget<Text>(find.text('All'));
    expect(selected.style?.fontWeight, FontWeight.w700);
    expect(selected.style?.color, Colors.white);

    await pumpChip(tester, label: 'All', isSelected: false, isDark: false);
    final unselected = tester.widget<Text>(find.text('All'));
    expect(unselected.style?.fontWeight, FontWeight.w600);
    expect(unselected.style?.color, Colors.black87);
  });

  testWidgets('dark unselected chip uses light text color', (tester) async {
    await pumpChip(tester, label: 'Hidden', isSelected: false, isDark: true);
    final text = tester.widget<Text>(find.text('Hidden'));
    expect(text.style?.color, Colors.white70);
  });
}
