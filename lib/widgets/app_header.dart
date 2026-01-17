import 'package:flutter/material.dart';
import '../../core/constants/desktop_dimensions.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;

  const AppHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: DesktopDimensions.headerHeight,
      padding:
          const EdgeInsets.symmetric(horizontal: DesktopDimensions.spacingLarge),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon,
              color: colorScheme.onPrimary,
              size: DesktopDimensions.appTitleSize),
          const SizedBox(width: DesktopDimensions.spacingMedium),
          Text(
            title,
            style: TextStyle(
              fontSize: DesktopDimensions.appTitleSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimary,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(DesktopDimensions.headerHeight);
}
