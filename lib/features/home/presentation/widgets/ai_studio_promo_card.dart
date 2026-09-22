import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Home promo for the AI Studio: scan or speak, get Santali text.
/// Tapping opens `/studio`. Sits next to the AI Voice promo.
class AiStudioPromoCard extends StatelessWidget {
  const AiStudioPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final reduce = RespectMotion.of(context);

    final card = PressableScale(
      semanticLabel: 'AI Studio. Scan or speak — get Santali text.',
      onTap: () => context.push('/studio'),
      child: BentoCell(
        gradient: const LinearGradient(
          colors: [
            AppColors.santaliSalGreenLight,
            AppColors.santaliSalGreen,
            AppColors.santaliNightSky,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.bakhedGlowBlue,
            blurRadius: 32,
            offset: Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -26,
              child: IgnorePointer(
                child: Text(
                  'ᱚᱞ',
                  style: TextStyle(
                    fontFamily: 'OlChiki',
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        AppLocalizations.of(context)!.aiStudioPromoBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.aiStudioTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.4,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocalizations.of(context)!.aiStudioPromoSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return reduce ? card : card.animate().fadeIn(duration: 500.ms);
  }
}
