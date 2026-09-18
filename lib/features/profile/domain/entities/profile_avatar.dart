import 'package:equatable/equatable.dart';

/// A selectable animated profile avatar backed by an original bundled Lottie
/// asset. Catalog entries must always point to files committed with the app.
///
/// Animal artwork: free Lottie animations by Google Inc. via IconScout
/// (free-animal-and-nature-animation packs 344421 and 344422, free license
/// with attribution) plus free LottieFiles community animations (see the
/// source links in tool/iconscout-avatar-import.tsv). See that manifest
/// for per-file sources.
class ProfileAvatar extends Equatable {
  const ProfileAvatar({
    required this.id,
    required this.assetFileName,
    required this.label,
    this.remoteFileId,
  });

  final String id;
  final String assetFileName;
  final String label;

  /// Appwrite Storage file id when this entry came from the remote avatar
  /// bucket. Null for bundled assets; artwork then resolves from cached or
  /// freshly downloaded bytes instead of the asset bundle.
  final String? remoteFileId;

  /// True when artwork must be resolved from cache/network bytes.
  bool get isRemote => remoteFileId != null;

  String get assetPath => '$avatarsAssetDir/$assetFileName';

  @override
  List<Object?> get props => [id, assetFileName, label, remoteFileId];
}

const String avatarsAssetDir = 'assets/animations/avatars';

/// Default animation for fresh installs and malformed or legacy values.
const String kDefaultAvatarId = 'default';

/// Explicit, persistable choice that renders the learner's name initial.
const String kInitialAvatarId = 'initial';

