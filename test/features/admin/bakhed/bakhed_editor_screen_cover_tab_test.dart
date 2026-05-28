import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/features/admin/presentation/bakhed/bakhed_editor_screen.dart';
import 'package:itun/shared/models/content_item.dart';
import 'package:itun/features/admin/data/bakhed_repository.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/api/appwrite_db_service.dart';
import 'package:itun/features/admin/presentation/widgets/media_picker_field.dart';
import 'package:itun/shared/providers/rhymes_providers.dart';
import 'package:itun/core/version/build_version_checker.dart';
import 'package:itun/core/version/build_version_status.dart';

class MockBakhedRepository extends Mock implements BakhedRepository {}

class MockAppwriteDbService extends Mock implements AppwriteDbService {}

class MockMediaUploader extends Mock implements MediaUploader {}

class FakeContentItem extends Fake implements ContentItem {}

void main() {
  late MockBakhedRepository mockRepository;
  late MockAppwriteDbService mockDbService;
  late MockMediaUploader mockMediaUploader;

  setUpAll(() {
    registerFallbackValue(FakeContentItem());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRepository = MockBakhedRepository();
    mockDbService = MockAppwriteDbService();
    mockMediaUploader = MockMediaUploader();
  });

  Widget createTestWidget({
    required String bakhedId,
    required List<Override> overrides,
  }) {
    return ProviderScope(
      overrides: [
        ...overrides,
        rhymeCategoriesProvider.overrideWith(
          (ref) => const AsyncValue.data([]),
        ),
        buildVersionStatusProvider.overrideWith(
          (ref) => Stream.value(const BuildVersionMatch()),
        ),
      ],
      child: MaterialApp(home: BakhedEditorScreen(bakhedId: bakhedId)),
    );
  }

  group('BakhedEditorScreen Cover Tab Switcher Widget Tests', () {
    testWidgets(
      '1. Reconciles _selectedCoverTab selection from async loaded item coverMediaType',
      (tester) async {
        final rhyme = ContentItem(
          id: 'rhyme_1',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          title: 'Video Cover Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
          coverMediaType: 'video',
          heroMedia: const ContentMedia(
            url: 'https://example.com/video.mp4',
            fileId: 'vid123',
            kind: ContentMediaKind.video,
          ),
        );

        when(
          () => mockRepository.get('rhyme_1'),
        ).thenAnswer((_) async => right(rhyme));

        await tester.pumpWidget(
          createTestWidget(
            bakhedId: 'rhyme_1',
            overrides: [
              bakhedRepositoryProvider.overrideWithValue(mockRepository),
              appwriteDbServiceProvider.overrideWithValue(mockDbService),
              mediaUploaderProvider.overrideWithValue(mockMediaUploader),
            ],
          ),
        );

        // Let notifier load the state
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find the SegmentedButton
        final segmentedButtonFinder = find.byType(SegmentedButton<int>);
        expect(segmentedButtonFinder, findsOneWidget);

        final SegmentedButton<int> segmentedButton = tester.widget(
          segmentedButtonFinder,
        );
        expect(
          segmentedButton.selected,
          contains(1),
        ); // Video tab selected because coverMediaType is 'video'

        // Check that Cover Video Loop picker is displayed instead of Cover Image picker
        expect(find.text('Cover Video Loop (Autoplay)'), findsOneWidget);
        expect(find.text('Cover Image (Thumbnail)'), findsNothing);
      },
    );

    testWidgets(
      '2. Switch tab immediately without dialog if heroMedia is empty/null',
      (tester) async {
        final rhyme = ContentItem(
          id: 'rhyme_empty',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          title: 'Empty Cover Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
        );

        when(
          () => mockRepository.get('rhyme_empty'),
        ).thenAnswer((_) async => right(rhyme));

        await tester.pumpWidget(
          createTestWidget(
            bakhedId: 'rhyme_empty',
            overrides: [
              bakhedRepositoryProvider.overrideWithValue(mockRepository),
              appwriteDbServiceProvider.overrideWithValue(mockDbService),
              mediaUploaderProvider.overrideWithValue(mockMediaUploader),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initially Image tab (0) is selected
        SegmentedButton<int> segmentedButton = tester.widget(
          find.byType(SegmentedButton<int>),
        );
        expect(segmentedButton.selected, contains(0));
        expect(find.text('Cover Image (Thumbnail)'), findsOneWidget);

        // Tap on Video tab
        await tester.tap(find.text('Video Loop Cover'));
        await tester.pump(const Duration(milliseconds: 100));

        // Should switch instantly without dialog
        segmentedButton = tester.widget(find.byType(SegmentedButton<int>));
        expect(segmentedButton.selected, contains(1));
        expect(find.text('Cover Video Loop (Autoplay)'), findsOneWidget);
        expect(
          find.text('Change Cover Media Type?'),
          findsNothing,
        ); // Dialog not shown
      },
    );

    testWidgets(
      '3. Switching tab with active cover shows dialog, cancels on Cancel, switches and clears cover on Confirm',
      (tester) async {
        final rhyme = ContentItem(
          id: 'rhyme_active',
          kind: ContentKind.rhyme,
          categoryId: 'cat_sohrai',
          title: 'Active Cover Rhyme',
          blocks: const [],
          updatedAt: DateTime(2026),
          coverMediaType: 'image',
          heroMedia: const ContentMedia(
            url: 'https://example.com/image.png',
            fileId: 'img123',
            kind: ContentMediaKind.image,
          ),
        );

        when(
          () => mockRepository.get('rhyme_active'),
        ).thenAnswer((_) async => right(rhyme));

        await tester.pumpWidget(
          createTestWidget(
            bakhedId: 'rhyme_active',
            overrides: [
              bakhedRepositoryProvider.overrideWithValue(mockRepository),
              appwriteDbServiceProvider.overrideWithValue(mockDbService),
              mediaUploaderProvider.overrideWithValue(mockMediaUploader),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initially Image tab (0) is selected
        SegmentedButton<int> segmentedButton = tester.widget(
          find.byType(SegmentedButton<int>),
        );
        expect(segmentedButton.selected, contains(0));
        expect(find.text('Cover Image (Thumbnail)'), findsOneWidget);

        // Tap on Video tab
        await tester.tap(find.text('Video Loop Cover'));
        await tester.pump(); // Show dialog

        // Verify confirmation dialog is visible
        expect(find.text('Change Cover Media Type?'), findsOneWidget);
        expect(
          find.text(
            'Switching to a video cover will permanently delete your existing image cover. Are you sure you want to continue?',
          ),
          findsOneWidget,
        );

        // Case A: Click Cancel
        await tester.tap(find.text('Cancel'));
        await tester.pump(const Duration(milliseconds: 100));

        // Dialog closed, tab selection reverted to Image (0)
        expect(find.text('Change Cover Media Type?'), findsNothing);
        segmentedButton = tester.widget(find.byType(SegmentedButton<int>));
        expect(segmentedButton.selected, contains(0));
        expect(find.text('Cover Image (Thumbnail)'), findsOneWidget);

        // Tap on Video tab again
        await tester.tap(find.text('Video Loop Cover'));
        await tester.pump(); // Show dialog

        // Case B: Click Confirm
        await tester.tap(find.text('Confirm'));
        await tester.pump(const Duration(milliseconds: 100));

        // Dialog closed, tab selection switched to Video (1) and cover cleared
        expect(find.text('Change Cover Media Type?'), findsNothing);
        segmentedButton = tester.widget(find.byType(SegmentedButton<int>));
        expect(segmentedButton.selected, contains(1));
        expect(find.text('Cover Video Loop (Autoplay)'), findsOneWidget);

        // Verify that notifier state shows heroMedia and coverMediaType cleared (value field in MediaPickerField is null)
        final MediaPickerField picker = tester.widget(
          find.byType(MediaPickerField),
        );
        expect(picker.value, isNull);
      },
    );
  });
}
