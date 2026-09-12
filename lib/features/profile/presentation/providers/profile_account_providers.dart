// Account identity & preference providers: display name, avatar
// (Lottie animation id + palette), badge names, membership date and real
// account age. Split out of profile_providers.dart by feature area.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/content_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/remote_avatar_datasource.dart';
import '../../domain/entities/profile_avatar.dart';

/// Real account creation date from Appwrite (null for guests/offline).
/// The profile hero hides its "Since ..." line rather than guessing.
final accountCreatedAtProvider = FutureProvider<DateTime?>((ref) async {
  final authed = await ref.watch(isAuthenticatedProvider.future);
  if (!authed) return null;
  try {
    final authService = ref.watch(appwriteAuthServiceProvider);
    final account = await authService.account.get();
    return DateTime.tryParse(account.registration)?.toLocal();
  } catch (_) {
    return null;
  }
});

final userNameProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('user_name') ??
      'Learner';
});

/// Selected animation id or the explicit name-initial choice. Unknown and
/// legacy emoji values resolve to the bundled default without rendering emoji.
final userAvatarIdProvider = StateProvider<String>((ref) {
  final stored = ref
      .read(sharedPreferencesProvider)
      .getString('user_avatar_id');
  return normalizeAvatarId(stored);
});

/// Syncs the live avatar set from the `profile_avatars` bucket.
final remoteAvatarDatasourceProvider = Provider<RemoteAvatarDatasource>((ref) {
  return RemoteAvatarDatasource(ref.watch(appwriteDbServiceProvider).storage);
});

/// Live avatar entries from Appwrite. Empty (never an error) when offline,
/// misconfigured, or unsupported so the bundled set below stays available.
final remoteAvatarListProvider = FutureProvider<List<ProfileAvatar>>((
  ref,
) async {
  final datasource = ref.watch(remoteAvatarDatasourceProvider);
  final result = await datasource.syncAvatars().timeout(
    const Duration(seconds: 8),
    onTimeout: () =>
        const Left(NetworkFailure(message: 'Avatar sync timed out')),
  );
  return result.fold((_) => const <ProfileAvatar>[], (avatars) => avatars);
});

/// Remote entries, or empty when the sync fails, times out, or is
/// unsupported — so the bundled set below stays available. Never throws.
Future<List<ProfileAvatar>> _remoteAvatarsOrEmpty(Ref ref) async {
  try {
    return await ref.watch(remoteAvatarListProvider.future);
  } catch (_) {
    return const <ProfileAvatar>[];
  }
}

/// Validates the complete catalog against Flutter's generated asset manifest.
/// Missing registrations fail visibly instead of silently hiding choices or
/// rendering a generic icon in place of a promised animation.
///
/// Remote entries from the avatar bucket take precedence whenever the sync
/// succeeds, so new uploads appear without an app release; the bundled set
/// below is the offline fallback.
final availableAvatarsProvider = FutureProvider<List<ProfileAvatar>>((
  ref,
) async {
  final remote = await _remoteAvatarsOrEmpty(ref);
  if (remote.isNotEmpty) return remote;

  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final bundled = manifest.listAssets().toSet();
  final missing = kProfileAvatars
      .where((avatar) => !bundled.contains(avatar.assetPath))
      .toList(growable: false);
  if (missing.isNotEmpty) {
    throw StateError(
      'Missing bundled profile avatar assets: '
      '${missing.map((avatar) => avatar.assetPath).join(', ')}',
    );
  }
  return kProfileAvatars;
});

/// Artwork bytes for one remote avatar, served from the disk cache on
/// native platforms and streamed on demand on web. Bundled avatars never
/// reach this provider; they resolve from the asset bundle directly.
final avatarArtworkBytesProvider =
    FutureProvider.family<Uint8List, ProfileAvatar>((ref, avatar) async {
      final fileId = avatar.remoteFileId;
      if (fileId == null) {
        throw StateError('Bundled avatars resolve from the asset bundle');
      }
      final datasource = ref.watch(remoteAvatarDatasourceProvider);
      final result = await datasource.readArtworkBytes(fileId);
      return result.fold(
        (failure) => throw FailureException(failure),
        Uint8List.fromList,
      );
    });

/// Fresh installs start on the transparent background so the animation sits
/// on the profile board itself. Explicitly stored indices are untouched.
final userAvatarColorIndexProvider = StateProvider<int>((ref) {
  return ref.read(sharedPreferencesProvider).getInt('user_avatar_color') ??
      AppColors.transparentAvatarPaletteIndex;
});

final badgeTraditionalArcherNameProvider = StateProvider<String>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getString('badge_traditional_archer_name') ??
      'Santali Archer';
});

final badgeTraditionalKudumNameProvider = StateProvider<String>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getString('badge_traditional_kudum_name') ??
      'Kudum Master';
});

final badgeTraditionalKherwalNameProvider = StateProvider<String>((ref) {
  return ref
          .watch(sharedPreferencesProvider)
          .getString('badge_traditional_kherwal_name') ??
      'Kherwal Elder';
});

final memberSinceProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('member_since') ??
      'April 2024';
});

final userAvatarColorsProvider = Provider<List<Color>>((ref) {
  final index = ref.watch(userAvatarColorIndexProvider);
  return AppColors.avatarPalettes[index.clamp(
    0,
    AppColors.avatarPalettes.length - 1,
  )];
});
