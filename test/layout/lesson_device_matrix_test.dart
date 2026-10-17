import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/presentation/providers/lesson_notifier.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/catalog/lesson_entity.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/lessons/lesson_block_detail_screen_test.dart'
    show MockAudioService, MockHttpOverrides;
import '../helpers/device_matrix.dart';

void main() {
  setUpAll(() => HttpOverrides.global = MockHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  const lessons = [
    LessonEntity(
      id: 'lesson_1',
      categoryId: 'cat_1',
      titleOlChiki: 'ᱛᱤ',
      titleLatin: 'Ti',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱚ',
          textLatin: 'At',
          audioUrl: 'https://example.com/audio1.mp3',
          data: {'pronunciation': 'at', 'themeColor': '#10B981'},
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱛᱟᱦᱮᱸ ᱫᱚ ᱡᱚᱛᱚ ᱠᱷᱚᱱ ᱢᱟᱨᱟᱝ ᱠᱟᱱᱟ',
          textLatin: 'A longer sentence that wraps across several lines',
          audioUrl: 'https://example.com/audio2.mp3',
          data: {'pronunciation': 'ot', 'themeColor': '#14B8A6'},
        ),
      ],
    ),
  ];

  for (final device in deviceMatrix) {
    testWidgets('Lesson page lays out on $device', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      device.apply(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            learnerLessonsProvider.overrideWithValue(
              const AsyncValue.data(lessons),
            ),
            lessonsByCategoryProvider(
              'cat_1',
            ).overrideWithValue(const AsyncValue.data(lessons)),
            audioServiceProvider.overrideWithValue(MockAudioService()),
            reduceVisualEffectsProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LessonBlockDetailScreen(
              lessonId: 'lesson_1',
              initialBlockIndex: 0,
            ),
          ),
        ),
      );
      await pumpFrames(tester, frames: 15);
      expect(tester.takeException(), isNull);

      // Both pages (short letter, long wrapping sentence) keep LISTEN usable.
      for (var page = 0; page < 2; page++) {
        final listen = find.text('LISTEN');
        await tester.ensureVisible(listen);
        await tester.pump();
        expect(listen.hitTestable(), findsOneWidget, reason: 'page $page');
        if (page == 0) {
          // Half a screen: one page on every width.
          await tester.fling(
            find.byType(PageView),
            Offset(-device.size.width / 2, 0),
            800,
          );
          await pumpFrames(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('STEP 2 OF 3'), findsOneWidget);
        }
      }
      await pumpFrames(tester, frames: 25);
    });
  }
}
