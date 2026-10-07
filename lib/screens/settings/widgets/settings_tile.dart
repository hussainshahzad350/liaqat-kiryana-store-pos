import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: AppTokens.relatedGap),
        child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTokens.surfacePadding,
                vertical: AppTokens.relatedGap),
            leading: Icon(icon, size: 24, color: colorScheme.primary),
            title: Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap));
  }
}
