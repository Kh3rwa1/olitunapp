import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

int getResponsiveCrossAxisCount(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width > 1200) {
    return 6;
  } else if (width > 800) {
    return 4;
  } else if (width > 600) {
    return 3;
  } else {
    return 2;
  }
}

BoxDecoration contentCardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppColors.primary.withValues(alpha: 0.15),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class ContentNavArrow extends StatelessWidget {
  const ContentNavArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.primary,
      ),
    );
  }
}
