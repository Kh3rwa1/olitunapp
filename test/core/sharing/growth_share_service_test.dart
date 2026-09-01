import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/sharing/growth_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GrowthShareService Unit Tests', () {
    const service = GrowthShareService();

    test('copyTextToClipboard copies text to system clipboard', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (message) async {
            if (message.method == 'Clipboard.setData') {
              return null;
            }
            if (message.method == 'Clipboard.getData') {
              return {'text': 'Test Olitun Share Message'};
            }
            return null;
          });

      final outcome = await service.copyTextToClipboard(
        'Test Olitun Share Message',
      );
      expect(outcome, equals(ShareOutcome.copiedToClipboard));

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      expect(data?.text, equals('Test Olitun Share Message'));
    });
  });
}
