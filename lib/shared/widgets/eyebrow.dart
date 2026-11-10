// One eyebrow style for the whole app: small caps, muted, no container.
// Section labels and card eyebrows used to each carry their own pill, border
// and colour; a single quiet label keeps the hierarchy calm.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.uppercase = true});

  final String text;

  /// Defaults to the muted slate (light) / white54 (dark).
  final Color? color;
  final bool uppercase;

  static TextStyle style(BuildContext context, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.2,
      height: 1.2,
      color: color ?? (isDark ? Colors.white54 : AppColors.webSlate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      uppercase ? text.toUpperCase() : text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style(context, color: color),
    );
  }
}
