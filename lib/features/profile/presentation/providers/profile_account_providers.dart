// Account identity & preference providers: display name, avatar
// (Lottie animation id + palette), badge names, membership date and real
// account age. Split out of profile_providers.dart by feature area.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/api/appwrite_db_service.dart';
import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
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
/// The bundled set below is always emitted first so the picker opens
/// instantly with zero network; remote entries from the avatar bucket merge
/// in the background whenever the sync succeeds, so new uploads appear
/// without an app release. Offline (or a failed sync) simply keeps bundled.
final availableAvatarsProvider = StreamProvider<List<ProfileAvatar>>((
  ref,
) async* {
  yield kProfileAvatars;

  var base = kProfileAvatars;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundled = manifest.listAssets().toSet();
    final missing = base
        .where((avatar) => !bundled.contains(avatar.assetPath))
        .map((avatar) => avatar.id)
        .toSet();
    if (missing.isNotEmpty) {
      AppLogger.warning(
        'Missing bundled profile avatar assets: ${missing.join(', ')}',
      );
      base = base
          .where((avatar) => !missing.contains(avatar.id))
          .toList(growable: false);
      yield base;
    }
  } catch (error) {
    AppLogger.debug('Avatar asset validation skipped: $error');
  }

  // Background remote merge. Guarded twice (here and inside
  // [_remoteAvatarsOrEmpty]) so a misconfigured backend can never turn the
  // catalog stream itself into an error: an unlistened stream error would
  // surface as an unhandled async error.
  var remote = const <ProfileAvatar>[];
  try {
    remote = await _remoteAvatarsOrEmpty(ref);
  } catch (_) {
    remote = const <ProfileAvatar>[];
  }
  if (remote.isEmpty) return;
  final merged = mergeAvatarCatalog(remote);
  if (!_sameAvatarIds(merged, base)) yield merged;
});

bool _sameAvatarIds(List<ProfileAvatar> a, List<ProfileAvatar> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].id != b[i].id) return false;
  }
  return true;
}

/// Resolves one avatar id against the latest catalog emission: background
/// remote entries first, then bundled, then the default animation. Never
/// throws, so hero/sidebar render instantly and swap in remote artwork only
/// if the sync later delivers that id.
final resolvedAvatarProvider = Provider.family<ProfileAvatar, String>((
  ref,
  id,
) {
  if (!usesProfileInitial(id)) {
    final remote = ref.watch(remoteAvatarListProvider).valueOrNull;
    if (remote != null) {
      for (final avatar in remote) {
        if (avatar.id == id) return avatar;
      }
    }
    final bundled = profileAvatarById(id);
    if (bundled != null) return bundled;
  }
  return kProfileAvatars.first;
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
