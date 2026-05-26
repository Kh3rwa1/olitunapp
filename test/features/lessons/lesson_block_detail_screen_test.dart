import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/shared/providers/providers.dart';
import 'package:itun/core/audio/audio_service.dart';

class MockAudioService extends Mock implements AudioService {
  @override
  Future<void> playUrl(String url) async {}
}

void main() {
  final mockLessons = [
    const LessonEntity(
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
          data: {
            'pronunciation': 'at',
            'themeColor': '#10B981',
          },
        ),
        LessonBlockEntity(
          type: 'text',
          textOlChiki: 'ᱛ',
          textLatin: 'Ot',
          audioUrl: 'https://example.com/audio2.mp3',
          data: {
            'pronunciation': 'ot',
            'themeColor': '#14B8A6',
          },
        ),
      ],
    ),
  ];

  testWidgets('LessonBlockDetailScreen shows loading state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerLessonsProvider.overrideWithValue(const AsyncValue.loading()),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('LessonBlockDetailScreen shows error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerLessonsProvider.overrideWithValue(AsyncValue.error('Error loading', StackTrace.empty)),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Could not load lesson details'), findsOneWidget);
  });

  testWidgets('LessonBlockDetailScreen shows not found state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerLessonsProvider.overrideWithValue(const AsyncValue.data([])),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Lesson not found'), findsOneWidget);
  });

  testWidgets('LessonBlockDetailScreen renders content details and page swiping works', (tester) async {
    final mockAudioService = MockAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerLessonsProvider.overrideWithValue(AsyncValue.data(mockLessons)),
          audioServiceProvider.overrideWithValue(mockAudioService),
          reduceVisualEffectsProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(
          home: LessonBlockDetailScreen(
            lessonId: 'lesson_1',
            initialBlockIndex: 0,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify first page renders details
    expect(find.text('At (at)'), findsOneWidget);
    expect(find.text('AT (AT)'), findsOneWidget);
    expect(find.text('Pronunciation'), findsOneWidget);
    expect(find.text('at'), findsOneWidget);

    // Slide/Swipe to the second page
    final pageViewFinder = find.byType(PageView);
    expect(pageViewFinder, findsOneWidget);

    await tester.fling(pageViewFinder, const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    // Verify second page renders details
    expect(find.text('Ot (ot)'), findsOneWidget);
    expect(find.text('OT (OT)'), findsOneWidget);
    expect(find.text('ot'), findsOneWidget);
  });
}
