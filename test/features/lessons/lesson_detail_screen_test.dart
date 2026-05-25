import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/features/content/presentation/content_detail_screen.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/core/audio/audio_service.dart';
import 'package:itun/core/analytics/analytics_service.dart';
import 'package:itun/core/storage/hive_service.dart';

class MockAudioService extends AudioService {
  @override
  Future<void> playUrl(String url) async {}
}

class MockAnalyticsService implements LearningAnalyticsService {
  @override
  Future<void> track(
    String eventName, {
    String? source,
    String? sourceId,
    Map<String, dynamic> metadata = const {},
    String? learnerLevel,
    String? scriptMode,
  }) async {}

  @override
  Future<void> flushPending() async {}
}

void main() {
  final mockLessonItem = ContentItem(
    id: 'test_lesson_1',
    kind: ContentKind.lesson,
    categoryId: 'alphabets',
    title: 'Lesson 1',
    titleOlChiki: 'ᱚ',
    blocks: const [
      TextBlock(
        id: 'block_1',
        order: 0,
        markdown: 'This is the first letter of Ol Chiki.',
      ),
    ],
    updatedAt: DateTime(2026, 5, 25),
  );

  testWidgets('ContentDetailScreen shows loading state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(MockAudioService()),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockAnalyticsService(),
          ),
          contentDetailProvider((
            ContentKind.lesson,
            'test_lesson_1',
          )).overrideWith((ref) => Completer<ContentItem>().future),
        ],
        child: const MaterialApp(
          home: ContentDetailScreen(
            kind: ContentKind.lesson,
            id: 'test_lesson_1',
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ContentDetailScreen shows lesson content', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(MockAudioService()),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockAnalyticsService(),
          ),
          contentDetailProvider((
            ContentKind.lesson,
            'test_lesson_1',
          )).overrideWith((ref) => mockLessonItem),
        ],
        child: const MaterialApp(
          home: ContentDetailScreen(
            kind: ContentKind.lesson,
            id: 'test_lesson_1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lesson 1'), findsOneWidget);
    expect(find.text('This is the first letter of Ol Chiki.'), findsOneWidget);
  });

  testWidgets('ContentDetailScreen shows error state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(MockAudioService()),
          learningAnalyticsServiceProvider.overrideWithValue(
            MockAnalyticsService(),
          ),
          contentDetailProvider((
            ContentKind.lesson,
            'test_lesson_1',
          )).overrideWith((ref) => throw Exception('Network failure')),
        ],
        child: const MaterialApp(
          home: ContentDetailScreen(
            kind: ContentKind.lesson,
            id: 'test_lesson_1',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Error loading content'), findsOneWidget);
  });
}
