import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itun/core/theme/app_theme.dart';
import 'package:itun/shared/widgets/animated_buttons.dart';

void main() {
  testWidgets('PrimaryButton golden — light theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(PrimaryButton),
      matchesGoldenFile('goldens/primary_button_light.png'),
    );
  });

  testWidgets('PrimaryButton golden — dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(PrimaryButton),
      matchesGoldenFile('goldens/primary_button_dark.png'),
    );
  });
}
