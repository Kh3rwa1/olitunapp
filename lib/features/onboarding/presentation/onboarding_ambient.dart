import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/local_settings_provider.dart';

/// Shared ambient canvas for the onboarding flow: a deep gradient mesh,
/// a top glow orb, and large faint Ol Chiki glyphs drifting almost
/// imperceptibly — the same visual language as the splash screen, so the
/// whole first-run experience reads as one continuous premium space.
///
/// Motion honors the OS reduce-motion setting: glyphs render statically
/// and entrances collapse to fades.
class OnboardingAmbient extends ConsumerWidget {
  const OnboardingAmbient({
    super.key,
    required this.child,
    required this.isDark,
  });

  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Infinite drift loops never settle under pumpAndSettle, so they obey
    // the same reduce-effects flag the rest of the app uses (tests override
    // it; OS reduce-motion is honored too).
    final reduceMotion =
        ref.watch(reduceVisualEffectsProvider) ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  AppColors.onboardingMeshDarkStart,
                  AppColors.darkBackground,
                  AppColors.onboardingMeshDarkEnd,
                ]
              : const [
                  AppColors.onboardingMeshLightStart,
                  AppColors.lightBackground,
                  AppColors.onboardingMeshLightEnd,
                ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Top glow orb behind the header.
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            child: Center(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.10 : 0.07,
                      ),
                      blurRadius: 110,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Drifting background glyphs.
          ..._ambientGlyphs.map((g) {
            final glyph = ExcludeSemantics(
              child: Text(
                g.char,
                style: TextStyle(
                  fontFamily: 'OlChiki',
                  fontSize: g.size,
                  color: (isDark ? Colors.white : AppColors.primaryDark)
                      .withValues(alpha: isDark ? 0.05 : 0.06),
                ),
              ),
            );
            final placed = Positioned(
              left: g.x,
              top: g.y,
              child: Transform.rotate(angle: g.rotation, child: glyph),
            );
            if (reduceMotion) return placed;
            return placed
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: 0,
                  end: -10,
                  duration: g.period,
                  curve: Curves.easeInOut,
                )
                .fade(begin: 1, end: 0.75, duration: g.period);
          }),
          child,
        ],
      ),
    );
  }
}

/// Locale-neutral step eyebrow: "01 · 05". Numerals need no translation.
class OnboardingEyebrow extends StatelessWidget {
  const OnboardingEyebrow({
    super.key,
    required this.step,
    required this.stepCount,
    required this.isDark,
  });

  final int step;
  final int stepCount;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final current = (step + 1).toString().padLeft(2, '0');
    final total = stepCount.toString().padLeft(2, '0');
    return Text(
      '$current · $total',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 3.0,
        color: AppColors.primary.withValues(alpha: isDark ? 0.9 : 1.0),
      ),
    );
  }
}

class _AmbientGlyph {
  const _AmbientGlyph(
    this.char,
    this.x,
    this.y,
    this.size,
    this.rotation,
    this.period,
  );
  final String char;
  final double x;
  final double y;
  final double size;
  final double rotation;
  final Duration period;
}

// Fixed pixel offsets keep the composition stable across screen sizes;
// glyphs sit at the edges so they never collide with content.
const _ambientGlyphs = [
  _AmbientGlyph('ᱚ', 18, 130, 64, 0.18, Duration(milliseconds: 5200)),
  _AmbientGlyph('ᱥ', -24, 420, 96, -0.22, Duration(milliseconds: 6800)),
  _AmbientGlyph('ᱛ', 300, 96, 44, 0.3, Duration(milliseconds: 4700)),
  _AmbientGlyph('ᱜ', 330, 540, 72, -0.14, Duration(milliseconds: 6100)),
  _AmbientGlyph('ᱢ', 40, 660, 52, 0.24, Duration(milliseconds: 5600)),
];