/// Ol Chiki funny nicknames keep the choices playful and Santali-first.
/// See `avatar_ol_chiki_names.dart` for the curated map (remote uses it too).
const List<ProfileAvatar> kProfileAvatars = [
  ProfileAvatar(
    id: kDefaultAvatarId,
    assetFileName: 'avatar_tiger.json',
    label: 'ᱨᱟᱹᱥᱠᱟᱹ ᱛᱟ.ᱨᱩᱵ',
  ),
  ProfileAvatar(
    id: 'owl',
    assetFileName: 'avatar_owl.json',
    label: 'ᱢᱟᱨᱟᱝ ᱢᱮᱫ ᱪᱮᱬᱮ',
  ),
  ProfileAvatar(
    id: 'ox',
    assetFileName: 'avatar_ox.json',
    label: 'ᱢᱟᱨᱟᱝ ᱰᱟᱝᱨᱟ',
  ),
  ProfileAvatar(
    id: 'paw_prints',
    assetFileName: 'avatar_paw_prints.json',
    label: 'ᱡᱟᱝᱜᱟ ᱪᱤᱱᱦᱟᱹ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'peace',
    assetFileName: 'avatar_peace.json',
    label: 'ᱥᱩᱞᱩᱠ ᱨᱟᱹᱥᱠᱟᱹ',
  ),
  ProfileAvatar(
    id: 'ant',
    assetFileName: 'avatar_ant.json',
    label: 'ᱦᱩᱰᱤᱧ ᱮᱱᱴ',
  ),
  ProfileAvatar(
    id: 'cat_noha',
    assetFileName: 'avatar_cat_noha.json',
    label: 'ᱮᱱᱮᱡ ᱯᱩᱥᱤ',
  ),
  ProfileAvatar(
    id: 'smart_puppy',
    assetFileName: 'avatar_smart_puppy.json',
    label: 'ᱥᱤᱭᱟᱹᱱᱟ ᱥᱮᱛᱟ ᱜᱤᱫᱽᱨᱟᱹ',
  ),
  ProfileAvatar(
    id: 'running_chicken',
    assetFileName: 'avatar_running_chicken.json',
    label: 'ᱧᱤᱨ ᱥᱤᱢ',
  ),
  ProfileAvatar(
    id: 'razmi',
    assetFileName: 'avatar_razmi.json',
    label: 'ᱨᱟᱡᱽᱢᱤ ᱨᱟᱹᱥᱠᱟᱹ',
  ),
  ProfileAvatar(
    id: 'bear',
    assetFileName: 'avatar_bear.json',
    label: 'ᱮᱱᱮᱡ ᱵᱟᱱᱟ',
  ),
  ProfileAvatar(
    id: 'coco',
    assetFileName: 'avatar_coco.json',
    label: 'ᱠᱳᱠᱳ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'chicken',
    assetFileName: 'avatar_chicken.json',
    label: 'ᱨᱟᱹᱥᱠᱟᱹ ᱥᱤᱢ',
  ),
  ProfileAvatar(
    id: 'cat_3d',
    assetFileName: 'avatar_cat_3d.json',
    label: 'ᱱᱟᱣᱟ ᱯᱩᱥᱤ',
  ),
  ProfileAvatar(
    id: 'bad_cat',
    assetFileName: 'avatar_bad_cat.json',
    label: 'ᱵᱚᱫᱽᱢᱟᱥ ᱯᱩᱥᱤ',
  ),
  ProfileAvatar(
    id: 'monkey',
    assetFileName: 'avatar_monkey.json',
    label: 'ᱢᱟᱥᱛᱤ ᱦᱟ.ᱬᱩ',
  ),
  ProfileAvatar(
    id: 'camaleon',
    assetFileName: 'avatar_camaleon.json',
    label: 'ᱨᱚᱝ ᱵᱚᱫᱚᱞ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'quadrin_funny',
    assetFileName: 'avatar_quadrin_funny.json',
    label: 'ᱟᱹᱰᱤ ᱨᱟᱹᱥᱠᱟᱹ',
  ),
  ProfileAvatar(
    id: 'flow',
    assetFileName: 'avatar_flow.json',
    label: 'ᱟᱛᱩ ᱨᱟᱹᱥᱠᱟᱹ',
  ),
  ProfileAvatar(
    id: 'one_eye_alien',
    assetFileName: 'avatar_one_eye_alien.json',
    label: 'ᱢᱤᱫ ᱢᱮᱫ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'unicorn_stretching',
    assetFileName: 'avatar_unicorn_stretching.json',
    label: 'ᱢᱟᱨᱟᱝ ᱥᱤᱸᱜ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'girls_face',
    assetFileName: 'avatar_girls_face.json',
    label: 'ᱨᱟᱹᱥᱠᱟᱹ ᱵᱤᱴᱤ',
  ),
  ProfileAvatar(
    id: 'rate_us',
    assetFileName: 'avatar_rate_us.json',
    label: 'ᱥᱟᱨᱦᱟᱣ ᱨᱟᱹᱥᱠᱟᱹ',
  ),
  ProfileAvatar(
    id: 'girl_thumbs_up',
    assetFileName: 'avatar_girl_thumbs_up.json',
    label: 'ᱥᱟᱵᱟᱥ ᱵᱤᱴᱤ',
  ),
  ProfileAvatar(
    id: 'laugh_oink',
    assetFileName: 'avatar_laugh_oink.json',
    label: 'ᱞᱟᱸᱫᱟ ᱥᱩᱠᱨᱤ',
  ),
  ProfileAvatar(
    id: 'man_wink',
    assetFileName: 'avatar_man_wink.json',
    label: 'ᱢᱮᱫ ᱵᱤᱞᱤᱪ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'blob_boy',
    assetFileName: 'avatar_blob_boy.json',
    label: 'ᱯᱷᱩᱞᱟᱹᱣ ᱜᱤᱫᱽᱨᱟᱹ',
  ),
  ProfileAvatar(
    id: 'love_cat',
    assetFileName: 'avatar_love_cat.json',
    label: 'ᱫᱩᱞᱟᱹᱲ ᱯᱩᱥᱤ',
  ),
  ProfileAvatar(
    id: 'flirting_dog',
    assetFileName: 'avatar_flirting_dog.json',
    label: 'ᱨᱟᱹᱥᱠᱟᱹ ᱥᱮᱛᱟ',
  ),
  ProfileAvatar(
    id: 'lurking_cat',
    assetFileName: 'avatar_lurking_cat.json',
    label: 'ᱩᱠᱩ ᱯᱩᱥᱤ',
  ),
  ProfileAvatar(
    id: 'ghost',
    assetFileName: 'avatar_ghost.json',
    label: 'ᱨᱟᱹᱥᱠᱟᱹ ᱵᱷᱩᱛ',
  ),
  ProfileAvatar(
    id: 'cha_chan',
    assetFileName: 'avatar_cha_chan.json',
    label: 'ᱪᱷᱟ ᱪᱷᱟᱱ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'lottie_admin',
    assetFileName: 'avatar_lottie_admin.json',
    label: 'ᱢᱟᱪᱮᱛ ᱢᱟᱥᱛᱤ',
  ),
  ProfileAvatar(
    id: 'funny_emoji',
    assetFileName: 'avatar_funny_emoji.json',
    label: 'ᱞᱟᱸᱫᱟ ᱢᱩᱸᱦᱟᱸ',
  ),
  ProfileAvatar(
    id: 'baby_chick',
    assetFileName: 'avatar_baby_chick.json',
    label: 'ᱦᱩᱰᱤᱧ ᱥᱤᱢ ᱜᱤᱫᱽᱨᱟᱹ',
  ),
  ProfileAvatar(
    id: 'bat',
    assetFileName: 'avatar_bat.json',
    label: 'ᱧᱤᱫᱟᱹ ᱵᱟᱫᱩᱲ',
  ),
  ProfileAvatar(
    id: 'bee',
    assetFileName: 'avatar_bee.json',
    label: 'ᱨᱟᱹᱥᱠᱟᱹ ᱧᱮᱞᱮ',
  ),
  ProfileAvatar(
    id: 'bird',
    assetFileName: 'avatar_bird.json',
    label: 'ᱮᱱᱮᱡ ᱪᱮᱬᱮ',
  ),
  ProfileAvatar(
    id: 'black_bird',
    assetFileName: 'avatar_black_bird.json',
    label: 'ᱦᱮᱸᱫᱮ ᱪᱮᱬᱮ',
  ),
  ProfileAvatar(
    id: 'blowfish',
    assetFileName: 'avatar_blowfish.json',
    label: 'ᱯᱷᱩᱞᱟᱹᱣ ᱦᱟᱹᱠᱩ',
  ),
  ProfileAvatar(
    id: 'comet',
    assetFileName: 'avatar_comet.json',
    label: 'ᱥᱤᱨᱡᱚᱱ ᱤᱯᱤᱞ',
  ),
];

