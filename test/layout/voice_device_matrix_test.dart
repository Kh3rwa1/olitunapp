import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/voice/presentation/screens/santali_voice_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/lessons/lesson_block_detail_screen_test.dart'
    show MockAudioService;
import '../helpers/device_matrix.dart';

void main() {
  Future<void> pumpVoice(WidgetTester tester, TestDevice device) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    device.apply(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioServiceProvider.overrideWithValue(MockAudioService()),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SantaliVoiceScreen(),
        ),
      ),
    );
    await pumpFrames(tester);
  }

  for (final device in deviceMatrix) {
    testWidgets('Santali AI Voice lays out on $device', (tester) async {
      await pumpVoice(tester, device);
      expect(tester.takeException(), isNull);
      final create = find.text('CREATE VOICE');
      await tester.ensureVisible(create);
      await tester.pump();
      expect(create.hitTestable(), findsOneWidget);
      await pumpFrames(tester, frames: 25);
    });

    testWidgets('Santali AI Voice keeps the player side on $device while the '
        'keyboard opens and closes', (tester) async {
      await pumpVoice(tester, device);
      FlipCardState card() =>
          tester.state<FlipCardState>(find.byType(FlipCard));

      // Generating flips the card to the player.
      if (card().isFront) card().flipCard();
      await pumpFrames(tester, frames: 4);
      expect(card().isFront, isFalse);

      for (final open in [true, false]) {
        TestDevice.setKeyboard(tester, open: open);
        await pumpFrames(tester, frames: 3);
        expect(card().isFront, isFalse, reason: 'keyboard open: $open');
      }
      expect(tester.takeException(), isNull);
      await pumpFrames(tester, frames: 25);
    });
  }
}
