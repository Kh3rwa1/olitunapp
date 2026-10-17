import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/ai_studio/data/ai_studio_service.dart';
import 'package:itun/features/ai_studio/data/studio_input_picker.dart';
import 'package:itun/features/ai_studio/data/studio_recorder.dart';
import 'package:itun/features/ai_studio/presentation/ai_studio_screen.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/device_matrix.dart';

class _Service extends Mock implements AiStudioService {}

class _Picker extends Mock implements StudioInputPicker {}

class _Recorder implements StudioRecorder {
  @override
  bool get isRecording => false;

  @override
  Future<void> start() async {}

  @override
  Future<StudioInput?> stop() async =>
      StudioInput(bytes: Uint8List(2), name: 'microphone.wav');

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  Future<void> pumpStudio(WidgetTester tester, TestDevice device) async {
    final service = _Service();
    when(() => service.configured).thenReturn(true);
    device.apply(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiStudioServiceProvider.overrideWithValue(service),
          studioInputPickerProvider.overrideWithValue(_Picker()),
          studioRecorderProvider.overrideWithValue(_Recorder()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AiStudioScreen(),
        ),
      ),
    );
    await pumpFrames(tester);
  }

  for (final device in deviceMatrix) {
    for (final tool in ['transcribe', 'translate', 'scan']) {
      testWidgets('AI Studio $tool lays out on $device', (tester) async {
        await pumpStudio(tester, device);
        final tab = find.byKey(Key('tool-$tool'));
        await tester.ensureVisible(tab);
        await tester.tap(tab);
        await pumpFrames(tester);
        expect(tester.takeException(), isNull);

        // The primary "… with AI" action stays reachable.
        final process = find.byKey(const Key('studio-process'));
        await tester.ensureVisible(process);
        await tester.pump();
        expect(process.hitTestable(), findsOneWidget);
        await pumpFrames(tester, frames: 25);
      });
    }
  }
}
