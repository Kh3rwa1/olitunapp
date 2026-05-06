import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

/// Animated music icon with layered glow rings for the rhyme header.
class AnimatedMusicIcon extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;
  const AnimatedMusicIcon({
    super.key,
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final pulse = 0.8 + 0.2 * math.sin(controller.value * 2 * math.pi);
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 64 * pulse,
                  height: 64 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.1 * pulse),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 52 * pulse,
                  height: 52 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.15 * pulse),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: math.sin(controller.value * 2 * math.pi) * 0.15,
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            );
          },
        )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack);
  }
}

/// Animated filter chip with bounce + glow for category/subcategory filtering.
class AnimatedFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool small;

  const AnimatedFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.small = false,
  });

  @override
  State<AnimatedFilterChip> createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<AnimatedFilterChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.92,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _scale = 0.92);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.small ? 14 : 20,
            vertical: widget.small ? 8 : 12,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primary
                : (widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white),
            borderRadius: BorderRadius.circular(widget.isSelected ? 16 : 24),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (widget.isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.06)),
              width: 1.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                      spreadRadius: -4,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: GoogleFonts.fredoka(
              fontSize: widget.small ? 12 : 14,
              fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
              color: widget.isSelected
                  ? Colors.white
                  : (widget.isDark ? Colors.white60 : Colors.black54),
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
