/// Bodhan indic-speak catalog for the Santali AI Voice feature.
///
/// Mirrors `functions/santaliVoice/src/validation.js` — keep both in sync
/// when voices or styles change. Santali-only by product decision: just
/// the two native Santali voices, Phulmani (female) and Sibu (male).
library;

/// A single Bodhan speaker voice.
class BodhanVoice {
  const BodhanVoice({
    required this.name,
    required this.languageCode,
    required this.languageName,
    required this.isFemale,
  });

  final String name;
  final String languageCode;
  final String languageName;
  final bool isFemale;

  String get genderLabel => isFemale ? 'Female' : 'Male';
}

const String defaultVoiceName = 'Phulmani';
const String defaultVoiceLang = 'sat';

/// The two native Santali voices — the only voices the app offers.
const List<BodhanVoice> bodhanVoices = [
  BodhanVoice(
    name: 'Phulmani',
    languageCode: 'sat',
    languageName: 'Santali',
    isFemale: true,
  ),
  BodhanVoice(
    name: 'Sibu',
    languageCode: 'sat',
    languageName: 'Santali',
    isFemale: false,
  ),
];

/// The two native Santali voices, shown as hero picks.
List<BodhanVoice> get santaliVoices =>
    bodhanVoices.where((v) => v.languageCode == 'sat').toList(growable: false);

/// A speaking style. Empty [apiValue] means the voice's neutral reading.
class VoiceStyle {
  const VoiceStyle({required this.label, required this.apiValue});

  final String label;
  final String apiValue;
}

const VoiceStyle neutralStyle = VoiceStyle(label: 'Neutral', apiValue: '');

const List<VoiceStyle> voiceStyles = [
  neutralStyle,
  VoiceStyle(label: 'News', apiValue: 'news'),
  VoiceStyle(label: 'TV News', apiValue: 'TV style news'),
  VoiceStyle(label: 'AIR News', apiValue: 'AIR style news'),
  VoiceStyle(label: 'Story', apiValue: "children's stories"),
  VoiceStyle(label: 'Audiobook', apiValue: 'single person narration audiobook'),
  VoiceStyle(label: 'Lecture', apiValue: 'educational lecture'),
  VoiceStyle(label: 'Ad', apiValue: 'advertisements'),
  VoiceStyle(label: 'Customer Care', apiValue: 'Customer Care'),
  VoiceStyle(label: 'Happy', apiValue: 'happy'),
  VoiceStyle(label: 'Sad', apiValue: 'sad'),
  VoiceStyle(label: 'Anger', apiValue: 'anger'),
  VoiceStyle(label: 'Fear', apiValue: 'fear'),
  VoiceStyle(label: 'Disgust', apiValue: 'disgust'),
  VoiceStyle(label: 'Surprise', apiValue: 'surprise'),
];

BodhanVoice voiceByName(String name) => bodhanVoices.firstWhere(
  (v) => v.name == name,
  orElse: () => bodhanVoices.firstWhere((v) => v.name == defaultVoiceName),
);

bool isKnownVoice(String name) => bodhanVoices.any((v) => v.name == name);

bool isKnownStyle(String apiValue) =>
    apiValue.isEmpty || voiceStyles.any((s) => s.apiValue == apiValue);
