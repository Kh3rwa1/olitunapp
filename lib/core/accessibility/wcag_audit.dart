import 'dart:ui';
import 'dart:math' as math;

class WcagAudit {
  const WcagAudit._();

  static const double minTapTargetDp = 48;
  static const double normalTextContrast = 4.5;
  static const double largeTextContrast = 3;
  static const supportedTextScales = <double>[1, 1.2, 1.5, 2];

  static double contrastRatio(Color foreground, Color background) {
    final fg = _relativeLuminance(foreground);
    final bg = _relativeLuminance(background);
    final lighter = fg > bg ? fg : bg;
    final darker = fg > bg ? bg : fg;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool passesNormalText(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= normalTextContrast;
  }

  static bool passesLargeText(Color foreground, Color background) {
    return contrastRatio(foreground, background) >= largeTextContrast;
  }

  static bool hasMinimumTapTarget(Size size) {
    return size.width >= minTapTargetDp && size.height >= minTapTargetDp;
  }

  static double _relativeLuminance(Color color) {
    final r = _linearColorComponent(color.r);
    final g = _linearColorComponent(color.g);
    final b = _linearColorComponent(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearColorComponent(double component) {
    return component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
  }
}
