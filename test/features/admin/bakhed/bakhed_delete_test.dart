import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/features/admin/presentation/bakhed/bakhed_hub_screen.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/features/rhymes/domain/rhyme_category_model.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';
import 'package:itun/shared/providers/bakhed_content_provider.dart';
import 'package:itun/shared/repositories/content_repository.dart';
import 'package:itun/core/error/failures.dart';

class MockBakhedRepository extends Mock implements BakhedRepository {}

void main() {
  group('BakhedHubScreen Delete Flow tests', () {
    late MockBakhedRepository mockRepo;
    late ContentItem smallRhyme;
    late ContentItem largeRhyme;

    setUp(() {
      mockRepo = MockBakhedRepository();

      smallRhyme = ContentItem(
        id: 'rhyme_small',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        category: 'Sohrai',
        title: 'Small Rhyme',
        blocks: const [],
        updatedAt: DateTime(2026),
      );

      largeRhyme = ContentItem(
        id: 'rhyme_large',
        kind: ContentKind.rhyme,
        categoryId: 'cat_sohrai',
        category: 'Sohrai',
        title: 'Large Rhyme',
        blocks: const [],
        updatedAt: DateTime(2026),
      );
    });

    Widget buildTestWidget(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Navigator(onGenerateRoute: _onGenerateRoute)),
        ),
      );
    }

    ProviderContainer createContainer({required List<ContentItem> rhymes}) {
      return ProviderContainer(
        overrides: [
          contentListProvider((
            ContentKind.rhyme,
            null,
          )).overrideWith((ref) => rhymes),
          rhymeCategoriesProvider.overrideWith(
            (ref) => AsyncValue.data([
              RhymeCategoryModel(
                id: 'Sohrai',
                nameOlChiki: 'Sohrai',
                nameLatin: 'Sohrai',
                iconName: 'auto_awesome',
                order: 0,
              ),
            ]),
          ),
          bakhedRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    }

    // Test 1: Race condition regression test
    testWidgets(
      'Race condition regression test: synchronous DB response does not pop parent route',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = createContainer(rhymes: [smallRhyme]);

        // Resolves synchronously (instant response)
        when(
          () => mockRepo.getLyrics(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getVocabulary(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getCulturalNotes(any()),
        ).thenAnswer((_) async => right(const []));

        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        final deleteBtn = find.byIcon(Icons.delete_outline_rounded);
        expect(deleteBtn, findsOneWidget);

        // Tap delete - triggers _confirmDelete
        await tester.tap(deleteBtn);

        // Pump once: should start showDialog and instantly execute the sync count fetches
        // Since we fixed the pop race condition by capturing dialogContext, it should not pop BakhedHubScreen.
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify BakhedHubScreen is STILL in the widget tree
        expect(find.byType(BakhedHubScreen), findsOneWidget);
        // Verify the confirmation dialog is visible
        expect(
          find.textContaining('Are you sure you want to permanently delete'),
          findsOneWidget,
        );
      },
    );

    // Test 2: TextEditingController persistence
    testWidgets(
      'TextEditingController persistence: does not lose state on rebuild',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = createContainer(rhymes: [largeRhyme]);

        // Return high subcollection counts (>20 total) to trigger the "DELETE" gate
        when(() => mockRepo.getLyrics(any())).thenAnswer(
          (_) async => right(
            List.generate(
              10,
              (_) => const BakhedLyricLine(
                id: '',
                lineIndex: 0,
                startMs: 0,
                endMs: 0,
                olChiki: '',
                latin: '',
                meaning: '',
              ),
            ),
          ),
        );
        when(() => mockRepo.getVocabulary(any())).thenAnswer(
          (_) async => right(
            List.generate(
              10,
              (_) => const BakhedVocabularyItem(
                id: '',
                olChiki: '',
                latin: '',
                meaning: '',
                audioFileId: '',
                sortOrder: 0,
              ),
            ),
          ),
        );
        when(() => mockRepo.getCulturalNotes(any())).thenAnswer(
          (_) async => right(
            List.generate(
              5,
              (_) => const BakhedCulturalNote(
                noteId: '',
                title: '',
                body: '',
                source: '',
              ),
            ),
          ),
        );

        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify we see the DELETE instruction text
        expect(
          find.textContaining('Please type DELETE to confirm'),
          findsOneWidget,
        );

        // Enter "DEL" into the text field
        final textField = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'DEL');
        await tester.pump();

        // Trigger a rebuild (e.g. media query/screen size change)
        tester.view.physicalSize = const Size(1400, 900);
        await tester.pumpAndSettle();

        // Verify the text "DEL" is still in the text field (persistence)
        final TextField fieldWidget = tester.widget(textField);
        expect(fieldWidget.controller?.text, 'DEL');
      },
    );

    // Test 3: Controller disposal
    testWidgets(
      'Controller disposal: verifies text controller is disposed when dialog closes',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = createContainer(rhymes: [largeRhyme]);

        when(() => mockRepo.getLyrics(any())).thenAnswer(
          (_) async => right(
            List.generate(
              10,
              (_) => const BakhedLyricLine(
                id: '',
                lineIndex: 0,
                startMs: 0,
                endMs: 0,
                olChiki: '',
                latin: '',
                meaning: '',
              ),
            ),
          ),
        );
        when(() => mockRepo.getVocabulary(any())).thenAnswer(
          (_) async => right(
            List.generate(
              10,
              (_) => const BakhedVocabularyItem(
                id: '',
                olChiki: '',
                latin: '',
                meaning: '',
                audioFileId: '',
                sortOrder: 0,
              ),
            ),
          ),
        );
        when(() => mockRepo.getCulturalNotes(any())).thenAnswer(
          (_) async => right(
            List.generate(
              5,
              (_) => const BakhedCulturalNote(
                noteId: '',
                title: '',
                body: '',
                source: '',
              ),
            ),
          ),
        );

        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        // Find the private confirmation dialog's state dynamically to get controller reference
        final element = tester.element(
          find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_DeleteConfirmationDialog',
          ),
        );
        final state = (element as StatefulElement).state as dynamic;
        final controller = state.textController as TextEditingController;

        // Verify it is currently active and not disposed
        expect(() => controller.addListener(() {}), returnsNormally);

        // Dismiss the dialog by tapping Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify that the controller has been disposed (calling addListener throws AssertionError)
        expect(
          () => controller.addListener(() {}),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    // Test 4: Cancel path
    testWidgets(
      'Cancel path: tapping Cancel closes dialog and does not trigger repo delete',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = createContainer(rhymes: [smallRhyme]);

        when(
          () => mockRepo.getLyrics(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getVocabulary(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getCulturalNotes(any()),
        ).thenAnswer((_) async => right(const []));

        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        // Tap Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Verify dialog is gone
        expect(find.byType(AlertDialog), findsNothing);
        // Verify delete was NEVER called
        verifyNever(() => mockRepo.delete(any()));
      },
    );

    // Test 5: Delete success path
    testWidgets(
      'Delete success path: confirmation calls delete, shows snackbar, and invalidates provider',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = createContainer(rhymes: [smallRhyme]);

        when(
          () => mockRepo.getLyrics(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getVocabulary(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getCulturalNotes(any()),
        ).thenAnswer((_) async => right(const []));
        when(() => mockRepo.delete(any())).thenAnswer((_) async => right(unit));

        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        // Tap Delete
        final deleteConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        );
        await tester.tap(deleteConfirmBtn);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify delete called once
        verify(() => mockRepo.delete('rhyme_small')).called(1);

        // Verify success snackbar is shown
        expect(find.textContaining('deleted successfully'), findsOneWidget);
        // Verify BakhedHubScreen remains mounted
        expect(find.byType(BakhedHubScreen), findsOneWidget);
      },
    );

    // Test 6: Delete failure path
    testWidgets(
      'Delete failure path: confirmation handles delete error, shows failure snackbar, and screen stays mounted',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = createContainer(rhymes: [smallRhyme]);

        when(
          () => mockRepo.getLyrics(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getVocabulary(any()),
        ).thenAnswer((_) async => right(const []));
        when(
          () => mockRepo.getCulturalNotes(any()),
        ).thenAnswer((_) async => right(const []));
        when(() => mockRepo.delete(any())).thenAnswer(
          (_) async =>
              left(const ServerFailure(message: 'Database connection failed')),
        );

        await tester.pumpWidget(buildTestWidget(container));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pump();
        await tester.pumpAndSettle();

        // Tap Delete
        final deleteConfirmBtn = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        );
        await tester.tap(deleteConfirmBtn);
        await tester.pump();
        await tester.pumpAndSettle();

        // Verify delete called once
        verify(() => mockRepo.delete('rhyme_small')).called(1);

        // Verify failure snackbar is shown
        expect(
          find.textContaining('Delete failed: Database connection failed'),
          findsOneWidget,
        );
        // Verify BakhedHubScreen remains mounted
        expect(find.byType(BakhedHubScreen), findsOneWidget);
      },
    );
  });
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  return MaterialPageRoute(
    builder: (context) => const BakhedHubScreen(),
    settings: settings,
  );
}
