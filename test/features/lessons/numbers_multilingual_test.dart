import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:itun/core/languages/ol_chiki_multilingual_helper.dart';
import 'package:itun/core/languages/providers/target_language_provider.dart';
import 'package:itun/core/storage/hive_service.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/presentation/providers/category_notifier.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/lessons/presentation/lesson_block_detail_screen.dart';
import 'package:itun/features/lessons/presentation/widgets/lesson_content/number_grid_content.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/models/content_models.dart';
import 'package:itun/shared/providers/language_settings_providers.dart';
import 'package:itun/shared/providers/learner_content_providers.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:itun/shared/utils/santali_numbers.dart';

class MockCategoryNotifier extends CategoryNotifier {
  final List<CategoryEntity> _initial;
  MockCategoryNotifier(this._initial);

  @override
  AsyncValue<List<CategoryEntity>> build() => AsyncValue.data(_initial);
  @override
  Future<void> loadCategories() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SantaliNumbers Multilingual Unit Tests', () {
    test('tryParseValue correctly extracts values from numerals and text', () {
      expect(SantaliNumbers.tryParseValue('᱐', '0 – Zero'), 0);
      expect(SantaliNumbers.tryParseValue('᱑', '1 – One'), 1);
      expect(SantaliNumbers.tryParseValue('᱒᱑', '21 – Twenty-One'), 21);
      expect(SantaliNumbers.tryParseValue('᱑᱐᱐', '100 – One Hundred'), 100);
      expect(SantaliNumbers.tryParseValue(null, '50 – Fifty'), 50);
      expect(SantaliNumbers.tryParseValue('᱕᱐', null), 50);
      expect(SantaliNumbers.tryParseValue('ᱡᱚᱦᱟᱨ', 'Johar'), null);
      expect(SantaliNumbers.tryParseValue('abc', 'def'), null);
    });

    test('toNumeral produces expected digits for each language', () {
      expect(SantaliNumbers.toNumeral(1, 'bn'), '১');
      expect(SantaliNumbers.toNumeral(21, 'bn'), '২১');
      expect(SantaliNumbers.toNumeral(1, 'hi'), '१');
      expect(SantaliNumbers.toNumeral(21, 'hi'), '२१');
      expect(SantaliNumbers.toNumeral(1, 'or'), '୧');
      expect(SantaliNumbers.toNumeral(21, 'or'), '୨୧');
      expect(SantaliNumbers.toNumeral(1, 'sat'), '᱑');
      expect(SantaliNumbers.toNumeral(21, 'sat'), '᱒᱑');
      expect(SantaliNumbers.toNumeral(1, 'en'), '1');
      expect(SantaliNumbers.toNumeral(21, 'en'), '21');
    });

    test(
      'pronunciation generates authentic Santali pronunciations across scripts',
      () {
        // 1 (Mit)
        expect(SantaliNumbers.pronunciation(1, 'bn'), 'মিৎ');
        expect(SantaliNumbers.pronunciation(1, 'hi'), 'मित');
        expect(SantaliNumbers.pronunciation(1, 'or'), 'ମିତ୍');
        expect(SantaliNumbers.pronunciation(1, 'en'), 'Mit');
        expect(SantaliNumbers.pronunciation(1, 'sat'), 'ᱢᱤᱫ');

        // 10 (Gel)
        expect(SantaliNumbers.pronunciation(10, 'bn'), 'গেল');
        expect(SantaliNumbers.pronunciation(10, 'hi'), 'गेल');
        expect(SantaliNumbers.pronunciation(10, 'or'), 'ଗେଲ୍');
        expect(SantaliNumbers.pronunciation(10, 'en'), 'Gel');
        expect(SantaliNumbers.pronunciation(10, 'sat'), 'ᱜᱮᱞ');

        // 21 (Isi Mit)
        expect(SantaliNumbers.pronunciation(21, 'bn'), 'ইসি মিৎ');
        expect(SantaliNumbers.pronunciation(21, 'hi'), 'इसी मित');
        expect(SantaliNumbers.pronunciation(21, 'or'), 'ଇସି ମିତ୍');
        expect(SantaliNumbers.pronunciation(21, 'en'), 'Isi Mit');
        expect(SantaliNumbers.pronunciation(21, 'sat'), 'ᱤᱥᱤ ᱢᱤᱫ');

        // 100 (Say)
        expect(SantaliNumbers.pronunciation(100, 'bn'), 'সায়');
        expect(SantaliNumbers.pronunciation(100, 'hi'), 'साय');
        expect(SantaliNumbers.pronunciation(100, 'or'), 'ସାୟ୍');
        expect(SantaliNumbers.pronunciation(100, 'en'), 'Say');
        expect(SantaliNumbers.pronunciation(100, 'sat'), 'ᱥᱟᱭ');
      },
    );

