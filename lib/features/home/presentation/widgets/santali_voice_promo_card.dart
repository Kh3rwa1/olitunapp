import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/motion.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/bento_grid.dart';

/// Bottom-of-home promo for the Santali AI Voice studio.
///
/// Loud on purpose: this is the viral surface. Tapping opens `/voice`.
class SantaliVoicePromoCard extends StatelessWidget {
  const SantaliVoicePromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = RespectMotion.of(context);

    final card = PressableScale(
      semanticLabel: 'Santali AI Voice. Type text, hear it in Santali, share the audio.',
      onTap: () => context.push('/voice'),
      child: BentoCell(
        gradient: const LinearGradient(
          colors: [Color(0xFF6D28D9), Color(0xFF4F46E5), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.violetGlow,
            blurRadius: 32,
            offset: Offset(0, 16),
            spreadRadius: -10,
          ),
        ],
        padding: const EdgeInsets.all(22),
        child: Stack(
          children: [
            // Giant Ol Chiki watermark.
            Positioned(
              right: -8,
              bottom: -26,
              child: IgnorePointer(
                child: Text(
                  'ᱨᱚᱲ',
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 12),
                          SizedBox(width: 5),
                          Text(
                            'NEW • SANTALI AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Icon(Icons.mic_rounded, color: Colors.white, size: 26),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Santali AI Voice',
                        style: TextStyle(
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
                  'Type anything — hear Phulmani or Sibu speak it. Save it. Share it.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Try now',
                            style: TextStyle(
                              color: AppColors.indigoVivid,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: AppColors.indigoVivid, size: 17),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ᱟᱲᱟᱝ • 15 styles',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: isDark ? 0.75 : 0.9),
                        fontFamily: 'OlChiki',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (reduce) return card;
    return card.animate().fadeIn(duration: 700.ms).slideY(begin: 0.12);
  }
}
