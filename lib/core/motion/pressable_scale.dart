import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'motion_tokens.dart';

/// One accessible action, with optional press motion and commit haptics.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = MotionTokens.pressedScale,
    this.haptic = HapticIntensity.light,
    this.enabled = true,
    this.behavior = HitTestBehavior.opaque,
    this.semanticLabel,
    this.focusColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HapticIntensity haptic;
  final bool enabled;
  final HitTestBehavior behavior;

  /// Optional replacement for the combined child label, for a single action.
  final String? semanticLabel;
  final Color? focusColor;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MotionTokens.quick,
    reverseDuration: MotionTokens.short,
  );
  bool _showFocus = false;
  bool _hasFocus = false;

  bool get _interactive =>
      widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  @override
  void didUpdateWidget(covariant PressableScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    if (!_interactive || widget.onTap == null) return;
    _fireHaptic();
    widget.onTap!();
  }

  void _commitLong() {
    if (!_interactive || widget.onLongPress == null) return;
    HapticFeedback.mediumImpact();
    widget.onLongPress!();
  }

  void _fireHaptic() {
    switch (widget.haptic) {
      case HapticIntensity.none:
        break;
      case HapticIntensity.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticIntensity.light:
        HapticFeedback.lightImpact();
        break;
      case HapticIntensity.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticIntensity.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = RespectMotion.of(context);
    final content = ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: widget.child,
    );

    return FocusableActionDetector(
      enabled: _interactive,
      includeFocusSemantics: false,
      mouseCursor: _interactive ? SystemMouseCursors.click : MouseCursor.defer,
      onFocusChange: (value) => setState(() => _hasFocus = value),
      onShowFocusHighlight: (value) => setState(() => _showFocus = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.onTap != null) {
              _commit();
            } else {
              _commitLong();
            }
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: _interactive,
        focusable: _interactive,
        focused: _hasFocus,
        label: widget.semanticLabel,
        excludeSemantics: widget.semanticLabel != null,
        onTap: _interactive && widget.onTap != null ? _commit : null,
        onLongPress: _interactive && widget.onLongPress != null
            ? _commitLong
            : null,
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: widget.behavior,
          onTapDown: _interactive && !reduce
              ? (_) => _controller.forward()
              : null,
          onTapUp: _interactive && !reduce
              ? (_) => _controller.reverse()
              : null,
          onTapCancel: _interactive && !reduce ? _controller.reverse : null,
          onTap: _interactive && widget.onTap != null ? _commit : null,
          onLongPress: _interactive && widget.onLongPress != null
              ? _commitLong
              : null,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _showFocus && _interactive
                  ? Border.all(
                      color:
                          widget.focusColor ??
                          Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: reduce
                ? content
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (_, child) {
                      final progress = MotionTokens.standard.transform(
                        _controller.value,
                      );
                      return Transform.scale(
                        scale: 1 + (widget.scale - 1) * progress,
                        child: child,
                      );
                    },
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }
}

enum HapticIntensity { none, selection, light, medium, heavy }
