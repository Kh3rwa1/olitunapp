import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/storage/upload_service.dart';
import 'package:itun/features/admin/presentation/letters/widgets/letter_media_field.dart';
import 'package:mocktail/mocktail.dart';

class _MockUploadService extends Mock implements AppwriteStorageUploadService {}

class _BrokenFilePicker extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    throw Exception('No picker on test host');
  }
}

void main() {
  late _MockUploadService uploadService;
  String? uploadedUrl;

  setUpAll(() {
    registerFallbackValue(
      PlatformFile(name: 'x', size: 0, bytes: Uint8List.fromList([0])),
    );
  });

  setUp(() {
    uploadService = _MockUploadService();
    uploadedUrl = null;
    FilePicker.platform = _BrokenFilePicker();
  });

  Future<void> pumpField(
    WidgetTester tester, {
    String? currentUrl,
    Widget Function(String url)? previewBuilder,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [uploadServiceProvider.overrideWithValue(uploadService)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              child: LetterMediaField(
                label: 'Letter Audio',
                subtitle: 'MP3 files',
                icon: Icons.audiotrack_rounded,
                accent: const Color(0xFF3B82F6),
                currentUrl: currentUrl,
                uploadFolder: 'audio',
                fileType: FileType.audio,
                onUploaded: (url) => uploadedUrl = url,
                previewBuilder: previewBuilder,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders label, subtitle, and manual URL entry', (tester) async {
    await pumpField(tester);

    expect(find.text('Letter Audio'), findsOneWidget);
    expect(find.text('MP3 files'), findsOneWidget);
    expect(find.text('Upload Letter Audio'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('shows current URL state with checkmark and change hint', (
    tester,
  ) async {
    await pumpField(tester, currentUrl: 'https://example.com/a.mp3');

    expect(find.text('Tap to change'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('https://example.com/a.mp3'), findsOneWidget);
  });

  testWidgets('typing a manual URL reports it via onUploaded', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextField), ' https://cdn/b.webm ');
    await tester.pump();

    expect(uploadedUrl, 'https://cdn/b.webm');
  });

  testWidgets('typing an empty URL reports null via onUploaded', (
    tester,
  ) async {
    await pumpField(tester, currentUrl: 'https://example.com/a.mp3');

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    expect(uploadedUrl, isNull);
  });

  testWidgets('failed file pick surfaces an error snackbar', (tester) async {
    await pumpField(tester);

    await tester.tap(find.text('Upload Letter Audio'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Error: Exception: No picker on test host'),
      findsOneWidget,
    );
  });

  testWidgets('renders custom preview when a URL and builder are given', (
    tester,
  ) async {
    await pumpField(
      tester,
      currentUrl: 'https://example.com/a.mp3',
      previewBuilder: (url) => Text('PREVIEW:$url'),
    );

    expect(find.text('PREVIEW:https://example.com/a.mp3'), findsOneWidget);
  });
}
