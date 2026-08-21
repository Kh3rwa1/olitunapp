import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/affirmations/data/affirmation_share_service_provider.dart';
import 'package:itun/features/affirmations/domain/affirmation_share_service.dart';
import 'package:itun/features/affirmations/presentation/widgets/affirmation_share_sheet.dart';
import 'package:itun/shared/models/content_models.dart';

class FakeAffirmationShareService implements AffirmationShareService {
  bool shareImageInvoked = false;
  bool shareTextInvoked = false;
  bool downloadInvoked = false;
  bool copyInvoked = false;
  AffirmationShareResult shareImageResult = AffirmationShareResult.shared;

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
    Rect? shareOrigin,
  }) async {
    shareImageInvoked = true;
    return shareImageResult;
  }

  @override
  Future<AffirmationShareResult> shareText({
    required String text,
    required String title,
    String? url,
    Rect? shareOrigin,
  }) async {
    shareTextInvoked = true;
    return AffirmationShareResult.shared;
  }

  @override
  Future<AffirmationShareResult> downloadImage({
    required Uint8List imageBytes,
    required String filename,
  }) async {
    downloadInvoked = true;
    return AffirmationShareResult.downloaded;
  }

  @override
  Future<AffirmationShareResult> copyToClipboard(String text) async {
    copyInvoked = true;
    return AffirmationShareResult.textCopied;
  }
}

// 1x1 transparent PNG bytes for test Image.memory rendering
final transparentPng = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

void main() {
  group('AffirmationShareSheet', () {
    late FakeAffirmationShareService fakeService;

    final affirmation = AffirmationModel(
      id: 'aff_1',
      olChikiText: 'ᱫᱟᱨᱮ ᱜᱮ ᱡᱤᱣᱤ',
      santaliPhonetic: 'Dare ge jiwi',
      englishMeaning: 'Trees are life',
      category: 'nature',
      order: 1,
      publishedAt: '2026-08-21T00:00:00Z',
    );

    setUp(() {
      fakeService = FakeAffirmationShareService();
    });

    testWidgets('renders share actions and handles Share Image tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            affirmationShareServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AffirmationShareSheet(
                affirmation: affirmation,
                imageBytes: transparentPng,
                shareText: 'Dare ge jiwi - Trees are life',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Share Wisdom Card'), findsOneWidget);
      expect(find.text('Share Image'), findsOneWidget);
      expect(find.text('Download PNG'), findsOneWidget);
      expect(find.text('Copy Text'), findsOneWidget);

      await tester.tap(find.text('Share Image'));
      await tester.pumpAndSettle();

      expect(fakeService.shareImageInvoked, isTrue);
    });

    testWidgets('handles Download PNG tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            affirmationShareServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AffirmationShareSheet(
                affirmation: affirmation,
                imageBytes: transparentPng,
                shareText: 'Dare ge jiwi - Trees are life',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Download PNG'));
      await tester.pumpAndSettle();

      expect(fakeService.downloadInvoked, isTrue);
    });

    testWidgets('handles Copy Text tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            affirmationShareServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AffirmationShareSheet(
                affirmation: affirmation,
                imageBytes: transparentPng,
                shareText: 'Dare ge jiwi - Trees are life',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Copy Text'));
      await tester.pumpAndSettle();

      expect(fakeService.copyInvoked, isTrue);
    });

    testWidgets('user cancellation does not show error snackbar', (
      tester,
    ) async {
      fakeService.shareImageResult = AffirmationShareResult.cancelled;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            affirmationShareServiceProvider.overrideWithValue(fakeService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AffirmationShareSheet(
                affirmation: affirmation,
                imageBytes: transparentPng,
                shareText: 'Dare ge jiwi - Trees are life',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Share Image'));
      await tester.pumpAndSettle();

      expect(fakeService.shareImageInvoked, isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
