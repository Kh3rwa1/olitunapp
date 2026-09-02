import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/hero_category_card.dart';
import 'package:itun/shared/providers/local_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:itun/core/storage/hive_service.dart';

Future<void> pumpCard(
  WidgetTester tester,
  CategoryEntity category, {
  bool reduceEffects = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        reduceVisualEffectsProvider.overrideWithValue(reduceEffects),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 420,
            child: HeroCategoryCard(category: category, isDark: false),
          ),
        ),
      ),
    ),
  );
  // The CTA shimmer animates after a 2s delay; advance the fake clock so no
  // timers are left pending when the test ends.
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  const category = CategoryEntity(
    id: 'cat_numbers',
    titleOlChiki: 'ᱞᱮᱠᱷᱟ',
    titleLatin: 'Numbers',
    iconName: 'numbers',
    gradientPreset: 'peach',
    description: 'Count from one to ten',
    totalLessons: 4,
  );

  testWidgets('renders recommended badge, titles and CTA', (tester) async {
    await pumpCard(tester, category);

    expect(find.text('RECOMMENDED'), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('ᱞᱮᱠᱷᱟ'), findsOneWidget);
    expect(find.text('Count from one to ten'), findsOneWidget);
    expect(find.text('START LEARNING'), findsOneWidget);
    expect(find.byIcon(Icons.calculate_rounded), findsWidgets);
  });

  testWidgets('hides Ol Chiki line and description when absent', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const CategoryEntity(
        id: 'cat_x',
        titleOlChiki: '',
        titleLatin: 'Stories',
        iconName: 'stories',
      ),
    );

    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('START LEARNING'), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
  });

  testWidgets('maps icon names to matching material icons', (tester) async {
    await pumpCard(
      tester,
      const CategoryEntity(
        id: 'cat_words',
        titleOlChiki: 'ᱟᱹᱲᱤ',
        titleLatin: 'Words',
        iconName: 'words',
      ),
    );
    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);

    await pumpCard(
      tester,
      const CategoryEntity(
        id: 'cat_alphabet',
        titleOlChiki: 'ᱪᱤᱠᱤ',
        titleLatin: 'Alphabet',
        iconName: 'alphabet',
      ),
    );
    expect(find.byIcon(Icons.translate_rounded), findsOneWidget);
  });

  testWidgets('falls back to school icon for unknown icon names', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const CategoryEntity(
        id: 'cat_other',
        titleOlChiki: 'ᱴᱷᱟᱶ',
        titleLatin: 'Culture',
        iconName: 'unknown-thing',
      ),
    );
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });
}
