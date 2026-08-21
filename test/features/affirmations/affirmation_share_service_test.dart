import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/affirmations/domain/affirmation_share_service.dart';

class MockAffirmationShareService implements AffirmationShareService {
  bool shareImageCalled = false;
  bool shareTextCalled = false;
  bool downloadImageCalled = false;
  bool copyToClipboardCalled = false;

  Uint8List? lastImageBytes;
  String? lastFilename;
  String? lastText;

  @override
  Future<bool> canShareFiles(Uint8List imageBytes) async => true;

  @override
  Future<bool> canShareText() async => true;

  @override
  Future<AffirmationShareResult> shareImage({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
    dynamic shareOrigin,
  }) async {
    shareImageCalled = true;
    lastImageBytes = imageBytes;
    lastFilename = filename;
    lastText = text;
    return AffirmationShareResult.shared;
  }

  @override
  Future<AffirmationShareResult> shareText({
    required String text,
    required String title,
    String? url,
    dynamic shareOrigin,
  }) async {
    shareTextCalled = true;
    lastText = text;
    return AffirmationShareResult.shared;
  }

  @override
  Future<AffirmationShareResult> downloadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    downloadImageCalled = true;
    lastImageBytes = imageBytes;
    lastFilename = filename;
    return AffirmationShareResult.downloaded;
  }

  @override
  Future<AffirmationShareResult> copyToClipboard(String text) async {
    copyToClipboardCalled = true;
    lastText = text;
    return AffirmationShareResult.textCopied;
  }
}

void main() {
  group('AffirmationShareService Interface', () {
    late MockAffirmationShareService mockService;
    final testBytes = Uint8List.fromList([1, 2, 3, 4]);

    setUp(() {
      mockService = MockAffirmationShareService();
    });

    test('shareImage delivers bytes and returns shared status', () async {
      final res = await mockService.shareImage(
        imageBytes: testBytes,
        filename: 'test_wisdom.png',
        title: 'Today Wisdom',
        text: 'Dare ge jiwi',
      );

      expect(res, AffirmationShareResult.shared);
      expect(mockService.shareImageCalled, isTrue);
      expect(mockService.lastImageBytes, testBytes);
      expect(mockService.lastFilename, 'test_wisdom.png');
    });

    test(
      'downloadImage delivers bytes and returns downloaded status',
      () async {
        final res = await mockService.downloadImage(
          imageBytes: testBytes,
          filename: 'test_download.png',
        );

        expect(res, AffirmationShareResult.downloaded);
        expect(mockService.downloadImageCalled, isTrue);
        expect(mockService.lastFilename, 'test_download.png');
      },
    );

    test(
      'copyToClipboard delivers text and returns textCopied status',
      () async {
        final res = await mockService.copyToClipboard('Trees are life');
        expect(res, AffirmationShareResult.textCopied);
        expect(mockService.copyToClipboardCalled, isTrue);
        expect(mockService.lastText, 'Trees are life');
      },
    );
  });
}
