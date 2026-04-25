import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';

class SettingSection extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const SettingSection({
    super.key,
    required this.title,
    required this.child,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: AppTokens.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: colorScheme.primary, size: 24),
                  const SizedBox(width: AppTokens.spacingSmall),
                ],
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.spacingSmall),
              child: Divider(),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
