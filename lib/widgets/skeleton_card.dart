import 'package:flutter/material.dart';
import '../config/theme.dart';

class _ShimmerPainter extends StatefulWidget {
  final Widget child;
  const _ShimmerPainter({required this.child});

  @override
  State<_ShimmerPainter> createState() => _ShimmerPainterState();
}

class _ShimmerPainterState extends State<_ShimmerPainter>
    with SingleTickerProviderStateMixin {
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
                Colors.white.withValues(alpha: 0.12),
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





class SkeletonTaskCard extends StatelessWidget {
  final double? width;
  final EdgeInsetsGeometry? margin;

  const SkeletonTaskCard({super.key, this.width, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      width: width,
      height: 88,
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BrainTheme.textTertiary.withValues(alpha: 0.08),
        ),
      ),
      child: _ShimmerPainter(
        child: Row(
          children: [
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: double.infinity, height: 12),
                    const SizedBox(height: 4),
                    _bar(width: 0.6, height: 9),
                    const Spacer(),
                    Row(
                      children: [
                        _bar(width: 50, height: 8),
                        const SizedBox(width: 12),
                        _bar(width: 70, height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width > 1 ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonProjectCard extends StatelessWidget {
  final double? width;
  final EdgeInsetsGeometry? margin;

  const SkeletonProjectCard({super.key, this.width, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.textTertiary.withValues(alpha: 0.08),
        ),
      ),
      child: _ShimmerPainter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: double.infinity, height: 14),
                      const SizedBox(height: 6),
                      _bar(width: 120, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bar(width: double.infinity, height: 10),
            const SizedBox(height: 6),
            _bar(width: 0.7, height: 10),
            const SizedBox(height: 14),
            _bar(width: double.infinity, height: 8),
            const SizedBox(height: 12),
            Row(
              children: [
                _bar(width: 80, height: 10),
                const Spacer(),
                _bar(width: 80, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width > 1 ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonGoalCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const SkeletonGoalCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.textTertiary.withValues(alpha: 0.08),
        ),
      ),
      child: _ShimmerPainter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: double.infinity, height: 14),
                      const SizedBox(height: 6),
                      _bar(width: 100, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _bar(width: double.infinity, height: 8),
            const SizedBox(height: 12),
            Row(
              children: [
                _bar(width: 100, height: 10),
                const Spacer(),
                _bar(width: 60, height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width > 1 ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonNoteCard extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const SkeletonNoteCard({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.textTertiary.withValues(alpha: 0.08),
        ),
      ),
      child: _ShimmerPainter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: double.infinity, height: 13),
                      const SizedBox(height: 4),
                      _bar(width: 80, height: 9),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bar(width: double.infinity, height: 9),
            const SizedBox(height: 4),
            _bar(width: 0.85, height: 9),
            const SizedBox(height: 4),
            _bar(width: 0.5, height: 9),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width > 1 ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonStatsGrid extends StatelessWidget {
  final int itemCount;

  const SkeletonStatsGrid({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: List.generate(itemCount, (_) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: BrainTheme.textTertiary.withValues(alpha: 0.08),
          ),
        ),
        child: _ShimmerPainter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: 38, height: 38),
              const Spacer(),
              _bar(width: 60, height: 24),
              const SizedBox(height: 4),
              _bar(width: double.infinity, height: 12),
              _bar(width: 100, height: 9),
              const SizedBox(height: 12),
              _bar(width: double.infinity, height: 3),
            ],
          ),
        ),
      )),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Keep backward compatibility with existing SkeletonCard
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
      child: _ShimmerPainter(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _bar(width: double.infinity, height: 14),
              const SizedBox(height: 8),
              _bar(width: 0.6, height: 10),
              const SizedBox(height: 12),
              Row(
                children: [
                  _bar(width: 60, height: 20),
                  const SizedBox(width: 6),
                  _bar(width: 50, height: 20),
                  const SizedBox(width: 6),
                  _bar(width: 70, height: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar({required double width, required double height}) {
    return Container(
      width: width > 1 ? width : null,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
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
