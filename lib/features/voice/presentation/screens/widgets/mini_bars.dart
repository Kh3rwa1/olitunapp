import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Tiny animated equalizer bars — loading shimmer and now-playing pulse.
class MiniBars extends StatefulWidget {
  const MiniBars({
    super.key,
    required this.barCount,
    required this.height,
    this.animate = true,
    this.light = false,
  });

  final int barCount;
  final double height;
  final bool animate;
  final bool light;

  @override
  State<MiniBars> createState() => _MiniBarsState();
}

class _MiniBarsState extends State<MiniBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant MiniBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.barCount, (i) {
            final phase = (_controller.value * 2 + i / widget.barCount) % 1;
            final h =
                widget.height * 0.25 +
                widget.height *
                    0.75 *
                    (0.5 + 0.5 * (0.5 - (phase - 0.5).abs()) * 2).clamp(
                      0.0,
                      1.0,
                    );
            return Container(
              width: 3,
              height: widget.animate ? h : widget.height * 0.4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.light ? Colors.white : AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }
}
