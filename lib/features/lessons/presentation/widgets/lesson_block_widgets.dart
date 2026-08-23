import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/local_settings_provider.dart';

/// Load-error surface for the lesson block detail screen.
class DetailLoadErrorBlock extends StatelessWidget {
  const DetailLoadErrorBlock({
    super.key,
    required this.title,
    required this.isDark,
    required this.onBack,
  });

  final String title;
  final bool isDark;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 22),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class SoundWaveIndicator extends ConsumerStatefulWidget {
  final Color color;
  final bool isPlaying;

  const SoundWaveIndicator({
    super.key,
    required this.color,
    required this.isPlaying,
  });

  @override
  ConsumerState<SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends ConsumerState<SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(SoundWaveIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    final reduceMotion = ref.read(reduceVisualEffectsProvider);
    if (widget.isPlaying && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(reduceVisualEffectsProvider);
    if (widget.isPlaying && !reduceMotion) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }

    if (!widget.isPlaying) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          5,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 3,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final val = (index == 0 || index == 4)
                ? 0.3
                : (index == 1 || index == 3)
                ? 0.6
                : 0.9;
            final animatedValue = 6 + (20 * val * _controller.value);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3,
              height: animatedValue.clamp(6.0, 24.0),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class Tactile3DButton extends StatefulWidget {
  const Tactile3DButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.color,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color color;

  @override
  State<Tactile3DButton> createState() => Tactile3DButtonState();
}

class Tactile3DButtonState extends State<Tactile3DButton> {
  bool _isPressed = false;
  static const double buttonHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final hasCallback = widget.onPressed != null;
    final buttonColor = hasCallback ? widget.color : Colors.grey.shade400;

    // Darker shade for the 3D bottom base shadow
    final hsl = HSLColor.fromColor(buttonColor);
    final darkColor = hsl
        .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
        .toColor();

    const shadowHeight = 4.0;
    final pushOffset = _isPressed ? 3.0 : 0.0;

    return GestureDetector(
      onTapDown: hasCallback
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _isPressed = true);
            }
          : null,
      onTapUp: hasCallback
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: hasCallback
          ? () {
              setState(() => _isPressed = false);
            }
          : null,
      child: SizedBox(
        height: buttonHeight + shadowHeight,
        child: Stack(
          children: [
            // Darker 3D Base
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: buttonHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: darkColor,
                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                ),
              ),
            ),
            // Sliding Top Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              top: pushOffset,
              left: 0,
              right: 0,
              height: buttonHeight,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      buttonColor,
                      HSLColor.fromColor(buttonColor)
                          .withLightness((hsl.lightness - 0.05).clamp(0.0, 1.0))
                          .toColor(),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                  boxShadow: _isPressed
                      ? []
                      : [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Center(child: widget.child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LessonBlockWatermarkPainter extends CustomPainter {
  final String text;
  final TextStyle style;

  LessonBlockWatermarkPainter({required this.text, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant LessonBlockWatermarkPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.style != style;
  }
}
