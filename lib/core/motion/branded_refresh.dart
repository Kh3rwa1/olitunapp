import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'motion_tokens.dart';

/// [RefreshIndicator] with an Ol Chiki "ᱚ" glyph spinning behind it.
class BrandedRefreshIndicator extends StatelessWidget {
  const BrandedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.primary;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: tint,
      backgroundColor: Theme.of(context).colorScheme.surface,
      strokeWidth: 2.5,
      displacement: 56,
      child: child,
    ).withGlyphRefresh(tint: tint);
  }
}

extension _GlyphRefreshExt on Widget {
  Widget withGlyphRefresh({required Color tint}) {
    return Stack(children: [
      this,
      Positioned(
        top: 12,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(child: _BrandedGlyph(color: tint)),
        ),
      ),
    ]);
  }
}

class _BrandedGlyph extends StatefulWidget {
  const _BrandedGlyph({required this.color});
  final Color color;

  @override
  State<_BrandedGlyph> createState() => _BrandedGlyphState();
}

class _BrandedGlyphState extends State<_BrandedGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (RespectMotion.of(context)) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) => Transform.rotate(
        angle: _ctl.value * math.pi * 2,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: 0.10),
          ),
          alignment: Alignment.center,
          child: Text(
            'ᱚ',
            style: TextStyle(
              color: widget.color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'OlChiki',
            ),
          ),
        ),
      ),
    );
  }
}