/// Merges remotely synced avatars into the bundled catalog for display.
///
/// The bundled order is preserved so the picker grid never reshuffles when
/// the background sync lands: remote entries win on id conflicts (admin
/// updates without an app release) and genuinely new remote ids are appended
/// in bucket order. An empty [remote] list returns [kProfileAvatars].
List<ProfileAvatar> mergeAvatarCatalog(List<ProfileAvatar> remote) {
  if (remote.isEmpty) return kProfileAvatars;
  final merged = List<ProfileAvatar>.of(kProfileAvatars);
  final indexById = <String, int>{
    for (var i = 0; i < merged.length; i++) merged[i].id: i,
  };
  for (final avatar in remote) {
    final index = indexById[avatar.id];
    if (index == null) {
      indexById[avatar.id] = merged.length;
      merged.add(avatar);
    } else {
      merged[index] = avatar;
    }
  }
  return List<ProfileAvatar>.unmodifiable(merged);
}

/// Like [normalizeAvatarId] but additionally accepts ids from the background
/// remote sync (see `availableAvatarsProvider`). [knownIds] is the set of ids
/// in the latest catalog emission; unknown values still migrate to the
/// default asset so legacy emoji can never persist as a selection.
String normalizeAvatarIdWithRemote(String? id, Iterable<String>? knownIds) {
  if (id == kInitialAvatarId) return kInitialAvatarId;
  if (id == null || id.isEmpty) return kDefaultAvatarId;
  if (profileAvatarById(id) != null) return id;
  if (knownIds != null && knownIds.contains(id)) return id;
  return kDefaultAvatarId;
}
ProfileAvatar? profileAvatarById(String id) {
  for (final avatar in kProfileAvatars) {
    if (avatar.id == id) return avatar;
  }
  return null;
}

/// Empty values are accepted only as a backwards-compatible presentation
/// alias. New writes persist [kInitialAvatarId] instead.
bool usesProfileInitial(String? id) =>
    id == null || id.isEmpty || id == kInitialAvatarId;

/// Resolves an animation id to a bundled asset. The explicit initial option is
/// never passed to Lottie by the UI; returning the default remains fail-safe.
String avatarAssetPath(String id) {
  return profileAvatarById(id)?.assetPath ?? kProfileAvatars.first.assetPath;
}

/// Preserves the explicit initial choice and valid catalog ids. Unknown values,
/// including legacy emoji preferences, migrate safely to the default asset.
String normalizeAvatarId(String? id) {
  if (id == kInitialAvatarId) return kInitialAvatarId;
  if (id == null || id.isEmpty) return kDefaultAvatarId;
  return profileAvatarById(id)?.id ?? kDefaultAvatarId;
}
