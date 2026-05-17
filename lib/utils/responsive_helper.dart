import 'package:flutter/material.dart';

class ResponsiveHelper {
  static const double mobileWidthThreshold = 600;
  static const double tabletWidthThreshold = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileWidthThreshold;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileWidthThreshold &&
      MediaQuery.of(context).size.width < tabletWidthThreshold;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletWidthThreshold;

  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 12;
    if (width < 600) return 16;
    if (width < 900) return 20;
    return 24;
  }

  static double getVerticalPadding(BuildContext context) {
    return getHorizontalPadding(context);
  }

  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 700) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  static double getTextScale(BuildContext context) {
    final density = MediaQuery.of(context).devicePixelRatio;
    final width = MediaQuery.of(context).size.width;

    // Para pantallas con alta densidad de píxeles como Xiaomi 15T
    if (density > 3 && width > 1080) {
      return 1.1; // Aumentar ligeramente los textos
    }
    return 1.0;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final padding = getHorizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: padding, vertical: padding);
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext) mobileBuilder;
  final Widget Function(BuildContext)? tabletBuilder;
  final Widget Function(BuildContext)? desktopBuilder;

  const ResponsiveLayout({
    required this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) && desktopBuilder != null) {
      return desktopBuilder!(context);
    }
    if (ResponsiveHelper.isTablet(context) && tabletBuilder != null) {
      return tabletBuilder!(context);
    }
    return mobileBuilder(context);
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final EdgeInsetsGeometry? padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final ScrollPhysics physics;

  const ResponsiveGridView({
    required this.children,
    this.crossAxisCount,
    this.padding,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 1.0,
    this.physics = const ScrollPhysics(),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount:
          crossAxisCount ?? ResponsiveHelper.getGridColumns(context),
      padding: padding,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      physics: physics,
      children: children,
    );
  }
}
