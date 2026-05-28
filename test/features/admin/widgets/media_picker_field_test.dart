import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:itun/core/storage/media_uploader.dart';
import 'package:itun/core/version/build_version_checker.dart';
import 'package:itun/core/version/build_version_status.dart';
import 'package:itun/features/admin/presentation/widgets/media_picker_field.dart';
import 'package:itun/shared/models/content_item.dart';

class MockMediaUploader extends Mock implements MediaUploader {}

void main() {
  late MockMediaUploader mockMediaUploader;

  setUpAll(() {
    registerFallbackValue(const ContentMedia(url: '', fileId: '', kind: ContentMediaKind.image));
  });

  setUp(() {
    mockMediaUploader = MockMediaUploader();
  });

  Widget createTestWidget({
    required List<Override> overrides,
    required ContentMedia? value,
    required ValueChanged<ContentMedia?> onChanged,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: Scaffold(
          body: MediaPickerField(
            label: 'Test Image',
            kind: ContentMediaKind.image,
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('Allows deletion and upload when build version matches', (tester) async {
    ContentMedia? updatedValue;
    var changed = false;

    when(() => mockMediaUploader.delete(any())).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          mediaUploaderProvider.overrideWithValue(mockMediaUploader),
          buildVersionStatusProvider.overrideWith((ref) => Stream.value(const BuildVersionMatch())),
        ],
        value: const ContentMedia(
          url: 'https://example.com/image.png',
          fileId: 'img123',
          kind: ContentMediaKind.image,
        ),
        onChanged: (val) {
          changed = true;
          updatedValue = val;
        },
      ),
    );

    // Wait for stream to emit initial value and settle
    final element = tester.element(find.byType(MediaPickerField));
    final container = ProviderScope.containerOf(element);
    await container.read(buildVersionStatusProvider.future);
    await tester.pump();

    // Initial check
    expect(find.text('Remove'), findsOneWidget);

    // Click remove
    await tester.tap(find.text('Remove'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(changed, isTrue);
    expect(updatedValue, isNull);
    verify(() => mockMediaUploader.delete('img123')).called(1);
  });

  testWidgets('Blocks deletion and shows version mismatch dialog when build version is stale', (tester) async {
    var changed = false;
    when(() => mockMediaUploader.delete(any())).thenAnswer((_) async => const Right(unit));

    await tester.pumpWidget(
      createTestWidget(
        overrides: [
          mediaUploaderProvider.overrideWithValue(mockMediaUploader),
          buildVersionStatusProvider.overrideWith((ref) => Stream.value(const BuildVersionStale('newsha123'))),
        ],
        value: const ContentMedia(
          url: 'https://example.com/image.png',
          fileId: 'img123',
          kind: ContentMediaKind.image,
        ),
        onChanged: (val) {
          changed = true;
        },
      ),
    );

    // Wait for stream to emit initial value and settle
    final element = tester.element(find.byType(MediaPickerField));
    final container = ProviderScope.containerOf(element);
    await container.read(buildVersionStatusProvider.future);
    await tester.pump();

    // Click remove
    await tester.tap(find.text('Remove'));
    await tester.pump(const Duration(milliseconds: 50));

    // Verify dialog appeared
    expect(find.text('Version Mismatch'), findsOneWidget);
    expect(find.textContaining('This page is out of date. Reload before removing or replacing media'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);

    // Verify callback was NOT called
    expect(changed, isFalse);
    verifyNever(() => mockMediaUploader.delete(any()));
  });
}
