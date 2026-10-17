import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/home/presentation/screens/ai_translator_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/device_matrix.dart';
import '../test_utils.dart';

void main() {
  for (final device in deviceMatrix) {
    testWidgets('AI Translator lays out on $device', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      device.apply(tester);
      await tester.pumpWidget(
        createTestableWidget(
          child: const AiTranslatorScreen(),
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        ),
      );
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);

      final translate = find.text('TRANSLATE MAGIC');
      await tester.ensureVisible(translate);
      await tester.pump();
      expect(translate.hitTestable(), findsOneWidget);
      await pumpFrames(tester, frames: 25);
    });
  }
}
