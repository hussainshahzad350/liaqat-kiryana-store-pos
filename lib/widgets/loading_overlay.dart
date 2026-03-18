import 'package:flutter/material.dart';
import '../core/res/app_tokens.dart';
import '../l10n/app_localizations.dart';

class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingXLarge,
              vertical: AppTokens.spacingLarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: colorScheme.primary),
                const SizedBox(height: AppTokens.spacingMedium),
                Text(
                  message ?? loc.processing,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

