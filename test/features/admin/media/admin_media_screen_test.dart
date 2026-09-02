import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/admin/presentation/admin_media_screen.dart';

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
  setUp(() {
    FilePicker.platform = _BrokenFilePicker();
  });

  testWidgets('mounts the media library with mock items and filters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AdminMediaScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Media Library'), findsOneWidget);
    expect(find.byType(AdminMediaScreen), findsOneWidget);
    expect(find.byIcon(Icons.image_rounded), findsWidgets);
  });

  testWidgets('failed upload surfaces an error snackbar without crashing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: AdminMediaScreen())),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final uploadButton = find.byIcon(Icons.cloud_upload_rounded);
    expect(uploadButton, findsWidgets);
    await tester.tap(uploadButton.first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Upload failed: Exception: No picker on test host'),
      findsOneWidget,
    );
  });
}
