import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PWA web assets', () {
    test('manifest is installable and learner-focused', () {
      final manifest = _readJson('web/manifest.json');

      expect(manifest['name'], contains('Santali'));
      expect(manifest['short_name'], 'Olitun');
      expect(manifest['start_url'], '/?source=pwa');
      expect(manifest['scope'], '/');
      expect(manifest['id'], '/');
      expect(manifest['display'], 'standalone');
      expect(manifest['theme_color'], '#10B981');
      expect(manifest['background_color'], '#0A0E14');
      expect(manifest['prefer_related_applications'], isFalse);

      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      expect(
        icons,
        contains(
          allOf(
            containsPair('sizes', '192x192'),
            containsPair('purpose', 'maskable'),
          ),
        ),
      );
      expect(
        icons,
        contains(
          allOf(
            containsPair('sizes', '512x512'),
            containsPair('purpose', 'maskable'),
          ),
        ),
      );

      final shortcuts = (manifest['shortcuts'] as List).cast<Map>();
      expect(
        shortcuts.map((item) => item['name']),
        containsAll(['Learn', 'Bakhed', 'Affirmations', 'Profile']),
      );

      final displayOverride = (manifest['display_override'] as List)
          .cast<String>();
      expect(displayOverride, contains('window-controls-overlay'));
    });

    test('manifest screenshots are real wide and narrow app captures', () {
      final manifest = _readJson('web/manifest.json');
      final screenshots = (manifest['screenshots'] as List)
          .cast<Map<String, dynamic>>();

      expect(
        screenshots.map((item) => item['form_factor']),
        containsAll(['narrow', 'wide']),
      );

      for (final screenshot in screenshots) {
        final src = screenshot['src'] as String;
        final file = File('web/$src');
        expect(file.existsSync(), isTrue, reason: '$src must exist');
        final dimensions = _pngDimensions(file.readAsBytesSync());
        expect(
          screenshot['sizes'],
          '${dimensions.width}x${dimensions.height}',
          reason: '$src manifest size must match the PNG',
        );
        expect(
          dimensions.width >= 320 && dimensions.height >= 320,
          isTrue,
          reason: '$src must be large enough for app store previews',
        );
      }
    });

    test('index keeps PWA metadata accessible', () {
      final html = File('web/index.html').readAsStringSync();

      expect(html, contains('viewport-fit=cover'));
      expect(html, isNot(contains('user-scalable=no')));
      expect(html, isNot(contains('maximum-scale=1.0')));
      expect(html, contains('apple-mobile-web-app-capable'));
      expect(html, contains('apple-touch-icon'));
      expect(html, contains('role="status"'));
      expect(html, contains('prefers-reduced-motion'));
      expect(html, contains('prefers-color-scheme: dark'));
      expect(html, contains('pwa-update-toast'));
      expect(html, contains('screenshots/welcome-wide.png'));
    });

    test('install prompt is accessible and standalone-aware', () {
      final script = File('web/pwa_install.js').readAsStringSync();

      expect(script, contains('beforeinstallprompt'));
      expect(script, contains('appinstalled'));
      expect(script, contains('isStandalonePwa'));
      expect(script, contains('aria-label'));
      expect(script, contains('min-height:44px'));
      expect(script, contains('safe-area-inset-bottom'));
      expect(script, contains('pwa-installable'));
    });
  });
}

Map<String, dynamic> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

({int width, int height}) _pngDimensions(Uint8List bytes) {
  const pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];
  for (var i = 0; i < pngSignature.length; i += 1) {
    if (bytes[i] != pngSignature[i]) {
      throw const FormatException('Not a PNG file');
    }
  }
  final data = ByteData.sublistView(bytes);
  return (width: data.getUint32(16), height: data.getUint32(20));
}
