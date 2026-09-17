import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/ai_studio/data/ai_studio_service.dart';
import 'package:itun/features/ai_studio/data/studio_input_picker.dart';
import 'package:itun/features/ai_studio/data/studio_recorder.dart';
import 'package:itun/features/ai_studio/presentation/ai_studio_screen.dart';
import 'package:mocktail/mocktail.dart';

class _Service extends Mock implements AiStudioService {}

class _Picker extends Mock implements StudioInputPicker {}

class _Input extends Mock implements StudioInput {}

class _Job extends Mock implements StudioJob {}

class _Recorder implements StudioRecorder {
  _Recorder(this.input);

  final StudioInput input;
  int starts = 0;
  int stops = 0;
  int cancels = 0;
  bool _isRecording = false;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<void> start() async {
    starts++;
    _isRecording = true;
  }

  @override
  Future<StudioInput?> stop() async {
    stops++;
    _isRecording = false;
    return input;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    _isRecording = false;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  late _Service service;
  late _Picker picker;
  late _Input input;
  late _Recorder recorder;

  setUp(() {
    service = _Service();
    picker = _Picker();
    input = _Input();
    when(() => service.configured).thenReturn(true);
    when(() => input.name).thenReturn('sample.wav');
    when(() => input.bytes).thenReturn(Uint8List(4));
    when(() => picker.pickAudio()).thenAnswer((_) async => input);
    when(() => picker.pickDocument()).thenAnswer((_) async => input);
    recorder = _Recorder(
      StudioInput(bytes: Uint8List.fromList([1, 0]), name: 'microphone.wav'),
    );
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1400, 1800),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiStudioServiceProvider.overrideWithValue(service),
          studioInputPickerProvider.overrideWithValue(picker),
          studioRecorderProvider.overrideWithValue(recorder),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const AiStudioScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> consent(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('studio-consent')));
  Future<void> process(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('studio-process')));
  Future<void> selectTranslate(WidgetTester tester) =>
      tap(tester, find.byKey(const Key('tool-translate')));
  FilledButton processButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('studio-process')));

  testWidgets(
    'requires consent, renders actual result, and invalidates consent on edit',
    (tester) async {
      when(
        () => service.translate('hello', 'hi-IN'),
      ).thenAnswer((_) async => 'Actual response');
      await pump(tester);
      expect(find.text('AI Studio'), findsOneWidget);
      expect(find.textContaining('Sarvam'), findsOneWidget);
      await selectTranslate(tester);
      expect(processButton(tester).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('studio-source')), 'hello');
      await tester.pump();
      expect(processButton(tester).onPressed, isNull);
      await consent(tester);
      expect(processButton(tester).onPressed, isNotNull);
      await process(tester);
      await tester.pumpAndSettle();
      expect(find.text('Actual response'), findsOneWidget);
      verify(() => service.translate('hello', 'hi-IN')).called(1);
      await tester.enterText(find.byKey(const Key('studio-source')), 'changed');
      await tester.pump();
      expect(processButton(tester).onPressed, isNull);
    },
  );

  testWidgets('unconfigured service disables processing without fake results', (
    tester,
  ) async {
    when(() => service.configured).thenReturn(false);
    await pump(tester);
    expect(find.textContaining('not available in this build'), findsOneWidget);
    await selectTranslate(tester);
    await tester.enterText(find.byKey(const Key('studio-source')), 'hello');
    await consent(tester);
    expect(processButton(tester).onPressed, isNull);
    expect(find.text('Your result will appear here.'), findsOneWidget);
  });

  testWidgets(
    'shows loading and error, retains input, does not claim success',
    (tester) async {
      final response = Completer<String>();
      when(
        () => service.translate('hello', 'hi-IN'),
      ).thenAnswer((_) => response.future);
      await pump(tester);
      await selectTranslate(tester);
      await tester.enterText(find.byKey(const Key('studio-source')), 'hello');
      await consent(tester);
      await process(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(processButton(tester).onPressed, isNull);
      response.completeError(StateError('private server details'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Processing failed.'), findsOneWidget);
      expect(find.textContaining('private server details'), findsNothing);
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('Your result will appear here.'), findsOneWidget);
    },
  );

  testWidgets('scan is manual, retains job across tools and preserves edits', (
    tester,
  ) async {
    final pending = _Job();
    final complete = _Job();
    when(() => pending.id).thenReturn('job-1');
    when(() => pending.status).thenReturn('processing');
    when(() => pending.text).thenReturn('Partial page');
    when(() => pending.isTerminal).thenReturn(false);
    when(() => complete.id).thenReturn('job-1');
    when(() => complete.status).thenReturn('completed');
    when(() => complete.text).thenReturn('Full page');
    when(() => complete.isTerminal).thenReturn(true);
    when(
      () => service.startOcr(input, 'hi-IN'),
    ).thenAnswer((_) async => pending);
    when(() => service.pollOcr('job-1')).thenAnswer((_) async => complete);
    await pump(tester);
    await tap(tester, find.byKey(const Key('tool-scan')));
    await tap(tester, find.byKey(const Key('studio-pick')));
    await consent(tester);
    await process(tester);
    await tester.pumpAndSettle();
    expect(find.text('Partial page'), findsOneWidget);
    await tester.pump(const Duration(minutes: 1));
    verifyNever(() => service.pollOcr('job-1'));
    await tester.enterText(
      find.byKey(const Key('studio-result-scan')),
      'My corrected page',
    );
    await tap(tester, find.byKey(const Key('tool-transcribe')));
    await tap(tester, find.byKey(const Key('tool-scan')));
    expect(find.text('Job: job-1'), findsOneWidget);
    await tap(tester, find.byKey(const Key('studio-check-status')));
    await tester.pumpAndSettle();
    expect(find.text('My corrected page'), findsOneWidget);
    expect(find.text('Full page'), findsNothing);
    verify(() => service.pollOcr('job-1')).called(1);
  });

  testWidgets('translation rejects oversized input without truncation', (
    tester,
  ) async {
    await pump(tester);
    await selectTranslate(tester);
    final text = 'a' * 2001;
    await tester.enterText(find.byKey(const Key('studio-source')), text);
    await consent(tester);
    expect(processButton(tester).onPressed, isNull);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('studio-source')))
          .controller!
          .text,
      text,
    );
  });

  testWidgets(
    'transcribe opens first with microphone primary and WAV upload optional',
    (tester) async {
      await pump(tester);

      expect(find.byKey(const Key('studio-record')), findsOneWidget);
      expect(find.text('Record voice'), findsOneWidget);
      expect(find.text('Upload WAV file'), findsOneWidget);
      expect(find.byKey(const Key('studio-source')), findsNothing);

      await tap(tester, find.byKey(const Key('studio-record')));
      expect(recorder.starts, 1);
      expect(find.text('Stop recording · 00s'), findsOneWidget);

      await tap(tester, find.byKey(const Key('studio-record')));
      await tester.pumpAndSettle();
      expect(recorder.stops, 1);
      expect(find.text('microphone.wav'), findsOneWidget);
      expect(processButton(tester).onPressed, isNull);
    },
  );

  testWidgets('small screen and large text do not overflow in any tool', (
    tester,
  ) async {
    await pump(tester, size: const Size(360, 800), scale: 2);
    expect(tester.takeException(), isNull);
    for (final tool in ['transcribe', 'scan', 'translate']) {
      await tap(tester, find.byKey(Key('tool-$tool')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
