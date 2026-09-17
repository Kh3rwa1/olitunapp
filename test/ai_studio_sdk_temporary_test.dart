import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/auth/appwrite_auth_service.dart';
import 'package:itun/features/ai_studio/data/ai_studio_service.dart';

void main() {
  test('live actual Studio service translation', () async {
    HttpOverrides.global = null;
    final dir = await Directory.systemTemp.createTemp('studio-sdk-check');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (_) async => dir.path);
    final auth = AppwriteAuthService();
    final container = ProviderContainer();
    try {
      await auth.account.createEmailPasswordSession(
        email: Platform.environment['STUDIO_TEST_EMAIL']!,
        password: Platform.environment['STUDIO_TEST_PASSWORD']!,
      );
      final result = await container.read(aiStudioServiceProvider).translate('নমস্কার', 'bn-IN');
      expect(result, isNotEmpty);
      expect(
        result.runes.any((r) => r >= 0x1C50 && r <= 0x1C7F),
        isTrue,
        reason: 'Bengali translation must return Santali in Ol Chiki.',
      );
      final document = Platform.environment['STUDIO_TEST_DOCUMENT'];
      if (document != null) {
        final service = container.read(aiStudioServiceProvider);
        var job = await service.startOcr(
          StudioInput(bytes: await File(document).readAsBytes(), name: 'sample.pdf'),
          'hi-IN',
        );
        expect(job.id, isNotEmpty);
        for (var i = 0; i < 8 && !job.isTerminal; i++) {
          await Future<void>.delayed(const Duration(seconds: 13));
          job = await service.pollOcr(job.id);
        }
        expect(job.status, anyOf('completed', 'partially_completed'));
        expect(job.text.trim(), isNotEmpty);
      }
    } catch (e, stack) {
      fail('Type: ${e.runtimeType}; detail: $e; stack: $stack');
    } finally {
      container.dispose();
      await auth.account.deleteSession(sessionId: 'current');
      // Cookie persistence can finish after session deletion; retry cleanup.
      for (var attempt = 0; attempt < 5 && await dir.exists(); attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        try {
          await dir.delete(recursive: true);
        } on FileSystemException {
          if (attempt == 4) rethrow;
        }
      }
    }
  }, skip: Platform.environment['STUDIO_LIVE_CHECK'] != 'true');
}
