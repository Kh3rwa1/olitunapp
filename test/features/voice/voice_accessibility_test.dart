import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/voice/presentation/screens/santali_voice_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/widgets/animated_buttons.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAudioService extends Mock implements AudioService {}

void main() {
  late _FakeAudioService audio;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    audio = _FakeAudioService();
    when(() => audio.isPlayingStream).thenAnswer((_) => const Stream.empty());
    when(() => audio.positionStream).thenAnswer((_) => const Stream.empty());
    when(() => audio.durationStream).thenAnswer((_) => const Stream.empty());
    when(
      () => audio.processingStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => audio.webPlaybackEndedStream,
    ).thenAnswer((_) => const Stream<void>.empty());
    when(() => audio.currentUrl).thenReturn(null);
    when(() => audio.currentProcessingState).thenReturn(ProcessingState.idle);
  });

  Future<void> pumpVoiceStudio(
    WidgetTester tester, {
    Size size = const Size(800, 1200),
    double textScale = 1.0,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const SantaliVoiceScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('SantaliVoiceScreen Accessibility & Text Scaling', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('Renders without overflow at textScale $scale (mobile)', (
        WidgetTester tester,
      ) async {
        await pumpVoiceStudio(
          tester,
          size: const Size(400, 800),
          textScale: scale,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SantaliVoiceScreen), findsOneWidget);
        expect(find.text('CREATE VOICE'), findsOneWidget);
      });

      testWidgets('Renders without overflow at textScale $scale (desktop)', (
        WidgetTester tester,
      ) async {
        await pumpVoiceStudio(
          tester,
          size: const Size(1200, 900),
          textScale: scale,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SantaliVoiceScreen), findsOneWidget);
        expect(find.text('CREATE VOICE'), findsOneWidget);
      });
    }

    testWidgets('Interactive elements meet tap target size guidelines', (
      WidgetTester tester,
    ) async {
      await pumpVoiceStudio(tester, size: const Size(400, 800));

      // Close button meets touch target
      final closeFinder = find.byType(IconButton);
      expect(closeFinder, findsOneWidget);
      final closeSize = tester.getSize(closeFinder);
      expect(closeSize.width, greaterThanOrEqualTo(40));
      expect(closeSize.height, greaterThanOrEqualTo(40));

      // Create Voice button height >= 48
      final buttonFinder = find.byType(DuoButton);
      expect(buttonFinder, findsOneWidget);
      final buttonSize = tester.getSize(buttonFinder);
      expect(buttonSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('Accessible semantics and tooltips are present', (
      WidgetTester tester,
    ) async {
      await pumpVoiceStudio(tester, size: const Size(800, 1000));

      // Semantics tree does not throw errors
      final handle = tester.ensureSemantics();

      expect(find.byTooltip('Close voice studio'), findsOneWidget);
      expect(find.text('CREATE VOICE'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('Dark and Light contrast rendering stability', (
      WidgetTester tester,
    ) async {
      // Light
      await pumpVoiceStudio(tester, size: const Size(800, 1000));
      expect(tester.takeException(), isNull);

      // Dark
      await pumpVoiceStudio(
        tester,
        size: const Size(800, 1000),
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
