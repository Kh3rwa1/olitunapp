import 'package:flutter/material.dart';
import 'package:itun/core/theme/admin_tokens.dart';

class InfoPill extends StatelessWidget {
  const InfoPill({
    super.key,
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminTokens.sunken(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AdminTokens.label(isDark)),
          const SizedBox(height: 2),
          SelectableText(value, style: AdminTokens.bodyStrong(isDark)),
        ],
      ),
    );
  }
}
