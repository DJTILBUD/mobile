import 'package:flutter/material.dart';
import 'package:dj_tilbud_app/core/design_system/components.dart';

class SkeletonCard extends StatefulWidget {
  const SkeletonCard({super.key});

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE8E8E8),
                Color(0xFFF5F5F5),
                Color(0xFFE8E8E8),
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: child!,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DSSpacing.s4, vertical: 6),
        padding: const EdgeInsets.all(DSSpacing.s4),
        decoration: BoxDecoration(
          color: lightColors.bg.surface,
          borderRadius: BorderRadius.circular(DSRadius.md),
          border: Border.all(color: lightColors.border.subtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _bone(width: 120, height: 18),
                const Spacer(),
                _bone(width: 80, height: 14),
              ],
            ),
            const SizedBox(height: DSSpacing.s3),
            Row(
              children: [
                _bone(width: 16, height: 16, circular: true),
                const SizedBox(width: 6),
                _bone(width: 70, height: 14),
                const SizedBox(width: DSSpacing.s4),
                _bone(width: 16, height: 16, circular: true),
                const SizedBox(width: 6),
                _bone(width: 100, height: 14),
              ],
            ),
            const SizedBox(height: DSSpacing.s3),
            Row(
              children: [
                _bone(width: 90, height: 24, radius: 6),
                const SizedBox(width: DSSpacing.s2),
                _bone(width: 110, height: 24, radius: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bone({
    required double width,
    required double height,
    bool circular = false,
    double radius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: lightColors.bg.canvas,
        borderRadius: circular ? null : BorderRadius.circular(radius),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

class SkeletonListView extends StatelessWidget {
  const SkeletonListView({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: DSSpacing.s3),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}
