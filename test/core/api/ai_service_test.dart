import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/api/ai_service.dart';

void main() {
  group('AiService', () {
    test('throws when TRANSLATE_URL is not configured', () async {
      // The build under `flutter test` does not pass --dart-define values,
      // so AiConfig.translateUrl is empty and the call must fail loudly
      // rather than silently hit a hardcoded host.
      expect(AiConfig.translateUrl, isEmpty);

      final svc = AiService();
      await expectLater(svc.translate('hello'), throwsStateError);
      await expectLater(svc.translateFromOlChiki('ᱚ'), throwsStateError);
    });
  });
}
