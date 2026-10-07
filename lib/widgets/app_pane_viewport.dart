import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gives a dense desktop pane horizontal scrolling below its readable width.
/// Height stays bounded for the feature's Expanded/ListView children.
class AppPaneViewport extends StatelessWidget {
  const AppPaneViewport(
      {super.key, required this.minimumWidth, required this.child});
  final double minimumWidth;
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
              width: math.max(minimumWidth, constraints.maxWidth),
              height: constraints.maxHeight,
              child: child)));
}
