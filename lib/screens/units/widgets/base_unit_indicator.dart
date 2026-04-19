import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';

class BaseUnitIndicator extends StatelessWidget {
  const BaseUnitIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTokens.borderRadiusSmall),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          ),
          const SizedBox(width: AppTokens.spacingSmall),
          Text(
            'BASE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.amber[900],
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
