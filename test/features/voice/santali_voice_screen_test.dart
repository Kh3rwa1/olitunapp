import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/voice/presentation/screens/santali_voice_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:just_audio/just_audio.dart' show ProcessingState;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAudioService extends Mock implements AudioService {}

void main() {
  testWidgets('SantaliVoiceScreen renders studio without exceptions', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final audio = _FakeAudioService();
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
    tester.view.physicalSize = const Size(2000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SantaliVoiceScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Santali AI Voice'), findsWidgets);
    expect(find.text('CREATE VOICE'), findsOneWidget);
    // Santali-first voices are hero picks.
    expect(find.text('Phulmani'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Sibu'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    // Neutral style default is visible in the style rail.
    expect(find.text('Neutral'), findsOneWidget);
  });

  testWidgets('AI Studio passage handoff pre-fills the studio text box', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final audio = _FakeAudioService();
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
    tester.view.physicalSize = const Size(2000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SantaliVoiceScreen(initialText: 'ᱡᱚᱦᱟᱨ'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
  });

  testWidgets(
    'the player side survives the keyboard shrinking a short screen',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final audio = _FakeAudioService();
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
      // A phone with room for the compact (single-screen) layout.
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            audioServiceProvider.overrideWithValue(audio),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SantaliVoiceScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));

      // Generating flips the card to the player side.
      tester.state<FlipCardState>(find.byType(FlipCard)).flipCard();
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.state<FlipCardState>(find.byType(FlipCard)).isFront, false);

      // The keyboard opens: the screen drops below the compact layout and
      // back. The card must keep showing the player.
      tester.view.physicalSize = const Size(400, 480);
      await tester.pump(const Duration(milliseconds: 300));
      tester.view.physicalSize = const Size(400, 900);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.state<FlipCardState>(find.byType(FlipCard)).isFront, false);
      // Let the layout switch's animations settle before teardown.
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
