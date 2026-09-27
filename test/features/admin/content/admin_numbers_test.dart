import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/admin/presentation/content/widgets/number_discovery_banner.dart';
import 'package:itun/features/admin/presentation/categories/widgets/category_card.dart';
import 'package:itun/features/admin/presentation/widgets/content_form/ol_chiki_number_helper.dart';
import 'package:itun/features/categories/domain/entities/category_entity.dart';
import 'package:itun/features/categories/domain/repositories/category_repository.dart';
import 'package:itun/l10n/generated/app_localizations.dart';
import 'package:itun/shared/providers/providers.dart';

class MockContentRepository extends Mock implements ContentRepository {}

class FakeCategoryRepository implements CategoryRepository {
  final List<CategoryEntity> _categories;
  FakeCategoryRepository([this._categories = const []]);

  @override
  Future<Either<Failure, void>> createCategory(CategoryEntity category) async =>
      const Right(null);

  @override
  Future<Either<Failure, void>> deleteCategory(String id) async =>
      const Right(null);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async =>
      Right(_categories);

  @override
  Future<Either<Failure, CategoryEntity>> getCategoryById(String id) async =>
      Right(_categories.firstWhere((c) => c.id == id));

  @override
  Future<Either<Failure, void>> updateCategory(CategoryEntity category) async =>
      const Right(null);
}

void main() {
  setUpAll(() {
    registerFallbackValue(ContentKind.number);
  });

  group('100 Numbers Admin Content Tests', () {
    testWidgets(
      'AdminContentListScreen for ContentKind.number displays 100 Numbers header and Add Number FAB',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockRepo = MockContentRepository();
        final numberItem = ContentItem(
          id: 'n_20',
          kind: ContentKind.number,
          categoryId: 'numbers',
          title: 'Bar Gel',
          titleOlChiki: 'ᱵᱟᱨ ᱜᱮᱞ',
          olChiki: '᱒᱐',
          subtitle: 'Twenty',
          order: 20,
          blocks: const [],
          updatedAt: DateTime.now(),
        );

        when(
          () => mockRepo.list(
            ContentKind.number,
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => Right([numberItem]));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository(),
              ),
              contentRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AdminContentListScreen(kind: ContentKind.number),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check header title and eyebrow
        expect(find.text('100 Numbers'), findsOneWidget);
        expect(find.text('CONTENT · 100 NUMBERS'), findsOneWidget);
        expect(find.text('Add Number'), findsOneWidget);
        // Check grid card with 20 numeral and Bar Gel name
        expect(find.text('᱒᱐'), findsOneWidget);
        expect(find.text('Bar Gel'), findsOneWidget);
      },
    );

    testWidgets(
      'NumberDiscoveryBanner identifies numbers category and renders',
      (tester) async {
        const numbersCat = CategoryEntity(
          id: 'cat_numbers',
          titleLatin: 'Numbers',
          titleOlChiki: 'ᱮᱞᱠᱷᱟ',
          description: 'Learn Santali counting',
          iconName: 'numbers',
          order: 2,
        );

        expect(
          NumberDiscoveryBanner.isNumberCategory('cat_numbers', [numbersCat]),
          isTrue,
        );
        expect(
          NumberDiscoveryBanner.isNumberCategory('cat_letters', [numbersCat]),
          isFalse,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: NumberDiscoveryBanner(isDark: false, isWideScreen: true),
            ),
          ),
        );

        expect(
          find.textContaining('Looking for the 100 Ol Chiki Numbers'),
          findsOneWidget,
        );
        expect(find.text('Manage 100 Numbers'), findsOneWidget);
      },
    );

    testWidgets('CategoryCard routes numbers category to /admin/numbers', (
      tester,
    ) async {
      const category = CategoryEntity(
        id: 'cat_numbers',
        titleLatin: 'Numbers',
        titleOlChiki: 'ᱮᱞᱠᱷᱟ',
        description: 'Learn counting',
        iconName: 'numbers',
        order: 2,
      );

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/admin/categories',
        routes: [
          GoRoute(
            path: '/admin/categories',
            builder: (context, state) => Scaffold(
              body: CategoryCard(
                category: category,
                index: 0,
                isDark: false,
                onEdit: () {},
                onDelete: () {},
              ),
            ),
          ),
          GoRoute(
            path: '/admin/numbers',
            builder: (context, state) {
              pushedRoute = '/admin/numbers';
              return const Scaffold(body: Text('100 Numbers Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            categoryRepositoryProvider.overrideWithValue(
              FakeCategoryRepository([category]),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on CategoryCard
      await tester.tap(find.text('Numbers'));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/admin/numbers');
      expect(find.text('100 Numbers Page'), findsOneWidget);
    });

    testWidgets('OlChikiNumberHelper pre-fills Bar Gel and 20 for preset 20', (
      tester,
    ) async {
      final titleCtrl = TextEditingController();
      final titleOlChikiCtrl = TextEditingController();
      final subtitleCtrl = TextEditingController();
      final olChikiCtrl = TextEditingController();
      final orderCtrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OlChikiNumberHelper(
              isDark: false,
              titleController: titleCtrl,
              titleOlChikiController: titleOlChikiCtrl,
              subtitleController: subtitleCtrl,
              olChikiController: olChikiCtrl,
              orderController: orderCtrl,
            ),
          ),
        ),
      );

      // Find chip for 20
      final chip20 = find.text('20 (᱒᱐ - Bar Gel)');
      expect(chip20, findsOneWidget);

      await tester.tap(chip20);
      await tester.pumpAndSettle();

      expect(orderCtrl.text, '20');
      expect(olChikiCtrl.text, '᱒᱐');
      expect(titleCtrl.text, 'Bar Gel');
      expect(titleOlChikiCtrl.text, 'ᱵᱟᱨ ᱜᱮᱞ');
      expect(subtitleCtrl.text, 'Twenty');
    });
  });
}
