import 'package:flutter_test/flutter_test.dart';
import 'package:itun/features/content/data/offline/audio_download_store_stub.dart';

void main() {
  late StubAudioDownloadStore store;

  setUp(() {
    store = StubAudioDownloadStore();
  });

  test(
    'the web stub is created by the factory and reports no file support',
    () {
      final viaFactory = createAudioDownloadStore();
      expect(viaFactory, isA<StubAudioDownloadStore>());
      expect(viaFactory.isSupported, isFalse);
    },
  );

  test(
    'fileExists answers false and fileSize answers zero without touching IO',
    () async {
      expect(await store.fileExists('audio/story-1/seg-1.mp3'), isFalse);
      expect(await store.fileSize('audio/story-1/seg-1.mp3'), 0);
    },
  );

  test('deleteFile is a safe no-op on web', () async {
    await store.deleteFile('audio/story-1/seg-1.mp3');
    expect(await store.fileExists('audio/story-1/seg-1.mp3'), isFalse);
  });

  test('write/read helpers reject downloads as unsupported on web', () async {
    await expectLater(
      store.writeFileBytes('a.mp3', [1, 2, 3]),
      throwsUnsupportedError,
    );
    await expectLater(store.readFileBytes('a.mp3'), throwsUnsupportedError);
    await expectLater(
      store.writeFileString('meta.json', '{}'),
      throwsUnsupportedError,
    );
    await expectLater(
      store.readFileString('meta.json'),
      throwsUnsupportedError,
    );
    await expectLater(store.absolutePath('a.mp3'), throwsUnsupportedError);
  });
}
