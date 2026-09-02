import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/playback_controller.dart';
import 'package:itun/features/admin/presentation/letters/widgets/letter_card.dart';
import 'package:itun/features/admin/presentation/letters/widgets/letter_grid.dart';
import 'package:itun/features/content/presentation/providers/audio_playback_providers.dart';
import 'package:itun/shared/models/content/letter_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockPlaybackController extends Mock implements PlaybackController {}

LetterModel _letter({String? audioUrl}) => LetterModel(
  id: 'letter_1',
  charOlChiki: 'ᱚ',
  transliterationLatin: "o'",
  audioUrl: audioUrl,
);

Widget _wrap(Widget child, {_MockPlaybackController? playback}) {
  return ProviderScope(
    overrides: [
      if (playback != null)
        playbackControllerProvider.overrideWithValue(playback),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('LetterCard', () {
    testWidgets('renders Ol Chiki glyph and transliteration', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 240,
            child: LetterCard(
              letter: _letter(),
              isDark: false,
              index: 0,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('ᱚ'), findsOneWidget);
      expect(find.text("o'"), findsOneWidget);
    });

    testWidgets('shows audio button only when audioUrl is present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 240,
            child: LetterCard(
              letter: _letter(audioUrl: 'https://example.com/a.mp3'),
              isDark: true,
              index: 0,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('tapping the card triggers onEdit', (tester) async {
      var edited = false;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 240,
            child: LetterCard(
              letter: _letter(),
              isDark: false,
              index: 0,
              onEdit: () => edited = true,
              onDelete: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('ᱚ'));
      expect(edited, isTrue);
    });

    testWidgets('tapping audio button routes through playback controller', (
      tester,
    ) async {
      final playback = _MockPlaybackController();
      when(
        () => playback.playSingle(
          id: any(named: 'id'),
          contentKind: any(named: 'contentKind'),
          contentId: any(named: 'contentId'),
          trackType: any(named: 'trackType'),
          languageCode: any(named: 'languageCode'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 240,
            child: LetterCard(
              letter: _letter(audioUrl: 'https://example.com/a.mp3'),
              isDark: false,
              index: 0,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
          playback: playback,
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pump();

      verify(
        () => playback.playSingle(
          id: 'https://example.com/a.mp3',
          contentKind: 'letter',
          contentId: 'letter_1',
          trackType: any(named: 'trackType'),
          languageCode: 'sat',
        ),
      ).called(1);
    });
  });

  group('LetterGrid', () {
    testWidgets('renders one card per letter', (tester) async {
      final letters = [
        _letter(),
        LetterModel(
          id: 'letter_2',
          charOlChiki: '᱑',
          transliterationLatin: 'ol',
        ),
      ];
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 800,
            height: 600,
            child: LetterGrid(
              letters: letters,
              isDark: false,
              isWideScreen: false,
              onEdit: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(LetterCard), findsNWidgets(2));
      expect(find.text("o'"), findsOneWidget);
    });
  });
}
