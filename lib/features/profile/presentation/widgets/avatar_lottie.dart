import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../domain/entities/profile_avatar.dart';
import '../providers/profile_account_providers.dart';

/// Renders one avatar animation from the right source: bundled assets load
/// from the asset bundle, remote bucket entries load from cached or freshly
/// downloaded bytes. Failures degrade to [fallback], never to a blank box.
class AvatarLottie extends ConsumerWidget {
  const AvatarLottie({
    super.key,
    required this.avatar,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.animate = true,
    this.repeat,
    this.fallback,
  });

  final ProfileAvatar avatar;
  final double width;
  final double height;
  final BoxFit fit;
  final bool animate;
  final bool? repeat;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget errorBox(BuildContext context) =>
        fallback ??
        const Icon(Icons.person_rounded, size: 42, color: Colors.white70);

    if (!avatar.isRemote) {
      return Lottie.asset(
        avatar.assetPath,
        width: width,
        height: height,
        fit: fit,
        animate: animate,
        repeat: repeat ?? animate,
        errorBuilder: (_, _, _) => errorBox(context),
      );
    }

    final bytesAsync = ref.watch(avatarArtworkBytesProvider(avatar));
    return bytesAsync.when(
      data: (bytes) => Lottie.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        animate: animate,
        repeat: repeat ?? animate,
        errorBuilder: (_, _, _) => errorBox(context),
      ),
      loading: () => errorBox(context),
      error: (_, _) => Lottie.asset(
        kProfileAvatars.first.assetPath,
        width: width,
        height: height,
        fit: fit,
        animate: false,
        errorBuilder: (_, _, _) => errorBox(context),
      ),
    );
  }
}
