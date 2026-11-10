import 'package:flutter_test/flutter_test.dart';
import 'package:itun/core/config/cloudflare_config.dart';
import 'package:itun/core/media/edge_media_url.dart';

void main() {
  final base = CloudflareConfig.baseUrl.replaceAll(RegExp(r'/$'), '');

  test('rewrites public Appwrite audio files to the R2 assets route', () {
    expect(
      toEdgeMediaUrl(
        'https://sgp.cloud.appwrite.io/v1/storage/buckets/audio/files/word_w_g1/view?project=p',
      ),
      '$base/api/v1/assets/audio/word_w_g1',
    );
  });

  test('rewrites images and previews too', () {
    expect(
      toEdgeMediaUrl(
        'https://sgp.cloud.appwrite.io/v1/storage/buckets/images/files/6a9ff1e937bec77ec5d0/preview?width=400',
      ),
      '$base/api/v1/assets/images/6a9ff1e937bec77ec5d0',
    );
  });

  test('leaves private buckets, non-Appwrite and empty URLs alone', () {
    const paid =
        'https://sgp.cloud.appwrite.io/v1/storage/buckets/paid_media/files/abc/view';
    expect(toEdgeMediaUrl(paid), paid);
    expect(
      toEdgeMediaUrl('https://example.com/a.mp3'),
      'https://example.com/a.mp3',
    );
    expect(toEdgeMediaUrl(''), '');
    expect(
      toEdgeMediaUrl('appwrite-storage://paid_media/x'),
      'appwrite-storage://paid_media/x',
    );
  });
}
