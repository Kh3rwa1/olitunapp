import 'package:flutter/material.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/theme/app_colors.dart';

class EmailAuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final Key? glowKey;

  const EmailAuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.glowKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fNode = focusNode;

    final field = TextField(
      controller: controller,
      focusNode: fNode,
      keyboardType: keyboardType,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
        letterSpacing: keyboardType == TextInputType.number ? 8 : 0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 15,
          letterSpacing: 0,
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white38 : Colors.black38,
          size: 22,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );

    final wrapped = Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: field,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        if (fNode != null)
          FocusGlowField(
            key: glowKey,
            focusNode: fNode,
            glowColor: AppColors.primary,
            child: wrapped,
          )
        else
          wrapped,
      ],
    );
  }
}
