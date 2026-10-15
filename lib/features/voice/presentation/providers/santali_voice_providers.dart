import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/bodhan_voice_catalog.dart';
import '../../data/voice_download_service.dart';

export '../../data/bodhan_voice_catalog.dart';
export '../../data/santali_tts_service.dart';
export '../../data/voice_download_service.dart';

/// Last-used voice/style, persisted so the studio reopens as the learner
/// left it (viral tools must remember taste).
const _voicePrefKey = 'santali_voice_name';
const _stylePrefKey = 'santali_voice_style';

final santaliVoiceNameProvider = NotifierProvider<VoicePrefNotifier, String>(
  () => VoicePrefNotifier(_voicePrefKey, defaultVoiceName),
);

final santaliVoiceStyleProvider = NotifierProvider<VoicePrefNotifier, String>(
  () => VoicePrefNotifier(_stylePrefKey, neutralStyle.apiValue),
);

class VoicePrefNotifier extends Notifier<String> {
  VoicePrefNotifier(this._key, this._initial);

  final String _key;
  final String _initial;

  /// Bumped on dispose so a preference read that resolves afterwards is
  /// dropped (replaces StateNotifier's `mounted`).
  int _generation = 0;

  @override
  String build() {
    ref.onDispose(() => _generation++);
    return _initial;
  }

  Future<void> load() async {
    final generation = _generation;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved == null) return;
      if (_key == _voicePrefKey && !isKnownVoice(saved)) return;
      if (_key == _stylePrefKey && !isKnownStyle(saved)) return;
      if (generation == _generation && saved != state) state = saved;
    } catch (_) {
      // Preference restore must never break the studio.
    }
  }

  Future<void> select(String value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, value);
    } catch (_) {
      // Persist failure is non-fatal; selection still applies.
    }
  }
}

final voiceDownloadServiceProvider = Provider((_) => VoiceDownloadService());
