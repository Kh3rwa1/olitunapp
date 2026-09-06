from pathlib import Path
import subprocess


def patch(path, old, new, count=1):
    p = Path(path)
    text = p.read_text()
    assert text.count(old) == count, (path, old, text.count(old))
    p.write_text(text.replace(old, new))


new_tests = Path('functions/test/authorized_media_access.test.js')
if not new_tests.exists():
    original_path = 'functions/test/authorized_lesson.test.js'
    new_tests.write_text(Path(original_path).read_text())
    legacy = subprocess.check_output(['git', 'show', 'origin/main:' + original_path], text=True)
    legacy = legacy.replace('createGetAuthorizedLessonHandler, evaluateLessonAccess', 'createGetAuthorizedLessonHandler as rawCreateHandler, evaluateLessonAccess')
    anchor = '\nfunction mockRes() {'
    assert legacy.count(anchor) == 1
    legacy = legacy.replace(anchor, '''
process.env.MEDIA_PUBLIC_ENDPOINT = 'https://media.example.test/v1';
process.env.APPWRITE_PROJECT_ID = 'test_project';
function createGetAuthorizedLessonHandler(options = {}) {
  return rawCreateHandler({
    ...options,
    storage: {
      getFile: async ({ fileId }) => ({ $id: fileId, mimeType: 'audio/mpeg', sizeOriginal: 1 }),
      ...options.storage,
      getFileDownload: async () => assert.fail('Media bytes must not pass through the function'),
    },
    tokens: { createFileToken: async ({ expire }) => ({ secret: 'test-only-grant', expire }) },
  });
}

function mockRes() {''')
    legacy = legacy.replace("action: 'get_media',", "action: 'get_media', protocolVersion: 2,")
    legacy = legacy.replace('.body.base64', '.body.url')
    Path(original_path).write_text(legacy)

patch('lib/core/media/authorized_media_provider.dart', 'state.value?.id', 'state.valueOrNull?.id')
p = 'lib/core/audio/private_audio_playback.dart'
patch(p, 'await player.stop();', 'await _stopSafely();', count=2)
patch(p, '  void cancel() {', '''  Future<void> _stopSafely() async {
    try {
      await player.stop();
    } catch (_) {
      // A disposed/failed player must not leak URI-bearing errors from timers.
    }
  }

  void cancel() {''')
p = 'lib/core/audio/audio_service.dart'
patch(p, '  PrivateAudioPlayback? _privatePlayback;', '  late final PrivateAudioPlayback? _privatePlayback;')
patch(p, '''    if (mediaService != null) {
      _privatePlayback = PrivateAudioPlayback(_player, mediaService);
    }''', '''    _privatePlayback = mediaService == null
        ? null
        : PrivateAudioPlayback(_player, mediaService);''')
p = 'lib/shared/widgets/authorized_media_display.dart'
patch(p, "import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_svg/flutter_svg.dart';\nimport 'package:lottie/lottie.dart';")
patch(p, "      } else if (!(lease.mimeType?.startsWith('image/') ?? false)) {", "      } else if (!(lease.mimeType?.startsWith('image/') ?? false) &&\n          lease.mimeType != 'application/json') {")
patch(p, '      await candidate?.dispose();', '      try { await candidate?.dispose(); } catch (_) {}')
patch(p, '''    if (controller == null) {
      return Image.network(''', '''    if (controller == null) {
      if (lease.mimeType == 'image/svg+xml') {
        return SvgPicture.network(
          lease.uri.toString(), fit: widget.fit,
          errorBuilder: (_, _, _) => _retryView(),
        );
      }
      if (lease.mimeType == 'application/json') {
        return Lottie.network(
          lease.uri.toString(), fit: widget.fit,
          errorBuilder: (_, _, _) => _retryView(),
        );
      }
      return Image.network(''')
patch(p, '        errorBuilder: (_, _, _) => widget.fallback,', '        errorBuilder: (_, _, _) => _retryView(),')
patch(p, '  Future<void> _resume() async {', '''  Widget _retryView() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      widget.fallback,
      IconButton(
        tooltip: 'Retry media',
        onPressed: () => unawaited(_load(preserve: false)),
        icon: const Icon(Icons.refresh),
      ),
    ]),
  );

  Future<void> _resume() async {''')
print('Preserved baseline entitlement tests, added transport tests, and hardened media failure cleanup.')
