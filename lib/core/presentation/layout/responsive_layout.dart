import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1100;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (isDesktop(context)) return 1120;
    if (isTablet(context)) return 900;
    return width;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 40, vertical: 28);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
  }

  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3}) {
    return isTablet(context) ? tablet : mobile;
  }
}

class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.padding,
  });

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
