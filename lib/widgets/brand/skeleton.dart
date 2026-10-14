import 'package:flutter/material.dart';

import '../../theme/tokens.dart';

/// A soft light sweep across placeholder shapes while content loads. Still
/// when the system asks for reduced motion.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = colors.surfaceContainerHighest;
    final light = Color.lerp(base, colors.surfaceContainerLowest, 0.7)!;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value * 3 - 1;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(t - 1, -0.3),
            end: Alignment(t + 1, 0.3),
            colors: [base, light, base],
            stops: const [0.25, 0.5, 0.75],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}

/// One placeholder shape.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.small,
    this.circle = false,
  });
  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle ? null : BorderRadius.circular(radius),
    ),
  );
}

/// Screen readers hear "loading" once; the shapes themselves are hidden.
class _Loading extends StatelessWidget {
  const _Loading({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Semantics(
    label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
    child: ExcludeSemantics(child: Shimmer(child: child)),
  );
}

/// A placeholder in the shape of a profile (Discover).
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => _Loading(
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        AspectRatio(
          aspectRatio: AppSizes.portrait,
          child: SkeletonBox(radius: AppRadius.card),
        ),
        SizedBox(height: AppSpacing.l),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SkeletonBox(width: 180, height: 26),
        ),
        SizedBox(height: AppSpacing.s),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SkeletonBox(width: 140, height: 16),
        ),
      ],
    ),
  );
}

/// A placeholder grid of portrait tiles (Likes).
class PortraitGridSkeleton extends StatelessWidget {
  const PortraitGridSkeleton({super.key, this.count = 4});
  final int count;

  @override
  Widget build(BuildContext context) => _Loading(
    child: GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.l),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisSpacing: AppSpacing.l,
        crossAxisSpacing: AppSpacing.m,
        childAspectRatio: 0.62,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: AppSizes.portrait,
            child: SkeletonBox(radius: AppRadius.card),
          ),
          SizedBox(height: AppSpacing.s),
          SkeletonBox(width: 110, height: 16),
          SizedBox(height: AppSpacing.xs),
          SkeletonBox(width: 80, height: 12),
        ],
      ),
    ),
  );
}

/// A placeholder list of rows with an avatar (Chats, notifications).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) => _Loading(
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.l),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        child: Row(
          children: [
            SkeletonBox(width: 56, height: 56, circle: true),
            SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 16),
                  SizedBox(height: AppSpacing.s),
                  SkeletonBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
