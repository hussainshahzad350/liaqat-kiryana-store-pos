import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
  });

  /// Single line of text
  const SkeletonLoader.text({super.key})
      : width = double.infinity, height = 14, borderRadius = 4;

  /// Title / heading bar
  const SkeletonLoader.title({super.key})
      : width = 200, height = 20, borderRadius = 4;

  /// Circular avatar
  const SkeletonLoader.avatar({super.key})
      : width = 40, height = 40, borderRadius = 20;

  /// Full card placeholder
  const SkeletonLoader.card({super.key})
      : width = double.infinity, height = 80, borderRadius = 10;

  /// Button placeholder
  const SkeletonLoader.button({super.key})
      : width = 120, height = 36, borderRadius = 8;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = colorScheme.surfaceContainerHighest;
    final highlight = colorScheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Sweep position moves from -1 to +2 across the widget
        final sweepPosition = -1.0 + (_controller.value * 3.0);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(sweepPosition - 1, 0),
              end: Alignment(sweepPosition + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}
