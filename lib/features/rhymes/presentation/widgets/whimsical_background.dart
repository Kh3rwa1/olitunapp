import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/providers/local_settings_provider.dart';
import '../../../../shared/providers/providers.dart';

class WhimsicalBackground extends ConsumerStatefulWidget {
  final Widget child;
  const WhimsicalBackground({super.key, required this.child});

  @override
  ConsumerState<WhimsicalBackground> createState() =>
      _WhimsicalBackgroundState();
}

class _WhimsicalBackgroundState extends ConsumerState<WhimsicalBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceEffects = ref.watch(reduceVisualEffectsProvider);
    if (reduceEffects) {
      return widget.child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Exclude decorative animated background from accessibility tree
        ExcludeSemantics(
          child: Stack(
            children: [
              // Base Gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            AppColors.ambientIndigoDark,
                            AppColors.ambientDeepPurpleDark,
                          ]
                        : [
                            AppColors.ambientLightBlueTop,
                            AppColors.ambientLightBlueBottom,
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}
