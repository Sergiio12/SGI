import 'package:flutter/material.dart';

class LoadingGlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  final double? left;
  final double? top;

  const LoadingGlowOrb({
    super.key,
    required this.size,
    required this.color,
    this.left,
    this.top,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
