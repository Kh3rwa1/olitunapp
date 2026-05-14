import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuizProgressBar extends StatelessWidget {
  final int current;
  final int total;
  final bool isDark;

  const QuizProgressBar({
    super.key,
    required this.current,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: current / total,
        backgroundColor: isDark ? Colors.white12 : Colors.black12,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        minHeight: 8,
      ),
    );
  }
}
