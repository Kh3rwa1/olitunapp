import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/theme/app_colors.dart';
import 'package:itun/shared/widgets/eyebrow.dart';

void main() {
  testWidgets('Eyebrow upper-cases and uses the muted style', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Eyebrow('Word of the day'))),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'WORD OF THE DAY');
    expect(text.style?.fontSize, 11);
    expect(text.style?.letterSpacing, 1.2);
    expect(text.style?.color, AppColors.webSlate);
  });

  testWidgets('Eyebrow can keep case and take a colour', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Eyebrow('Santali', uppercase: false, color: AppColors.primary),
        ),
      ),
    );
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.data, 'Santali');
    expect(text.style?.color, AppColors.primary);
  });
}
