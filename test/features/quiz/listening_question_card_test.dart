import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/quiz/presentation/widgets/listening_question_card.dart';
import 'package:itun/shared/models/content_models.dart';

void main() {
  final question = QuizQuestion(
    type: 'listen_meaning',
    promptOlChiki: 'ᱚ',
    promptLatin: 'Listen and choose the correct meaning:',
    optionsOlChiki: ['Water', 'Fire', 'Food', 'Tree'],
    optionsLatin: ['Water', 'Fire', 'Food', 'Tree'],
    audioUrl: 'https://example.com/audio/sat_greetings_1.mp3',
  );

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders play button and calls onPlayTap when tapped', (
    tester,
  ) async {
    var playTaps = 0;
    var stopTaps = 0;

    await tester.pumpWidget(
      wrap(
        ListeningQuestionCard(
          question: question,
          isPlaying: false,
          isLoading: false,
          playbackError: null,
          onPlayTap: () => playTaps++,
          onStopTap: () => stopTaps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();

    expect(playTaps, 1);
    expect(stopTaps, 0);
  });

  testWidgets('shows stop icon and calls onStopTap when playing', (
    tester,
  ) async {
    var playTaps = 0;
    var stopTaps = 0;

    await tester.pumpWidget(
      wrap(
        ListeningQuestionCard(
          question: question,
          isPlaying: true,
          isLoading: false,
          playbackError: null,
          onPlayTap: () => playTaps++,
          onStopTap: () => stopTaps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();

    expect(stopTaps, 1);
    expect(playTaps, 0);
  });

  testWidgets('shows loading spinner instead of an icon while loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ListeningQuestionCard(
          question: question,
          isPlaying: false,
          isLoading: true,
          playbackError: null,
          onPlayTap: () {},
          onStopTap: () {},
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);
  });

  testWidgets('surfaces playback error text when provided', (tester) async {
    await tester.pumpWidget(
      wrap(
        ListeningQuestionCard(
          question: question,
          isPlaying: false,
          isLoading: false,
          playbackError: 'Audio failed to load.',
          onPlayTap: () {},
          onStopTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('listening-playback-error')),
      findsOneWidget,
    );
    expect(find.text('Audio failed to load.'), findsOneWidget);
  });

  testWidgets('shows no-audio hint when the question has no audio URL', (
    tester,
  ) async {
    final audiolessQuestion = QuizQuestion(
      type: 'listen_meaning',
      promptOlChiki: 'ᱚ',
      promptLatin: 'Listen and choose the correct meaning:',
      optionsOlChiki: ['Water', 'Fire', 'Food', 'Tree'],
      optionsLatin: ['Water', 'Fire', 'Food', 'Tree'],
    );

    await tester.pumpWidget(
      wrap(
        ListeningQuestionCard(
          question: audiolessQuestion,
          isPlaying: false,
          isLoading: false,
          playbackError: null,
          onPlayTap: () {},
          onStopTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('listening-no-audio-hint')),
      findsOneWidget,
    );
  });

  testWidgets('hides no-audio hint when audio URL is present', (tester) async {
    await tester.pumpWidget(
      wrap(
        ListeningQuestionCard(
          question: question,
          isPlaying: false,
          isLoading: false,
          playbackError: null,
          onPlayTap: () {},
          onStopTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listening-no-audio-hint')), findsNothing);
  });
}
