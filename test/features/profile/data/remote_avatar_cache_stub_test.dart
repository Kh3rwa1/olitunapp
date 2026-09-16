import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/profile/data/datasources/remote_avatar_cache_stub.dart';

void main() {
  group('StubRemoteAvatarCache', () {
    test('factory returns an unsupported in-memory stub', () {
      final cache = createRemoteAvatarCache();

      expect(cache, isA<StubRemoteAvatarCache>());
      expect(cache.isSupported, isFalse);
    });

    test('filesystem queries report an empty cache', () async {
      final cache = StubRemoteAvatarCache();

      expect(await cache.exists('avatar.json'), isFalse);
      expect(await cache.cachedFileIds(), isEmpty);
      await expectLater(cache.delete('avatar.json'), completes);
    });

    test('disk reads and writes fail with a clear unsupported error', () {
      final cache = StubRemoteAvatarCache();

      expect(
        () => cache.writeBytes('avatar.json', const [1, 2, 3]),
        throwsUnsupportedError,
      );
      expect(
        () => cache.readBytes('avatar.json'),
        throwsUnsupportedError,
      );
    });
  });
}
