import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/presentation/widgets/notifications_settings_card.dart';
import 'package:itun/shared/providers/notification_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required SharedPreferences prefs,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NotificationsSettingsCard(isDark: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('NotificationsSettingsCard', () {
    testWidgets(
      'renders daily study reminder switch and reminder time when enabled',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'notifications_enabled': true,
          'reminder_hour': 20,
          'reminder_minute': 0,
        });
        final prefs = await SharedPreferences.getInstance();

        await pumpCard(tester, prefs: prefs);

        expect(find.text('NOTIFICATIONS & HABITS'), findsOneWidget);
        expect(find.text('Daily Study Reminder'), findsOneWidget);
        expect(find.text('Reminder Time'), findsOneWidget);
        expect(find.text('8:00 PM'), findsOneWidget);

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);
      },
    );

    testWidgets('hides reminder time tile when notifications are disabled', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': false});
      final prefs = await SharedPreferences.getInstance();

      await pumpCard(tester, prefs: prefs);

      expect(find.text('Daily Study Reminder'), findsOneWidget);
      expect(find.text('Reminder Time'), findsNothing);

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('toggling switch toggles notificationsEnabledProvider', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'notifications_enabled': true});
      final prefs = await SharedPreferences.getInstance();

      await pumpCard(tester, prefs: prefs);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(NotificationsSettingsCard));
      final container = ProviderScope.containerOf(context);
      expect(container.read(notificationsEnabledProvider), isFalse);
      expect(prefs.getBool('notifications_enabled'), isFalse);
    });
  });
}
