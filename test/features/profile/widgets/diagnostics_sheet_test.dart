import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/observability/app_observability.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/profile/presentation/widgets/diagnostics_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async {
          if (message.method == 'Clipboard.setData') {
            return null;
          }
          if (message.method == 'Clipboard.getData') {
            return {'text': 'mock'};
          }
          return null;
        });
    AppObservability.tracker.clear();
    AppObservability.recordInteraction('SettingsScreen', 'mount');
  });

  group('DiagnosticsTile & DiagnosticsSheet Tests', () {
    testWidgets('renders DiagnosticsTile with system health info', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: Scaffold(body: DiagnosticsTile())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Diagnostics & Health'), findsOneWidget);
    });

    testWidgets('opens DiagnosticsSheet and handles Copy Diagnostics trigger', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const MaterialApp(home: Scaffold(body: DiagnosticsTile())),
        ),
      );
      await tester.pumpAndSettle();

      // Open sheet
      await tester.tap(find.byType(DiagnosticsTile));
      await tester.pumpAndSettle();

      expect(find.text('System Diagnostics & Health'), findsWidgets);
      expect(find.text('Diagnostic Payload Preview'), findsOneWidget);
      expect(find.text('Copy Anonymized Diagnostics'), findsOneWidget);

      // Tap Copy button
      await tester.ensureVisible(find.text('Copy Anonymized Diagnostics'));
      await tester.tap(find.text('Copy Anonymized Diagnostics'));
      await tester.pumpAndSettle();

      expect(find.text('Copied to Clipboard'), findsOneWidget);
    });
  });
}
