import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/accessibility/wcag_audit.dart';
import '../../../core/motion/motion_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'button_tokens.dart';

/// A keyboard-accessible primary action with a wrapping, persistent label.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 58,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _LearningButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      width: width,
      height: height,
      foreground: AppColors.elevatedButtonFg,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDisabled || isLoading ? null : AppColors.buttonShadow,
      ),
    );
  }
}

/// A raised action whose foreground is chosen from its actual opaque surface.
class DuoButton extends StatelessWidget {
  const DuoButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = AppColors.primary,
    this.shadowColor,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
  });

  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color? shadowColor;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final surface = Color.alphaBlend(
      color,
      Theme.of(context).colorScheme.surface,
    );
    final foreground =
        WcagAudit.contrastRatio(Colors.black, surface) >=
            WcagAudit.contrastRatio(Colors.white, surface)
        ? Colors.black
        : Colors.white;
    return _LearningButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isDisabled: isDisabled,
      icon: icon,
      width: width,
      height: height,
      borderRadius: borderRadius,
      foreground: foreground,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color:
                shadowColor ??
                (color == AppColors.primary
                    ? AppColors.primaryDark
                    : surface.withValues(alpha: 0.7)),
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _LearningButton extends StatelessWidget {
  const _LearningButton({
    required this.text,
    required this.onPressed,
    required this.isLoading,
    required this.isDisabled,
    required this.icon,
    required this.width,
    required this.height,
    required this.foreground,
    required this.decoration,
    this.borderRadius = 16,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final double? width;
  final double height;
  final Color foreground;
  final BoxDecoration decoration;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final enabled = !isDisabled && !isLoading;
    final reduce = RespectMotion.of(context);
    final loadingLabel =
        AppLocalizations.of(context)?.joharLoading ?? 'Loading';

    return Semantics(
      liveRegion: isLoading,
      child: SizedBox(
        width: width ?? double.infinity,
        child: DecoratedBox(
          decoration: decoration,
          child: ElevatedButton(
            onPressed: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed();
                  }
                : null,
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(foreground),
              backgroundColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              shadowColor: const WidgetStatePropertyAll(Colors.transparent),
              surfaceTintColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              elevation: const WidgetStatePropertyAll(0),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed) ||
                    states.contains(WidgetState.hovered) ||
                    states.contains(WidgetState.focused)) {
                  // State feedback increases, rather than reduces, contrast.
                  return (foreground.computeLuminance() > 0.5
                          ? Colors.black
                          : Colors.white)
                      .withValues(alpha: 0.08);
                }
                return Colors.transparent;
              }),
              minimumSize: WidgetStatePropertyAll(
                Size(48, height < 48 ? 48 : height),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              tapTargetSize: MaterialTapTargetSize.padded,
              animationDuration: reduce ? Duration.zero : MotionTokens.quick,
              splashFactory: reduce ? NoSplash.splashFactory : null,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              side: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.focused)
                    ? BorderSide(color: foreground, width: 3)
                    : BorderSide.none;
              }),
            ),
            child: Semantics(
              label: isLoading ? '$text. $loadingLabel' : text,
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    if (reduce)
                      Icon(Icons.hourglass_top_rounded, color: foreground)
                    else
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: foreground,
                          strokeWidth: 2.5,
                        ),
                      ),
                    const SizedBox(width: 10),
                  ] else if (icon != null) ...[
                    Icon(icon, color: foreground, size: 22),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
