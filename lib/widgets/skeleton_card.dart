import 'package:flutter/material.dart';
import '../config/theme.dart';

class SkeletonCard extends StatelessWidget {
  final double height;
  final double width;
  final EdgeInsetsGeometry? margin;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 10),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: BrainTheme.textTertiary.withValues(alpha: 0.08),
        ),
      ),
      child: _Shimmer(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBar(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              _shimmerBar(width: 0.6, height: 10),
              const SizedBox(height: 12),
              Row(
                children: [
                  _shimmerBar(width: 60, height: 20, borderRadius: 7),
                  const SizedBox(width: 6),
                  _shimmerBar(width: 50, height: 20, borderRadius: 7),
                  const SizedBox(width: 6),
                  _shimmerBar(width: 70, height: 20, borderRadius: 7),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBar({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width > 1 ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(brightnessQualifier(borderRadius)),
      ),
    );
  }

  double brightnessQualifier(double value) => value;
}

class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 120,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(height: itemHeight),
    );
  }
}

class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double itemHeight;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.itemHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => SkeletonCard(
        height: itemHeight,
        margin: EdgeInsets.zero,
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  final Widget child;

  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}
