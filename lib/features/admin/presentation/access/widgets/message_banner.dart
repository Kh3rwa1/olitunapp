import 'package:flutter/material.dart';
import 'package:itun/core/theme/admin_tokens.dart';

class MessageBanner extends StatelessWidget {
  const MessageBanner({super.key, required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTokens.accentSoft(isDark),
        borderRadius: BorderRadius.circular(AdminTokens.radiusSm),
        border: Border.all(color: AdminTokens.accentBorder(isDark)),
      ),
      child: Text(message, style: AdminTokens.bodyStrong(isDark)),
    );
  }
}
