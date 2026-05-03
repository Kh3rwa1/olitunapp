import 'package:flutter/material.dart';
import '../motion/motion_tokens.dart';

/// A premium collapsing header used by detail screens.
///
/// Wraps a [SliverAppBar.large] with a [FlexibleSpaceBar] whose background
/// paints a brand gradient, a softly-faded glyph that parallax-scrolls
/// behind the title, and an optional centered hero illustration that lands
/// the shared-element transition from the previous screen.
///
/// Honors the OS reduce-motion setting via [RespectMotion]: when enabled,
/// the parallax + stretch effects are disabled so the header simply stays
/// put as the user scrolls.
class ParallaxHeroSliverAppBar extends StatelessWidget {
  const ParallaxHeroSliverAppBar({
    super.key,
    required this.gradient,
    this.glyph,
    this.title,
    this.leading,
    this.actions,
    this.heroChild,
    this.heroTag,
    this.expandedHeight = 280,
    this.foregroundColor = Colors.white,
    this.glyphColor = Colors.white,
  });

  final Gradient gradient;

  /// If provided, the gradient background is wrapped in a [Hero] with this
  /// tag so a shared-element transition from the previous screen lands
  /// cleanly on the expanded header.
  final Object? heroTag;

  /// Large background glyph (e.g. an Ol Chiki character or emoji) that
  /// shifts behind the title as the header collapses.
  final String? glyph;

  /// Title shown in the collapsed bar and at the bottom of the expanded
  /// header. Should be a [Text] for FlexibleSpaceBar styling.
  final Widget? title;

  final Widget? leading;
  final List<Widget>? actions;

  /// Centered hero artwork shown in the expanded header.
  /// Typically wrapped in a [Hero] by the caller.
  final Widget? heroChild;

  final double expandedHeight;
  final Color foregroundColor;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) {
    final reduce = RespectMotion.of(context);

    return SliverAppBar.large(
      pinned: true,
      stretch: !reduce,
      expandedHeight: expandedHeight,
      backgroundColor: gradient is LinearGradient
          ? (gradient as LinearGradient).colors.first
          : Colors.transparent,
      foregroundColor: foregroundColor,
      surfaceTintColor: Colors.transparent,
      leading: leading,
      actions: actions,
      iconTheme: IconThemeData(color: foregroundColor),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: reduce ? CollapseMode.none : CollapseMode.parallax,
        stretchModes: reduce
            ? const <StretchMode>[]
            : const <StretchMode>[
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
        titlePadding: const EdgeInsetsDirectional.only(
          start: 56,
          bottom: 16,
          end: 16,
        ),
        title: title == null
            ? null
            : DefaultTextStyle.merge(
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
                child: title!,
              ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (heroTag != null)
              Hero(
                tag: heroTag!,
                flightShuttleBuilder:
                    (
                      flightContext,
                      animation,
                      flightDirection,
                      fromHeroContext,
                      toHeroContext,
                    ) {
                      return Material(
                        color: Colors.transparent,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: gradient),
                  ),
                ),
              )
            else
              DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
            if (glyph != null && glyph!.isNotEmpty)
              Positioned(
                right: -28,
                bottom: -36,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.16,
                    child: Text(
                      glyph!,
                      style: TextStyle(
                        fontSize: 240,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: glyphColor,
                      ),
                    ),
                  ),
                ),
              ),
            if (heroChild != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 64),
                child: Center(child: heroChild!),
              ),
          ],
        ),
      ),
    );
  }
}
