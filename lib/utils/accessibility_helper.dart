import 'package:flutter/material.dart';

class AccessibilityHelper {
  static double adjustedFontSize(BuildContext context, double baseSize) {
    final bold = MediaQuery.boldTextOf(context);
    return bold ? baseSize + 2 : baseSize;
  }

  static double adjustedIconSize(BuildContext context, double baseSize) {
    final bold = MediaQuery.boldTextOf(context);
    return bold ? baseSize + 4 : baseSize;
  }

  static EdgeInsets adjustedPadding(BuildContext context, EdgeInsets base) {
    final nav = MediaQuery.accessibleNavigationOf(context);
    if (!nav) return base;
    return base + const EdgeInsets.symmetric(vertical: 4, horizontal: 4);
  }

  static double adjustedTapTarget(BuildContext context, double minSize) {
    final nav = MediaQuery.accessibleNavigationOf(context);
    return nav ? 48.0 : minSize;
  }

  static Duration adjustedAnimationDuration(BuildContext context, Duration base) {
    final nav = MediaQuery.accessibleNavigationOf(context);
    return nav ? Duration.zero : base;
  }

  static bool shouldReduceAnimations(BuildContext context) {
    return MediaQuery.accessibleNavigationOf(context);
  }

  static Widget wrapWithMinTapTarget(Widget child, {double minSize = 48}) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: child,
    );
  }
}
