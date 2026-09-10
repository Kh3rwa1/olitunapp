import 'package:equatable/equatable.dart';

/// A selectable animated profile avatar backed by an original bundled Lottie
/// asset. Catalog entries must always point to files committed with the app.
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
/// Abstract names keep the choices inclusive and culturally neutral.
const List<ProfileAvatar> kProfileAvatars = [
  ProfileAvatar(
    id: kDefaultAvatarId,
    assetFileName: 'avatar_default.json',
    label: 'Olitun',
  ),
  ProfileAvatar(
    id: 'sunrise',
    assetFileName: 'avatar_sunrise.json',
    label: 'Sunrise',
  ),
  ProfileAvatar(
    id: 'river',
    assetFileName: 'avatar_river.json',
    label: 'River',
  ),
  ProfileAvatar(
    id: 'forest',
    assetFileName: 'avatar_forest.json',
    label: 'Forest',
  ),
  ProfileAvatar(
    id: 'festival',
    assetFileName: 'avatar_festival.json',
    label: 'Festival',
  ),
  ProfileAvatar(
    id: 'night_sky',
    assetFileName: 'avatar_night_sky.json',
    label: 'Night sky',
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
