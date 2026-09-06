import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/domain/content_badge_resolver.dart';
import 'package:itun/features/admin/presentation/content/widgets/content_filter_bar.dart';
import 'package:itun/features/admin/presentation/content/widgets/content_list_tile.dart';
import 'package:itun/features/admin/presentation/widgets/admin_data_table.dart';
import 'package:itun/shared/models/content_item.dart';

void main() {
  group('Admin Mobile Responsiveness Tests', () {
    testWidgets(
      'AdminDataTable handles unbounded vertical constraints without RenderFlex error',
      (tester) async {
        final dummyItems = List.generate(
          5,
          (i) => {'id': '$i', 'name': 'Item $i', 'code': 'C$i'},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AdminDataTable<Map<String, String>>(
                  items: dummyItems,
                  searchPredicate: (item, q) => item['name']!.contains(q),
                  columns: [
                    AdminColumn(
                      label: 'ID',
                      cellBuilder: (item) => Text(item['id']!),
                    ),
                    AdminColumn(
                      label: 'Name',
                      cellBuilder: (item) => Text(item['name']!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Item 0'), findsOneWidget);
        expect(find.text('Item 4'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminDataTable renders mobile cards and allows view switching on mobile width',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final dummyItems = [
          {'id': '1', 'name': 'Alpha', 'type': 'Letter'},
          {'id': '2', 'name': 'Beta', 'type': 'Number'},
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdminDataTable<Map<String, String>>(
                items: dummyItems,
                searchPredicate: (item, q) => item['name']!.contains(q),
                columns: [
                  AdminColumn(
                    label: 'Type',
                    cellBuilder: (item) => Text(item['type']!),
                  ),
                  AdminColumn(
                    label: 'Name',
                    cellBuilder: (item) => Text(item['name']!),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsOneWidget);

        // Switch to Table view
        final toggleBtn = find.byTooltip('Switch to Horizontal Table view');
        expect(toggleBtn, findsOneWidget);
        await tester.tap(toggleBtn);
        await tester.pumpAndSettle();

        expect(find.byTooltip('Switch to Card view'), findsOneWidget);
      },
    );

    testWidgets(
      'ContentFilterBar renders full width search on mobile without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: ContentFilterBar(
                  title: 'Lessons',
                  isDark: false,
                  supportsCategory: false,
                  supportsPublished: true,
                  supportsPremium: true,
                  categories: const [],
                  selectedCategoryId: null,
                  publishFilter: 'Published',
                  premiumFilter: 'Premium',
                  onSearchChanged: (_) {},
                  onCategoryChanged: (_) {},
                  onPublishFilterChanged: (_) {},
                  onPremiumFilterChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Published'), findsOneWidget);
        expect(find.text('Premium'), findsOneWidget);
      },
    );

    testWidgets(
      'ContentListTile renders on narrow 360px mobile width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final item = ContentItem(
          id: '123',
          kind: ContentKind.word,
          categoryId: 'basics',
          title: 'Johar',
          titleOlChiki: 'ᱡᱚᱦᱟᱨ',
          subtitle: 'Formal Santali greeting and hello',
          isPublished: true,
          isPremium: true,
          order: 1,
          updatedAt: DateTime(2026),
          blocks: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: ContentListTile(
                  item: item,
                  index: 0,
                  isSelected: false,
                  isDark: false,
                  supportsPublished: true,
                  supportsPremium: true,
                  supportsTags: false,
                  badgeType: ContentBadgeType.words,
                  fallbackIcon: Icons.menu_book,
                  onSelectChanged: (_) {},
                  onTap: () {},
                  onEditMetadata: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Johar'), findsOneWidget);
        expect(find.text('ᱡᱚᱦᱟᱨ'), findsOneWidget);
        expect(find.text('Published'), findsOneWidget);
        expect(find.text('Premium'), findsOneWidget);
      },
    );
  });
}
