import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';

class InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const InfoItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSmall / 2),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: AppTokens.spacingSmall),
          ],
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
