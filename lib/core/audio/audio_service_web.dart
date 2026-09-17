import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:itun/core/logging/app_logger.dart';

web.HTMLAudioElement? _currentWebAudio;
JSFunction? _webEndedListener;

/// Fallback player for web when just_audio cannot load a URL (e.g. CORS).
/// just_audio never sees this element, so completions are reported through
/// [onEnded] — without it the central controller would show "playing"
/// forever after the clip ends.
void playNativeWebAudio(String url, {void Function()? onEnded}) {
  try {
    stopNativeWebAudio();
    final element = web.HTMLAudioElement()
      ..src = url
      ..crossOrigin = 'anonymous';
    if (onEnded != null) {
      _webEndedListener = ((JSAny _) {
        try {
          onEnded();
        } catch (e) {
          AppLogger.warning('playNativeWebAudio onEnded failed: $e');
        }
      }).toJS;
      element.addEventListener('ended', _webEndedListener);
    }
    _currentWebAudio = element;
    _currentWebAudio?.play();
  } catch (e) {
    AppLogger.warning('playNativeWebAudio failed: $e');
  }
}

void stopNativeWebAudio() {
  try {
    if (_webEndedListener != null) {
      _currentWebAudio?.removeEventListener('ended', _webEndedListener);
      _webEndedListener = null;
    }
    _currentWebAudio?.pause();
    _currentWebAudio?.remove();
    _currentWebAudio = null;
  } catch (_) {
    // Best-effort cleanup: element removal can throw if already detached.
  }
}
