import 'package:web/web.dart' as web;
import 'package:itun/core/logging/app_logger.dart';

web.HTMLAudioElement? _currentWebAudio;

void playNativeWebAudio(String url) {
  try {
    _currentWebAudio?.pause();
    _currentWebAudio?.remove();
    _currentWebAudio = web.HTMLAudioElement()
      ..src = url
      ..crossOrigin = 'anonymous';
    _currentWebAudio?.play();
  } catch (e) {
    AppLogger.warning('playNativeWebAudio failed: $e');
  }
}

void stopNativeWebAudio() {
  try {
    _currentWebAudio?.pause();
    _currentWebAudio?.remove();
    _currentWebAudio = null;
  } catch (_) {
    // Best-effort cleanup: element removal can throw if already detached.
  }
}
