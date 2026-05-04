import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.05),
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
      child:
          child ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.width,
    this.height = 160,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton(width: width, height: height, borderRadius: borderRadius);
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Skeleton(width: 60, height: 60, borderRadius: 16),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(
                  width: double.infinity,
                  height: 18,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                Skeleton(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonGridItem extends StatelessWidget {
  const SkeletonGridItem({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Skeleton(width: double.infinity, borderRadius: 20),
        ),
        SizedBox(height: 12),
        Skeleton(width: 80, height: 16, borderRadius: 4),
        SizedBox(height: 6),
        Skeleton(width: 40, height: 12, borderRadius: 4),
      ],
    );
  }
}
