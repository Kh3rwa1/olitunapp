import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/interstitial_ad_manager.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Close button for Voice Studio. Leaving the studio is a natural break, so
/// an interstitial may show (frequency-capped) before the route pops.
class VoiceStudioCloseButton extends ConsumerWidget {
  const VoiceStudioCloseButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: CircleAvatar(
        radius: 22,
        backgroundColor: (isDark ? Colors.white : Colors.black).withValues(
          alpha: 0.1,
        ),
        child: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: isDark ? Colors.white : Colors.black,
            size: 20,
          ),
          tooltip: AppLocalizations.of(context)!.closeVoiceStudio,
          onPressed: () async {
            await ref
                .read(interstitialAdManagerProvider)
                .showIfAllowed(context, 'voice_exit');
            if (context.mounted) context.pop();
          },
        ),
      ),
    );
  }
}
