import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/voice/presentation/screens/santali_voice_screen.dart';
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
    when(
      () => audio.currentProcessingState,
    ).thenReturn(ProcessingState.idle);
    tester.view.physicalSize = const Size(2000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: SantaliVoiceScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Santali AI Voice'), findsWidgets);
    expect(find.text('CREATE VOICE'), findsOneWidget);
    // Santali-first voices are hero picks.
    expect(find.text('Phulmani • Female'), findsOneWidget);
    expect(find.text('Sibu • Male'), findsOneWidget);
    // Neutral style default is visible in the style rail.
    expect(find.text('Neutral'), findsOneWidget);
  });
}
