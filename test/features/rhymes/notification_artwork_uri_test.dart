import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/rhymes/presentation/providers/notification_artwork_uri.dart';

void main() {
  const view =
      'https://example.test/v1/storage/buckets/covers/files/cover/view';

  test('missing or malformed artwork is ignored', () {
    expect(notificationArtworkUri(null), isNull);
    expect(notificationArtworkUri('  '), isNull);
    expect(notificationArtworkUri('http://[invalid'), isNull);
  });

  test('project and encoded file-token values survive thumbnail conversion', () {
    final original = Uri.parse(
      '$view?project=demo&token=sample%2B%2F%3D',
    );
    final result = notificationArtworkUri(original.toString())!;

    expect(result.path, '/v1/storage/buckets/covers/files/cover/preview');
    expect(result.queryParameters['project'], 'demo');
    expect(result.queryParameters['token'], original.queryParameters['token']);
    expect(result.queryParameters['width'], '300');
    expect(result.queryParameters['height'], '300');
    expect(result.queryParameters['output'], 'webp');
    expect(result.toString().split('?').length, 2);
  });

  test('repeated parameters, port and fragment are preserved', () {
    final result = notificationArtworkUri(
      '${view.replaceFirst('example.test', 'example.test:8443')}'
      '?project=demo&tag=one&tag=two#cover',
    )!;

    expect(result.port, 8443);
    expect(result.fragment, 'cover');
    expect(result.queryParametersAll['tag'], ['one', 'two']);
    expect(result.queryParameters['project'], 'demo');
  });

  test('only thumbnail transformation parameters are overridden', () {
    final result = notificationArtworkUri(
      '$view?width=1200&width=600&height=800&output=png&project=demo',
    )!;

    expect(result.queryParametersAll['width'], ['300']);
    expect(result.queryParameters['height'], '300');
    expect(result.queryParameters['output'], 'webp');
    expect(result.queryParameters['project'], 'demo');
  });

  test('a query-free view URL becomes a bounded preview', () {
    final result = notificationArtworkUri('  $view  ')!;
    expect(result.path.endsWith('/preview'), isTrue);
    expect(result.queryParameters.length, 3);
  });

  test('non-view artwork and unrelated query text are left unchanged', () {
    for (final url in [
      '$view/extra?project=demo',
      view.replaceFirst('/view', '/preview?project=demo'),
      'https://example.test/image.png?next=/view',
      'https://example.test/view?project=demo',
      'file:///storage/buckets/covers/files/cover/view',
      'asset:///assets/images/cover.jpg',
    ]) {
      expect(notificationArtworkUri(url), Uri.parse(url), reason: url);
    }
  });
}
