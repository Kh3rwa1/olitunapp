import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/affirmations/data/affirmation_share_service_web.dart';
import 'package:itun/features/affirmations/data/web_share_adapter.dart';
import 'package:itun/features/affirmations/domain/affirmation_share_service.dart';

class FakeWebShareAdapter implements WebShareAdapter {
  bool supportShare = true;
  bool supportFileShare = true;
  bool supportTextShare = true;

  bool shareFilesInvoked = false;
  bool shareTextInvoked = false;
  bool createBlobUrlInvoked = false;
  bool triggerDownloadInvoked = false;
  bool revokeBlobUrlInvoked = false;
  bool copyToClipboardInvoked = false;

  Exception? shareFilesException;
  Exception? shareTextException;
  Exception? clipboardException;

  String createdBlobUrl = 'blob:https://olitun.app/test-uuid-1234';
  String? lastDownloadedBlobUrl;
  String? lastDownloadedFilename;
  String? lastRevokedBlobUrl;
  String? lastClipboardText;

  @override
  bool isShareSupported() => supportShare;

  @override
  bool canShareFiles(Uint8List imageBytes, String filename) =>
      supportShare && supportFileShare;

  @override
  bool canShareText(String text, String title, [String? url]) =>
      supportShare && supportTextShare;

  @override
  Future<void> shareFiles({
    required Uint8List imageBytes,
    required String filename,
    required String title,
    required String text,
  }) async {
    shareFilesInvoked = true;
    if (shareFilesException != null) throw shareFilesException!;
  }

  @override
  Future<void> shareText({
    required String text,
    required String title,
    String? url,
  }) async {
    shareTextInvoked = true;
    if (shareTextException != null) throw shareTextException!;
  }

  @override
  String createBlobUrl(Uint8List bytes, String mimeType) {
    createBlobUrlInvoked = true;
    return createdBlobUrl;
  }

  @override
  void triggerDownload(String blobUrl, String filename) {
    triggerDownloadInvoked = true;
    lastDownloadedBlobUrl = blobUrl;
    lastDownloadedFilename = filename;
  }

  @override
  void revokeBlobUrl(String blobUrl) {
    revokeBlobUrlInvoked = true;
    lastRevokedBlobUrl = blobUrl;
  }

  @override
  Future<void> copyToClipboard(String text) async {
    copyToClipboardInvoked = true;
    lastClipboardText = text;
    if (clipboardException != null) throw clipboardException!;
  }
}

void main() {
  group('AffirmationShareServiceImpl - Web JS/DOM Boundary Suite', () {
    late FakeWebShareAdapter adapter;
    late AffirmationShareServiceImpl service;
    final testBytes = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
    ]); // PNG signature

    setUp(() {
      adapter = FakeWebShareAdapter();
      service = AffirmationShareServiceImpl(adapter: adapter);
    });

    test('Case 1: Native file share succeeds when supported', () async {
      final result = await service.shareImage(
        imageBytes: testBytes,
        filename: 'wisdom.png',
        title: 'Today Wisdom',
        text: 'Dare ge jiwi',
      );

      expect(result, AffirmationShareResult.shared);
      expect(adapter.shareFilesInvoked, isTrue);
      expect(adapter.triggerDownloadInvoked, isFalse);
    });

    test(
      'Case 2: Fallback to text share when file sharing is unsupported',
      () async {
        adapter.supportFileShare = false;
        adapter.supportTextShare = true;

        final result = await service.shareImage(
          imageBytes: testBytes,
          filename: 'wisdom.png',
          title: 'Today Wisdom',
          text: 'Dare ge jiwi',
        );

        expect(result, AffirmationShareResult.shared);
        expect(adapter.shareFilesInvoked, isFalse);
        expect(adapter.shareTextInvoked, isTrue);
      },
    );

    test(
      'Case 3: Fallback to download when native share is completely unsupported',
      () async {
        adapter.supportShare = false;
        adapter.supportFileShare = false;
        adapter.supportTextShare = false;

        final result = await service.shareImage(
          imageBytes: testBytes,
          filename: 'wisdom.png',
          title: 'Today Wisdom',
          text: 'Dare ge jiwi',
        );

        expect(result, AffirmationShareResult.downloaded);
        expect(adapter.createBlobUrlInvoked, isTrue);
        expect(adapter.triggerDownloadInvoked, isTrue);
        expect(adapter.lastDownloadedFilename, 'wisdom.png');
        expect(adapter.lastDownloadedBlobUrl, adapter.createdBlobUrl);

        // Verify delayed revocation
        await Future.delayed(const Duration(milliseconds: 1600));
        expect(adapter.revokeBlobUrlInvoked, isTrue);
        expect(adapter.lastRevokedBlobUrl, adapter.createdBlobUrl);
      },
    );

    test(
      'Case 4: User cancellation (AbortError) returns cancelled without error',
      () async {
        adapter.shareFilesException = Exception(
          'AbortError: Share cancelled by user',
        );

        final result = await service.shareImage(
          imageBytes: testBytes,
          filename: 'wisdom.png',
          title: 'Today Wisdom',
          text: 'Dare ge jiwi',
        );

        expect(result, AffirmationShareResult.cancelled);
        expect(adapter.triggerDownloadInvoked, isFalse);
      },
    );

    test('Case 5: Fallback to clipboard when text share unsupported', () async {
      adapter.supportShare = false;

      final result = await service.shareText(
        text: 'Dare ge jiwi',
        title: 'Wisdom',
      );

      expect(result, AffirmationShareResult.textCopied);
      expect(adapter.copyToClipboardInvoked, isTrue);
      expect(adapter.lastClipboardText, 'Dare ge jiwi');
    });

    test('Case 6: Clipboard exception returns failed cleanly', () async {
      adapter.supportShare = false;
      adapter.clipboardException = Exception('Clipboard permission denied');

      final result = await service.shareText(
        text: 'Dare ge jiwi',
        title: 'Wisdom',
      );

      expect(result, AffirmationShareResult.failed);
    });
  });
}
