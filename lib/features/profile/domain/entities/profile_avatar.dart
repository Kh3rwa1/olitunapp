import 'package:equatable/equatable.dart';

/// A selectable animated profile avatar backed by a bundled Lottie file.
///
/// Avatars are plain animations — no emoji. The picker only offers entries
/// whose JSON file is bundled under [avatarsAssetDir]; premium IconScout
/// files are dropped into that folder using the [assetFileName] below.
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

/// Folder (declared in pubspec.yaml) holding every avatar animation.
const String avatarsAssetDir = 'assets/animations/avatars';

/// Avatar used for fresh installs and as the fallback for unknown ids
/// (including legacy emoji values stored before the Lottie migration).
const String kDefaultAvatarId = 'default';

/// Full catalog: the bundled default plus the 18 premium
/// "Profile Avatar Icon Lottie Animation" pack slots. Premium files are
/// optional — the picker lists only files actually present in the bundle.
const List<ProfileAvatar> kProfileAvatars = [
  ProfileAvatar(
    id: kDefaultAvatarId,
    assetFileName: 'avatar_default.json',
    label: 'Olitun',
  ),
  // --- Premium pack: boys (7) ---
  ProfileAvatar(
    id: 'boy_01',
    assetFileName: 'avatar_boy_01.json',
    label: 'Boy 1',
  ),
  ProfileAvatar(
    id: 'boy_02',
    assetFileName: 'avatar_boy_02.json',
    label: 'Boy 2',
  ),
  ProfileAvatar(
    id: 'boy_03',
    assetFileName: 'avatar_boy_03.json',
    label: 'Boy 3',
  ),
  ProfileAvatar(
    id: 'boy_04',
    assetFileName: 'avatar_boy_04.json',
    label: 'Boy 4',
  ),
  ProfileAvatar(
    id: 'boy_05',
    assetFileName: 'avatar_boy_05.json',
    label: 'Boy 5',
  ),
  ProfileAvatar(
    id: 'boy_06',
    assetFileName: 'avatar_boy_06.json',
    label: 'Boy 6',
  ),
  ProfileAvatar(
    id: 'boy_07',
    assetFileName: 'avatar_boy_07.json',
    label: 'Boy 7',
  ),
  // --- Premium pack: girls (4) ---
  ProfileAvatar(
    id: 'girl_01',
    assetFileName: 'avatar_girl_01.json',
    label: 'Girl 1',
  ),
  ProfileAvatar(
    id: 'girl_02',
    assetFileName: 'avatar_girl_02.json',
    label: 'Girl 2',
  ),
  ProfileAvatar(
    id: 'girl_03',
    assetFileName: 'avatar_girl_03.json',
    label: 'Girl 3',
  ),
  ProfileAvatar(
    id: 'girl_04',
    assetFileName: 'avatar_girl_04.json',
    label: 'Girl 4',
  ),
  // --- Premium pack: man (1) ---
  ProfileAvatar(
    id: 'man_01',
    assetFileName: 'avatar_man_01.json',
    label: 'Man',
  ),
  // --- Premium pack: women (6) ---
  ProfileAvatar(
    id: 'women_01',
    assetFileName: 'avatar_women_01.json',
    label: 'Women 1',
  ),
  ProfileAvatar(
    id: 'women_02',
    assetFileName: 'avatar_women_02.json',
    label: 'Women 2',
  ),
  ProfileAvatar(
    id: 'women_03',
    assetFileName: 'avatar_women_03.json',
    label: 'Women 3',
  ),
  ProfileAvatar(
    id: 'women_04',
    assetFileName: 'avatar_women_04.json',
    label: 'Women 4',
  ),
  ProfileAvatar(
    id: 'women_05',
    assetFileName: 'avatar_women_05.json',
    label: 'Women 5',
  ),
  ProfileAvatar(
    id: 'women_06',
    assetFileName: 'avatar_women_06.json',
    label: 'Women 6',
  ),
];

/// Resolves a stored avatar id to its bundled asset path, falling back to
/// the default animation for unknown ids (never an emoji).
String avatarAssetPath(String id) {
  for (final avatar in kProfileAvatars) {
    if (avatar.id == id) return avatar.assetPath;
  }
  return kProfileAvatars.first.assetPath;
}

/// Stored id if it names a catalog entry, otherwise the default id.
String normalizeAvatarId(String? id) {
  if (id == null || id.isEmpty) return kDefaultAvatarId;
  for (final avatar in kProfileAvatars) {
    if (avatar.id == id) return id;
  }
  return kDefaultAvatarId;
}
