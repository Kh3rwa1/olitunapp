import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/lessons/presentation/widgets/bento_category_card.dart';

Widget wrap(Widget child, Size size) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: size.width, height: size.height, child: child),
  ),
);

void main() {
  testWidgets('renders category title, ol chiki subtitle and arrow', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const BentoCategoryCard(
          category: CategoryEntity(
            id: 'cat_numbers',
            titleOlChiki: 'ᱞᱮᱠᱷᱟ',
            titleLatin: 'Numbers',
            iconName: 'numbers',
          ),
          index: 0,
          isDark: false,
        ),
        const Size(200, 200),
      ),
    );

    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('ᱞᱮᱠᱷᱟ'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
  });

  testWidgets('omits ol chiki subtitle when empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BentoCategoryCard(
          category: CategoryEntity(
            id: 'cat_stories',
            titleOlChiki: '',
            titleLatin: 'Stories',
          ),
          index: 1,
          isDark: true,
        ),
        const Size(200, 200),
      ),
    );

    expect(find.text('Stories'), findsOneWidget);
    expect(find.text('ᱞᱮᱠᱷᱟ'), findsNothing);
  });

  testWidgets('falls back to index-driven icon for unknown names', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const BentoCategoryCard(
          category: CategoryEntity(
            id: 'cat_misc',
            titleOlChiki: 'ᱴᱷᱟᱶ',
            titleLatin: 'Misc',
            iconName: 'nope',
          ),
          index: 3,
          isDark: false,
        ),
        const Size(200, 200),
      ),
    );
    // _icons[3 % 6] == Icons.auto_stories_rounded
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
  });

  testWidgets('renders in dark mode without crashing', (tester) async {
    await tester.pumpWidget(
      wrap(
        const BentoCategoryCard(
          category: CategoryEntity(
            id: 'cat_words',
            titleOlChiki: 'ᱟᱹᱲᱤ',
            titleLatin: 'Words',
            iconName: 'words',
          ),
          index: 2,
          isDark: true,
        ),
        const Size(200, 200),
      ),
    );
    expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
