// Account identity & preference providers: display name, avatar
// (Lottie animation id + palette), badge names, membership date and real
// account age. Split out of profile_providers.dart by feature area.
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/appwrite_auth_service.dart';
import '../../../../core/storage/hive_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/profile_avatar.dart';

/// Real account creation date from Appwrite (null for guests/offline).
/// The profile hero hides its "Since ..." line rather than guessing.
final accountCreatedAtProvider = FutureProvider<DateTime?>((ref) async {
  // Guests have no account record — skip the network call entirely.
  final authed = await ref.watch(isAuthenticatedProvider.future);
  if (!authed) return null;
  try {
    final authService = ref.watch(appwriteAuthServiceProvider);
    final account = await authService.account.get();
    // Appwrite returns `registration` as an ISO string.
    return DateTime.tryParse(account.registration)?.toLocal();
  } catch (_) {
    // Guest/offline — the profile hero hides the "Since ..." line instead
    // of guessing (documented contract of this provider).
    return null;
  }
});

final userNameProvider = StateProvider<String>((ref) {
  return ref.read(sharedPreferencesProvider).getString('user_name') ??
      'Learner';
});

/// Selected Lottie avatar id (see [kProfileAvatars]). Legacy emoji values
/// stored before the animation migration normalize to the default avatar.
final userAvatarIdProvider = StateProvider<String>((ref) {
  final stored = ref
      .read(sharedPreferencesProvider)
      .getString('user_avatar_id');
  return normalizeAvatarId(stored);
});

/// Catalog entries whose animation file is actually bundled. Premium pack
/// files appear here automatically once dropped into [avatarsAssetDir].
final availableAvatarsProvider = FutureProvider<List<ProfileAvatar>>((
  ref,
) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final bundled = manifest.listAssets().toSet();
  final available = kProfileAvatars
      .where((avatar) => bundled.contains(avatar.assetPath))
      .toList(growable: false);
  return available.isEmpty ? [kProfileAvatars.first] : available;
});

final userAvatarColorIndexProvider = StateProvider<int>((ref) {
  return ref.read(sharedPreferencesProvider).getInt('user_avatar_color') ?? 0;
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
