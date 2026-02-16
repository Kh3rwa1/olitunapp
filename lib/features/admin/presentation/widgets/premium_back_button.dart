import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PremiumBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const PremiumBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap ?? () => context.pop(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}
