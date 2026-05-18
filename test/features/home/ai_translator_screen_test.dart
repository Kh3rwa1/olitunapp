import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/home/presentation/screens/ai_translator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';
import '../../test_utils.dart';

void main() {
  testWidgets('AiTranslatorScreen renders correctly without exceptions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      createTestableWidget(
        child: const AiTranslatorScreen(),
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AI Translator'), findsOneWidget);
    expect(find.text('Speak With\nConfidence'), findsOneWidget);
    expect(find.text('TRANSLATE MAGIC'), findsOneWidget);
  });
}
