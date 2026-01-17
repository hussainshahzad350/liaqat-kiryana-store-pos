import 'package:flutter/material.dart';
import 'package:liaqat_store/core/res/app_dimensions.dart';
import 'main_layout.dart';

class BaseScreen extends StatelessWidget {
  final String currentRoute;
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const BaseScreen({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MainLayout(
      currentRoute: currentRoute,
      child: Column(
        children: [
          Container(
            height: AppDimensions.headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const Spacer(),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}