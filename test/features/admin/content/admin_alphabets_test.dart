import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:itun/core/error/failures.dart';
import 'package:itun/features/admin/presentation/content/admin_content_list_screen.dart';
import 'package:itun/features/admin/presentation/categories/widgets/category_card.dart';
import 'package:itun/features/admin/presentation/widgets/content_form.dart';
import 'package:itun/features/categories/data/models/category_model.dart';
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
    registerFallbackValue(ContentKind.letter);
  });

  group('35 Alphabets Admin Content Tests', () {
    testWidgets(
      'AdminContentListScreen for ContentKind.letter displays 35 Alphabets header and Add Alphabet FAB',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockRepo = MockContentRepository();
        final letter = ContentItem(
          id: 'l_la',
          kind: ContentKind.letter,
          categoryId: 'letters',
          title: 'La (a)',
          titleOlChiki: 'ᱚ',
          olChiki: 'ᱚ',
          subtitle: 'Ol',
          blocks: const [],
          updatedAt: DateTime.now(),
        );

        when(
          () => mockRepo.list(
            ContentKind.letter,
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => Right([letter]));

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
                body: AdminContentListScreen(kind: ContentKind.letter),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check header title and eyebrow
        expect(find.text('35 Alphabets'), findsOneWidget);
        expect(find.text('CONTENT · 35 ALPHABETS'), findsOneWidget);
        expect(
          find.text(
            'Manage the 35 Ol Chiki alphabet characters, pronunciation, audio, and tracing',
          ),
          findsOneWidget,
        );

        // Check FAB label
        expect(find.text('Add Alphabet'), findsOneWidget);

        // Check letter item rendered
        expect(find.text('La (a)'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminContentListScreen for ContentKind.lesson with Alphabets category displays discovery banner',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final mockRepo = MockContentRepository();
        const alphabetsCategory = CategoryEntity(
          id: 'cat_alphabets_test',
          titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
          titleLatin: 'Alphabets',
          iconName: 'alphabet',
        );

        when(
          () => mockRepo.list(
            ContentKind.lesson,
            categoryId: any(named: 'categoryId'),
          ),
        ).thenAnswer((_) async => const Right([]));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository([alphabetsCategory]),
              ),
              contentRepositoryProvider.overrideWithValue(mockRepo),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AdminContentListScreen(
                  kind: ContentKind.lesson,
                  categoryId: 'cat_alphabets_test',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check discovery banner
        expect(
          find.text(
            'Looking for the 35 Ol Chiki Alphabets? Alphabets with audio, pronunciation, and stroke tracing are managed in the 35 Alphabets Database.',
          ),
          findsOneWidget,
        );
        expect(find.text('Manage 35 Alphabets'), findsOneWidget);
      },
    );

    testWidgets(
      'ContentForm for ContentKind.letter auto-initializes tracing and renders letter-specific form fields',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 4000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        ContentItem? savedItem;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              categoryRepositoryProvider.overrideWithValue(
                FakeCategoryRepository(),
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: ContentForm(
                  kind: ContentKind.letter,
                  onSubmit: (item) async {
                    savedItem = item;
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check letter-specific field labels
        expect(
          find.text('Transliteration Latin (e.g. La (a))*'),
          findsOneWidget,
        );
        expect(find.text('Ol Chiki Character Glyph (e.g. ᱚ)*'), findsOneWidget);
        expect(find.text('Example Word (e.g. Ol)'), findsOneWidget);
        expect(find.text('Alphabet Index (1-35)*'), findsOneWidget);

        // Fill in letter fields
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Transliteration Latin (e.g. La (a))*',
          ),
          'At (t)',
        );
        await tester.enterText(
          find.widgetWithText(
            TextFormField,
            'Ol Chiki Character Glyph (e.g. ᱚ)*',
          ),
          'ᱛ',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Example Word (e.g. Ol)'),
          'At',
        );

        // Scroll down to Save button and tap
        await tester.ensureVisible(find.text('Save Content'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save Content'));
        await tester.pumpAndSettle();

        // Verify savedItem was populated and tracing was auto-initialized
        expect(savedItem, isNotNull);
        expect(savedItem!.title, 'At (t)');
        expect(savedItem!.olChiki, 'ᱛ');
        expect(savedItem!.subtitle, 'At');
        expect(savedItem!.tracing, isNotNull);
      },
    );

    test(
      'ContentItem.fromJson deserializes exampleWord into subtitle for letter kind',
      () {
        final item = ContentItem.fromJson(
          {
            'id': 'l_la',
            'charOlChiki': 'ᱚ',
            'transliterationLatin': 'La (a)',
            'order': 0,
            'isActive': true,
            'exampleWord': 'Ol',
          },
          null,
          ContentKind.letter,
        );

        expect(item.id, 'l_la');
        expect(item.title, 'La (a)');
        expect(item.olChiki, 'ᱚ');
        expect(item.subtitle, 'Ol');
      },
    );

    testWidgets(
      'CategoryCard navigates to /admin/letters when category is Alphabets',
      (tester) async {
        String? navigatedLocation;

        final router = GoRouter(
          initialLocation: '/admin/categories',
          routes: [
            GoRoute(
              path: '/admin/categories',
              builder: (context, state) => Scaffold(
                body: CategoryCard(
                  category: const CategoryModel(
                    id: 'cat_alphabets_test',
                    titleOlChiki: 'ᱚᱞ ᱪᱤᱠᱤ',
                    titleLatin: 'Alphabets',
                    iconName: 'alphabet',
                  ),
                  index: 0,
                  isDark: false,
                  onEdit: () {},
                  onDelete: () {},
                ),
              ),
            ),
            GoRoute(
              path: '/admin/letters',
              builder: (context, state) {
                navigatedLocation = '/admin/letters';
                return const Scaffold(body: Text('Letters Screen'));
              },
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        );

        await tester.pumpAndSettle();

        // Tap the category card
        await tester.tap(find.byType(CategoryCard));
        await tester.pumpAndSettle();

        expect(navigatedLocation, '/admin/letters');
      },
    );
  });
}
