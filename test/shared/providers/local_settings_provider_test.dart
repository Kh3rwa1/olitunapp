import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/main.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';

void main() {
  group('app language settings', () {
    test('defaults to English and maps Santali to the sat locale', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(appLanguageProvider), 'en');
      expect(appLocaleForLanguage('en').languageCode, 'en');
      expect(appLocaleForLanguage('sat').languageCode, 'sat');
    });

    testWidgets('persists and publishes selected app language', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      updateAppLanguage(capturedRef, 'sat');

      expect(capturedRef.read(appLanguageProvider), 'sat');
      expect(prefs.getString('app_language'), 'sat');
    });
  });
}
