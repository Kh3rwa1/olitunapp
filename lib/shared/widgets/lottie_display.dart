import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable widget for rendering Lottie animations from network URLs.
/// Falls back to a placeholder on error or while loading.
class LottieDisplay extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;
  final Widget? placeholder;
  final Widget? errorWidget;

  const LottieDisplay({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      url,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      animate: animate,
      frameBuilder: (context, child, composition) {
        if (composition == null) {
          return placeholder ?? _buildLoadingPlaceholder();
        }
        return child;
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildLoadingPlaceholder() {
    return SizedBox(
      width: width ?? 48,
      height: height ?? 48,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return SizedBox(
      width: width ?? 48,
      height: height ?? 48,
      child: const Center(
        child: Icon(Icons.animation, color: Colors.grey, size: 24),
      ),
    );
  }
}
