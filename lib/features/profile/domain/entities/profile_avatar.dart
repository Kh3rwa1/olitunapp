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
  });

  final String id;
  final String assetFileName;
  final String label;

  String get assetPath => '$avatarsAssetDir/$assetFileName';

  @override
  List<Object?> get props => [id, assetFileName, label];
}

const String avatarsAssetDir = 'assets/animations/avatars';

/// Default animation for fresh installs and malformed or legacy values.
const String kDefaultAvatarId = 'default';

/// Explicit, persistable choice that renders the learner's name initial.
const String kInitialAvatarId = 'initial';

/// Every catalog entry has a corresponding original asset in this repository.
/// Animal names keep the choices playful and culturally neutral.
const List<ProfileAvatar> kProfileAvatars = [
  ProfileAvatar(
    id: kDefaultAvatarId,
    assetFileName: 'avatar_tiger.json',
    label: 'Tiger',
  ),
  ProfileAvatar(id: 'owl', assetFileName: 'avatar_owl.json', label: 'Owl'),
  ProfileAvatar(id: 'ox', assetFileName: 'avatar_ox.json', label: 'Ox'),
  ProfileAvatar(
    id: 'paw_prints',
    assetFileName: 'avatar_paw_prints.json',
    label: 'Paw prints',
  ),
  ProfileAvatar(
    id: 'peace',
    assetFileName: 'avatar_peace.json',
    label: 'Peace',
  ),
  ProfileAvatar(id: 'ant', assetFileName: 'avatar_ant.json', label: 'Ant'),
  ProfileAvatar(
    id: 'cat_noha',
    assetFileName: 'avatar_cat_noha.json',
    label: 'Cat Noha',
  ),
  ProfileAvatar(
    id: 'smart_puppy',
    assetFileName: 'avatar_smart_puppy.json',
    label: 'Smart Puppy',
  ),
  ProfileAvatar(
    id: 'running_chicken',
    assetFileName: 'avatar_running_chicken.json',
    label: 'Running Chicken',
  ),
  ProfileAvatar(
    id: 'razmi',
    assetFileName: 'avatar_razmi.json',
    label: 'Razmi',
  ),
  ProfileAvatar(id: 'bear', assetFileName: 'avatar_bear.json', label: 'Bear'),
  ProfileAvatar(id: 'coco', assetFileName: 'avatar_coco.json', label: 'Coco'),
  ProfileAvatar(
    id: 'chicken',
    assetFileName: 'avatar_chicken.json',
    label: 'Chicken',
  ),
  ProfileAvatar(
    id: 'cat_3d',
    assetFileName: 'avatar_cat_3d.json',
    label: 'Cat 3D',
  ),
  ProfileAvatar(
    id: 'bad_cat',
    assetFileName: 'avatar_bad_cat.json',
    label: 'Bad Cat',
  ),
  ProfileAvatar(
    id: 'monkey',
    assetFileName: 'avatar_monkey.json',
    label: 'Monkey',
  ),
  ProfileAvatar(
    id: 'camaleon',
    assetFileName: 'avatar_camaleon.json',
    label: 'Camaleon',
  ),
  ProfileAvatar(
    id: 'quadrin_funny',
    assetFileName: 'avatar_quadrin_funny.json',
    label: 'Quadrin Funny',
  ),
  ProfileAvatar(id: 'flow', assetFileName: 'avatar_flow.json', label: 'Flow'),
  ProfileAvatar(
    id: 'one_eye_alien',
    assetFileName: 'avatar_one_eye_alien.json',
    label: 'One Eye Alien',
  ),
  ProfileAvatar(
    id: 'unicorn_stretching',
    assetFileName: 'avatar_unicorn_stretching.json',
    label: 'Unicorn Stretching',
  ),
  ProfileAvatar(
    id: 'girls_face',
    assetFileName: 'avatar_girls_face.json',
    label: "Girl's Face",
  ),
  ProfileAvatar(
    id: 'rate_us',
    assetFileName: 'avatar_rate_us.json',
    label: 'Rate Us',
  ),
  ProfileAvatar(
    id: 'girl_thumbs_up',
    assetFileName: 'avatar_girl_thumbs_up.json',
    label: 'Girl Thumbs Up',
  ),
  ProfileAvatar(
    id: 'laugh_oink',
    assetFileName: 'avatar_laugh_oink.json',
    label: 'Laugh Oink',
  ),
  ProfileAvatar(
    id: 'man_wink',
    assetFileName: 'avatar_man_wink.json',
    label: 'Man Wink',
  ),
  ProfileAvatar(
    id: 'blob_boy',
    assetFileName: 'avatar_blob_boy.json',
    label: 'Blob Boy',
  ),
  ProfileAvatar(
    id: 'love_cat',
    assetFileName: 'avatar_love_cat.json',
    label: 'Love Cat',
  ),
  ProfileAvatar(
    id: 'flirting_dog',
    assetFileName: 'avatar_flirting_dog.json',
    label: 'Flirting Dog',
  ),
  ProfileAvatar(
    id: 'lurking_cat',
    assetFileName: 'avatar_lurking_cat.json',
    label: 'Lurking Cat',
  ),
  ProfileAvatar(
    id: 'ghost',
    assetFileName: 'avatar_ghost.json',
    label: 'Ghost',
  ),
  ProfileAvatar(
    id: 'cha_chan',
    assetFileName: 'avatar_cha_chan.json',
    label: 'Cha Chan',
  ),
  ProfileAvatar(
    id: 'spiderman',
    assetFileName: 'avatar_spiderman.json',
    label: 'Spiderman',
  ),
  ProfileAvatar(
    id: 'lottie_admin',
    assetFileName: 'avatar_lottie_admin.json',
    label: 'Lottie Admin',
  ),
  ProfileAvatar(
    id: 'funny_emoji',
    assetFileName: 'avatar_funny_emoji.json',
    label: 'Funny Emoji',
  ),
];

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
