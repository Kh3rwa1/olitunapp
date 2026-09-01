import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/widgets/content_hero.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ContentHero Multilingual Display Tests', () {
    testWidgets('renders word in Bengali mode with Bengali meaning and transliteration', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final wordItem = ContentItem(
        id: 'w_baba',
        kind: ContentKind.word,
        categoryId: 'cat_family',
        title: 'Baba',
        olChiki: 'ᱵᱟᱵᱟ',
        subtitle: 'Father',
        blocks: const [],
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            teachingLanguageProvider.overrideWith((ref) => 'bn'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ContentHero(
                item: wordItem,
                accentColor: Colors.blue,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ol Chiki script in middle
      expect(find.text('ᱵᱟᱵᱟ'), findsWidgets);
      // Bengali meaning in main title (Zero English / Roman leakage)
      expect(find.text('পিতা'), findsOneWidget);
      // Bengali transliteration in subtitle
      expect(find.text('বাবা'), findsOneWidget);
      // Roman "Father" should NOT be present
      expect(find.text('Father'), findsNothing);
    });

    testWidgets('renders sentence in Hindi mode with Hindi meaning and Devanagari transliteration', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final sentenceItem = ContentItem(
        id: 's_work',
        kind: ContentKind.sentence,
        categoryId: 'cat_sentences',
        title: 'In do kamiyedanj',
        olChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱹᱧ',
        subtitle: 'I am working',
        blocks: const [],
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            teachingLanguageProvider.overrideWith((ref) => 'hi'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ContentHero(
                item: sentenceItem,
                accentColor: Colors.purple,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ol Chiki script in middle
      expect(find.text('ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱹᱧ'), findsWidgets);
      // Hindi meaning in main title
      expect(find.text('मैं काम कर रहा हूँ'), findsOneWidget);
      // Hindi Devanagari transliteration in subtitle
      expect(find.text('इञ द कामियेदाञ'), findsOneWidget);
      // Roman "I am working" in title should NOT be present
      expect(find.text('I am working'), findsNothing);
    });

    testWidgets('renders lesson item retaining regular title and subtitle', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final lessonItem = ContentItem(
        id: 'l_1',
        kind: ContentKind.lesson,
        categoryId: 'cat_lessons',
        title: 'Lesson 1: Basics',
        titleOlChiki: 'ᱯᱟᱹᱴᱷ ᱑',
        subtitle: 'Introduction to Santali',
        blocks: const [],
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            teachingLanguageProvider.overrideWith((ref) => 'bn'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ContentHero(
                item: lessonItem,
                accentColor: Colors.green,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ᱯᱟᱹᱴᱷ ᱑'), findsWidgets);
      expect(find.text('Lesson 1: Basics'), findsOneWidget);
      expect(find.text('Introduction to Santali'), findsOneWidget);
    });
  });
}