    test('teachingLanguageName formats number name and numeral correctly', () {
      // 1
      expect(SantaliNumbers.teachingLanguageName(1, 'bn'), 'এক (১)');
      expect(SantaliNumbers.teachingLanguageName(1, 'hi'), 'एक (१)');
      expect(SantaliNumbers.teachingLanguageName(1, 'or'), 'ଏକ (୧)');
      expect(SantaliNumbers.teachingLanguageName(1, 'en'), 'One (1)');
      expect(SantaliNumbers.teachingLanguageName(1, 'sat'), 'ᱢᱤᱫ (᱑)');

      // 21
      expect(SantaliNumbers.teachingLanguageName(21, 'bn'), 'একুশ (২১)');
      expect(SantaliNumbers.teachingLanguageName(21, 'hi'), 'इक्कीस (२१)');
      expect(SantaliNumbers.teachingLanguageName(21, 'or'), 'ଏକୋଇଶ (୨୧)');
      expect(SantaliNumbers.teachingLanguageName(21, 'en'), 'Twenty-One (21)');
      expect(SantaliNumbers.teachingLanguageName(21, 'sat'), 'ᱤᱥᱤ ᱢᱤᱫ (᱒᱑)');

      // 100
      expect(SantaliNumbers.teachingLanguageName(100, 'bn'), 'একশো (১০০)');
      expect(SantaliNumbers.teachingLanguageName(100, 'hi'), 'एक सौ (१००)');
      expect(SantaliNumbers.teachingLanguageName(100, 'or'), 'ଏକ ଶହ (୧୦୦)');
      expect(
        SantaliNumbers.teachingLanguageName(100, 'en'),
        'One Hundred (100)',
      );
      expect(SantaliNumbers.teachingLanguageName(100, 'sat'), 'ᱥᱟᱭ (᱑᱐᱐)');
    });
  });

  group('OlChikiMultilingualHelper Number Resolution Tests', () {
    test('resolves complete number display for block 1 in Bengali', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: '᱑',
        textLatin: '1 – One',
        teachingLanguage: 'bn',
        scriptMode: 'both',
      );

      expect(display.title, 'এক (১)');
      expect(display.scriptText, '᱑');
      expect(display.subtitle, 'মিৎ');
      expect(display.ctaText, 'শুনুন');
    });

    test('resolves complete number display for block 1 in Hindi', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: '᱑',
        textLatin: '1 – One',
        teachingLanguage: 'hi',
        scriptMode: 'both',
      );

      expect(display.title, 'एक (१)');
      expect(display.scriptText, '᱑');
      expect(display.subtitle, 'मित');
      expect(display.ctaText, 'सुनें');
    });

    test('resolves complete number display for block 1 in Odia', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: '᱑',
        textLatin: '1 – One',
        teachingLanguage: 'or',
        scriptMode: 'both',
      );

      expect(display.title, 'ଏକ (୧)');
      expect(display.scriptText, '᱑');
      expect(display.subtitle, 'ମିତ୍');
      expect(display.ctaText, 'ଶୁଣନ୍ତୁ');
    });

    test('resolves complete number display for block 1 in English', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: '᱑',
        textLatin: '1 – One',
        teachingLanguage: 'en',
        scriptMode: 'both',
      );

      expect(display.title, 'One (1)');
      expect(display.scriptText, '᱑');
      expect(display.subtitle, 'Mit');
      expect(display.ctaText, 'LISTEN');
    });

    test('resolves complete number display for block 21 in Bengali', () {
      final display = OlChikiMultilingualHelper.resolveBlockDisplay(
        textOlChiki: '᱒᱑',
        textLatin: '21 – Twenty-One',
        teachingLanguage: 'bn',
        scriptMode: 'both',
      );

      expect(display.title, 'একুশ (২১)');
      expect(display.scriptText, '᱒᱑');
      expect(display.subtitle, 'ইসি মিৎ');
      expect(display.ctaText, 'শুনুন');
    });

    test(
      'respects explicit pronunciation and meaning overrides on number blocks across languages',
      () {
        // Bengali override for 20 (Bar gel / 20)
        final displayBn = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: '᱒᱐',
          textLatin: '20 - Bar gel',
          textBengali: '২০',
          explicitMeaning: 'বার গেল',
          teachingLanguage: 'bn',
          scriptMode: 'both',
        );
        expect(displayBn.title, 'বার গেল');
        expect(displayBn.scriptText, '᱒᱐');
        expect(displayBn.subtitle, '২০');
        expect(displayBn.ctaText, 'শুনুন');

        // Hindi override for 20 (Bar gel / 20)
        final displayHi = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: '᱒᱐',
          textLatin: '20 - Bar gel',
          textHindi: '२०',
          explicitMeaning: 'बार गेल',
          teachingLanguage: 'hi',
          scriptMode: 'both',
        );
        expect(displayHi.title, 'बार गेल');
        expect(displayHi.scriptText, '᱒᱐');
        expect(displayHi.subtitle, '२०');
        expect(displayHi.ctaText, 'सुनें');

        // Odia override for 20 (Bar gel / 20)
        final displayOr = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: '᱒᱐',
          textLatin: '20 - Bar gel',
          textOdia: '୨୦',
          explicitMeaning: 'ବାର ଗେଲ୍',
          teachingLanguage: 'or',
          scriptMode: 'both',
        );
        expect(displayOr.title, 'ବାର ଗେଲ୍');
        expect(displayOr.scriptText, '᱒᱐');
        expect(displayOr.subtitle, '୨୦');
        expect(displayOr.ctaText, 'ଶୁଣନ୍ତୁ');

        // English override for 20 (Bar gel)
        final displayEn = OlChikiMultilingualHelper.resolveBlockDisplay(
          textOlChiki: '᱒᱐',
          textLatin: '20 - Bar gel',
          explicitPronunciation: 'Bar gel',
          explicitMeaning: 'Twenty',
          teachingLanguage: 'en',
          scriptMode: 'both',
        );
        expect(displayEn.title, 'Twenty');
        expect(displayEn.scriptText, '᱒᱐');
        expect(displayEn.subtitle, 'Bar gel');
        expect(displayEn.ctaText, 'LISTEN');
      },
    );
  });

  group('LessonBlockDetailScreen Number Rendering Widget Tests', () {
    const numberLesson = LessonEntity(
      id: 'lesson_num_test',
      categoryId: 'cat_numbers',
      titleOlChiki: '᱐-᱙ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 0-9',
      blocks: [
        LessonBlockEntity(type: 'text', textOlChiki: '᱑', textLatin: '1 – One'),
      ],
    );

    const overriddenNumberLesson = LessonEntity(
      id: 'lesson_num_override_test',
      categoryId: 'cat_numbers',
      titleOlChiki: '᱑᱐-᱒᱐ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 10-20',
      blocks: [
        LessonBlockEntity(
          type: 'text',
          textOlChiki: '᱒᱐',
          textLatin: '20 - Bar gel',
          textBengali: '২০',
          data: {'meaning_bn': 'বার গেল'},
        ),
      ],
    );

    testWidgets(
      'renders explicit pronunciation and meaning overrides in LessonBlockDetailScreen',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              learnerLessonsProvider.overrideWith(
                (ref) => const AsyncValue.data([overriddenNumberLesson]),
              ),
              learnerLessonDetailProvider(
                'lesson_num_override_test',
              ).overrideWith((ref) => Future.value(overriddenNumberLesson)),
              effectiveTeachingLanguageProvider.overrideWith((ref) => 'bn'),
              targetLanguageCodeProvider.overrideWith(
                (ref) => TargetLanguageNotifier(),
              ),
              effectiveScriptModeProvider.overrideWith((ref) => 'both'),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LessonBlockDetailScreen(
                lessonId: 'lesson_num_override_test',
                initialBlockIndex: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top title in teaching language uses explicit override
        expect(find.text('বার গেল'), findsOneWidget);
        // Main numeral card
        expect(find.text('᱒᱐'), findsWidgets);
        // Subtitle pronunciation in Bengali script uses explicit override
        expect(find.text('২০'), findsOneWidget);
      },
    );

    testWidgets(
      'renders teaching language title and Santali pronunciation in Bengali',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              learnerLessonsProvider.overrideWith(
                (ref) => const AsyncValue.data([numberLesson]),
              ),
              learnerLessonDetailProvider(
                'lesson_num_test',
              ).overrideWith((ref) => Future.value(numberLesson)),
              effectiveTeachingLanguageProvider.overrideWith((ref) => 'bn'),
              targetLanguageCodeProvider.overrideWith(
                (ref) => TargetLanguageNotifier(),
              ),
              effectiveScriptModeProvider.overrideWith((ref) => 'both'),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LessonBlockDetailScreen(
                lessonId: 'lesson_num_test',
                initialBlockIndex: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top title in teaching language
        expect(find.text('এক (১)'), findsOneWidget);
        // Main numeral card
        expect(find.text('᱑'), findsWidgets);
        // Subtitle pronunciation in Bengali script
        expect(find.text('মিৎ'), findsOneWidget);
      },
    );

    testWidgets(
      'renders teaching language title and Santali pronunciation in Odia',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              learnerLessonsProvider.overrideWith(
                (ref) => const AsyncValue.data([numberLesson]),
              ),
              learnerLessonDetailProvider(
                'lesson_num_test',
              ).overrideWith((ref) => Future.value(numberLesson)),
              effectiveTeachingLanguageProvider.overrideWith((ref) => 'or'),
              targetLanguageCodeProvider.overrideWith(
                (ref) => TargetLanguageNotifier(),
              ),
              effectiveScriptModeProvider.overrideWith((ref) => 'both'),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LessonBlockDetailScreen(
                lessonId: 'lesson_num_test',
                initialBlockIndex: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top title in teaching language
        expect(find.text('ଏକ (୧)'), findsOneWidget);
        // Main numeral card
        expect(find.text('᱑'), findsWidgets);
        // Subtitle pronunciation in Odia script
        expect(find.text('ମିତ୍'), findsOneWidget);
      },
    );

    testWidgets(
      'renders teaching language title and Santali pronunciation in Hindi',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              learnerLessonsProvider.overrideWith(
                (ref) => const AsyncValue.data([numberLesson]),
              ),
              learnerLessonDetailProvider(
                'lesson_num_test',
              ).overrideWith((ref) => Future.value(numberLesson)),
              effectiveTeachingLanguageProvider.overrideWith((ref) => 'hi'),
              targetLanguageCodeProvider.overrideWith(
                (ref) => TargetLanguageNotifier(),
              ),
              effectiveScriptModeProvider.overrideWith((ref) => 'both'),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: LessonBlockDetailScreen(
                lessonId: 'lesson_num_test',
                initialBlockIndex: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Top title in teaching language
        expect(find.text('एक (१)'), findsOneWidget);
        // Main numeral card
        expect(find.text('᱑'), findsWidgets);
        // Subtitle pronunciation in Devanagari script
        expect(find.text('मित'), findsOneWidget);
      },
    );
  });

  group('NumberGridContent Widget Tests', () {
    final mockNumbers = [
      NumberModel(
        id: 'n_1',
        numeral: '᱑',
        value: 1,
        nameOlChiki: 'ᱢᱤᱫ',
        nameLatin: 'Mit',
      ),
    ];

    const lessonWithNumber = LessonEntity(
      id: 'lesson_with_num',
      categoryId: 'cat_numbers',
      titleOlChiki: '᱐-᱙ ᱮᱞᱠᱷᱟ',
      titleLatin: 'Numbers 0-9',
      blocks: [
        LessonBlockEntity(type: 'text', textOlChiki: '᱑', textLatin: '1 – One'),
      ],
    );

    testWidgets(
      'displays localized number name and pronunciation in Bengali mode',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              learnerNumbersProvider.overrideWith(
                (ref) => AsyncValue.data(mockNumbers),
              ),
              learnerLessonsProvider.overrideWith(
                (ref) => const AsyncValue.data([lessonWithNumber]),
              ),
              effectiveTeachingLanguageProvider.overrideWith((ref) => 'bn'),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: NumberGridContent(lessonId: 'lesson_with_num'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('᱑'), findsOneWidget);
        expect(find.text('এক (১)'), findsOneWidget);
        expect(find.text('মিৎ'), findsOneWidget);
        expect(find.text('ᱢᱤᱫ'), findsOneWidget);
      },
    );
  });
}
