import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/translations/models/translation_entry.dart';
import 'package:itun/features/admin/presentation/translations/widgets/translation_edit_dialog.dart';
import 'package:itun/features/admin/presentation/translations/widgets/translation_stats_card.dart';

TranslationEntry _entry({Map<String, String>? translations}) =>
    TranslationEntry(
      id: 'word_1',
      kind: TranslationKind.word,
      textOlChiki: 'ᱡᱚᱦᱟᱨ',
      textLatin: 'johar',
      englishMeaning: 'hello',
      category: 'greetings',
      customTranslations: translations,
    );

void main() {
  group('TranslationStatsCard', () {
    Future<void> pumpCard(
      WidgetTester tester, {
      required int total,
      required int translated,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 620,
              child: TranslationStatsCard(
                selectedLang: 'bn',
                langName: 'Bengali',
                langFlag: '🇧🇩',
                totalCount: total,
                translatedCount: translated,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows computed coverage percentage and progress', (
      tester,
    ) async {
      await pumpCard(tester, total: 10, translated: 5);

      expect(find.text('Bengali Translation Coverage'), findsOneWidget);
      expect(find.text('50% Covered'), findsOneWidget);
      expect(
        find.text(
          '5 of 10 items have localized meaning & transliteration in Bengali',
        ),
        findsOneWidget,
      );
    });

    testWidgets('treats empty collections as fully covered', (tester) async {
      await pumpCard(tester, total: 0, translated: 0);

      expect(find.text('100% Covered'), findsOneWidget);
    });

    testWidgets('marks 95 percent and above as complete', (tester) async {
      await pumpCard(tester, total: 100, translated: 96);

      expect(find.text('96% Covered'), findsOneWidget);
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, closeTo(0.96, 0.001));
    });
  });

  group('TranslationEditDialog', () {
    Future<void> pumpDialog(
      WidgetTester tester, {
      required String activeLang,
      Map<String, String>? translations,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => TranslationEditDialog.show(
                    context,
                    _entry(translations: translations),
                    activeLang,
                    false,
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders reference fields for the entry', (tester) async {
      await pumpDialog(tester, activeLang: 'en');

      expect(find.text('Multilingual Translation Detail'), findsOneWidget);
      expect(find.text('Word · greetings'), findsOneWidget);
      expect(find.text('Ol Chiki Script'), findsOneWidget);
      expect(find.text('Romanized Santali'), findsOneWidget);
      expect(find.text('English Base Meaning'), findsOneWidget);
    });

    testWidgets('prefills the meaning field from custom translations', (
      tester,
    ) async {
      await pumpDialog(
        tester,
        activeLang: 'bn',
        translations: const {'bn': 'নমস্কার'},
      );

      expect(find.text('নমস্কার'), findsWidgets);
      expect(find.text('Translated Meaning (BN)*'), findsOneWidget);
    });

    testWidgets('close button dismisses the dialog', (tester) async {
      await pumpDialog(tester, activeLang: 'en');

      await tester.tap(find.text('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Multilingual Translation Detail'), findsNothing);
    });
  });
}
