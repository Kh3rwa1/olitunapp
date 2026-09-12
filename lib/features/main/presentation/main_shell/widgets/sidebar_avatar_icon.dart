import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../profile/domain/entities/profile_avatar.dart';
import '../../../../profile/presentation/providers/profile_account_providers.dart';
import '../../../../profile/presentation/widgets/avatar_lottie.dart';

/// The learner's animated avatar for the desktop sidebar Profile row.
/// Mirrors the hero card at 42dp: user palette circle, Lottie animation,
/// name initial fallback. Unknown ids fall back to the default animation.
class SidebarAvatarIcon extends ConsumerWidget {
  const SidebarAvatarIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarId = ref.watch(userAvatarIdProvider);
    final avatarColors = ref.watch(userAvatarColorsProvider);
    final userName = ref.watch(userNameProvider);
    final isTransparent = avatarColors.every((color) => color.a == 0.0);

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: avatarColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: isTransparent ? Border.all(color: Colors.black12) : null,
      ),
      child: Center(
        child: usesProfileInitial(avatarId)
            ? Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'L',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              )
            : ClipOval(
                child: AvatarLottie(
                  avatar: profileAvatarById(avatarId) ?? kProfileAvatars.first,
                  width: 38,
                  height: 38,
                  fallback: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'L',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
