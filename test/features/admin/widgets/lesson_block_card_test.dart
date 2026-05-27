import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/lessons/content/widgets/lesson_block_card.dart';
import 'package:itun/features/lessons/domain/entities/lesson_entity.dart';
import 'package:itun/features/admin/presentation/widgets/content_type_badge.dart';
import 'package:itun/features/admin/domain/content_badge_resolver.dart';

void main() {
  group('LessonBlockCard Badge Integration Tests', () {
    testWidgets('renders specific badge for audio block', (tester) async {
      const block = LessonBlockEntity(
        type: 'audio',
        textOlChiki: 'ᱴᱮᱥᱴ',
        audioUrl: 'https://example.com/audio.mp3',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LessonBlockCard(
              index: 0,
              block: block,
              isDark: false,
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      // Verify that ContentTypeBadge is rendered
      final badgeFinder = find.byType(ContentTypeBadge);
      expect(badgeFinder, findsOneWidget);

      final badgeWidget = tester.widget<ContentTypeBadge>(badgeFinder);
      expect(badgeWidget.type, equals(ContentBadgeType.audio));
    });

    testWidgets(
      'presentation block falls back to parent lesson tracing badge',
      (tester) async {
        const block = LessonBlockEntity(type: 'text', textOlChiki: 'ᱴᱮᱥᱴ');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LessonBlockCard(
                index: 1,
                block: block,
                isDark: false,
                onEdit: () {},
                onDelete: () {},
                categoryId: 'cat_alphabets',
                categorySlug: 'letters',
              ),
            ),
          ),
        );

        final badgeFinder = find.byType(ContentTypeBadge);
        expect(badgeFinder, findsOneWidget);

        final badgeWidget = tester.widget<ContentTypeBadge>(badgeFinder);
        expect(badgeWidget.type, equals(ContentBadgeType.tracing));
      },
    );
  });
}
