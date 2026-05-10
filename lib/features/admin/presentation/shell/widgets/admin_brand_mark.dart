import 'package:flutter/material.dart';
import '../../../../../core/theme/admin_tokens.dart';
import '../../../../../core/theme/app_colors.dart';

class AdminBrandMark extends StatelessWidget {
  final double size;
  const AdminBrandMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AdminTokens.brandGlow(AppColors.primary, strength: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset('assets/icons/olitun_logo.png', fit: BoxFit.cover),
      ),
    );
  }
}
