import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;
  static const double wideBreakpoint = 1440;

  // Desktop sidebar widths — tuned for premium web rhythm:
  // 268px nav rail + 324px stats rail + 880px learning canvas.
  static const double leftSidebarWidth = 268;
  static const double rightSidebarWidth = 324;
  static const double collapsedSidebarWidth = 80;

  /// Bottom clearance (dp, excluding the OS gesture inset) consumed by the
  /// floating glass navigation (80 nav + 15 margin + 8 breathing room).
  /// Floating snackbars must add it to their bottom margin; bottom sheets
  /// must open above it via `useRootNavigator: true`.
  static const double floatingNavClearance = 103.0;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint;

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wideBreakpoint) return 880; // Premium learning canvas
    if (isDesktop(context)) return 860;
    if (isTablet(context)) return 900;
    return width;
  }

  /// Narrow canvas for focused flows (lesson player, quiz, study cards).
  static double maxNarrowWidth(BuildContext context) {
    if (isDesktop(context)) return 720;
    if (isTablet(context)) return 680;
    return MediaQuery.sizeOf(context).width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isWide(context)) {
      return const EdgeInsets.symmetric(horizontal: 44, vertical: 36);
    }
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 36, vertical: 32);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  }

  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}

class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsivePageContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: ResponsiveLayout.maxContentWidth(context),
        ),
        child: Padding(
          padding: padding ?? ResponsiveLayout.pagePadding(context),
          child: child,
        ),
      ),
    );
  }
}
