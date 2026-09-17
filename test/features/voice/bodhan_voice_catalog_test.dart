import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/voice/data/bodhan_voice_catalog.dart';

void main() {
  group('bodhan voice catalog', () {
    test('contains only the two native Santali voices', () {
      expect(bodhanVoices.length, 2);
      expect(bodhanVoices.map((v) => v.name), ['Phulmani', 'Sibu']);
      expect(santaliVoices.map((v) => v.name), ['Phulmani', 'Sibu']);
      expect(defaultVoiceName, 'Phulmani');
      expect(defaultVoiceLang, 'sat');
    });

    test('rejects non-Santali voices', () {
      expect(isKnownVoice('Kavya'), isFalse);
      expect(isKnownVoice('Arun'), isFalse);
    });

    test('voice names are unique', () {
      final names = bodhanVoices.map((v) => v.name).toList();
      expect(names.toSet().length, names.length);
    });

    test('voiceByName falls back to Phulmani for unknown names', () {
      expect(voiceByName('Sibu').languageCode, 'sat');
      expect(voiceByName('Nobody').name, 'Phulmani');
      expect(isKnownVoice('Phulmani'), isTrue);
      expect(isKnownVoice('Sibu'), isTrue);
      expect(isKnownVoice('Nobody'), isFalse);
    });

    test('styles include neutral default and all 14 Bodhan styles', () {
      expect(neutralStyle.apiValue, isEmpty);
      // Neutral + 14 documented styles.
      expect(voiceStyles.length, 15);
      expect(isKnownStyle(''), isTrue);
      expect(isKnownStyle('news'), isTrue);
      expect(isKnownStyle("children's stories"), isTrue);
      expect(isKnownStyle('opera'), isFalse);
    });
  });
}
