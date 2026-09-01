import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/translations/models/translation_entry.dart';
import 'package:itun/features/admin/presentation/widgets/multilingual_preview_box.dart';

void main() {
  group('TranslationEntry Model Tests', () {
    test('resolves Bengali meaning and pronunciation for vocabulary word', () {
      const entry = TranslationEntry(
        id: 'test_word_1',
        kind: TranslationKind.word,
        textOlChiki: 'ᱵᱟᱵᱟ',
        textLatin: 'baba',
        englishMeaning: 'Father',
      );

      expect(entry.meaningFor('bn'), 'পিতা');
      expect(entry.transliterationFor('bn'), 'বাবা');
      expect(entry.meaningFor('hi'), 'पिता');
      expect(entry.meaningFor('or'), 'ବାପା');
      expect(entry.meaningFor('en'), 'Father');
      expect(entry.isTranslatedFor('bn'), isTrue);
    });

    test('resolves Bengali meaning and pronunciation for sentence', () {
      const entry = TranslationEntry(
        id: 'test_sent_1',
        kind: TranslationKind.sentence,
        textOlChiki: 'ᱤᱧ ᱫᱚ ᱠᱟᱹᱢᱤᱭᱮᱫᱟᱹᱧ',
        textLatin: 'In do kamiyedanj',
        englishMeaning: 'I am working',
      );

      expect(entry.meaningFor('bn'), 'আমি কাজ করছি');
      expect(entry.transliterationFor('bn'), 'ইঞ দ কামিয়েদাঞ');
      expect(entry.isTranslatedFor('bn'), isTrue);
    });
  });

  group('MultilingualPreviewBox Widget Tests', () {
    testWidgets('renders Bengali meaning and Ol Chiki script correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MultilingualPreviewBox(
              textOlChiki: 'ᱵᱟᱵᱟ',
              textLatin: 'baba',
              explicitMeaning: 'Father',
              isDark: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Live Learner Preview'), findsOneWidget);
      expect(find.text('বাংলা'), findsWidgets);
      expect(find.text('পিতা'), findsOneWidget);
      expect(find.text('ᱵᱟᱵᱟ'), findsOneWidget);
      expect(find.text('বাবা'), findsOneWidget);
    });
  });
}
