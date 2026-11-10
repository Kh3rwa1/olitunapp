// Loading placeholders for Home (stats card block and the category grid).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/presentation/layout/responsive_layout.dart';

class HomeStatsSkeleton extends StatelessWidget {
  const HomeStatsSkeleton({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    return Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .fade(begin: 0.4, end: 0.8, duration: 800.ms);
  }
}

class HomeGridSkeleton extends StatelessWidget {
  const HomeGridSkeleton({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fill = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.03);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveLayout.isDesktop(context)
            ? 4
            : (ResponsiveLayout.isTablet(context) ? 3 : 2),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(20),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(begin: 0.4, end: 0.8, duration: 800.ms);
      },
    );
  }
}
