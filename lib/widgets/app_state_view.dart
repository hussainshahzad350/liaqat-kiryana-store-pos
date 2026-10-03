import 'package:flutter/material.dart';

import '../core/res/app_tokens.dart';

/// Shared full-area feedback for loading, empty, and recoverable error states.
class AppStateView extends StatelessWidget {
  const AppStateView._({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
    this.isError = false,
  });

  const AppStateView.loading({String? message})
      : this._(
          icon: null,
          message: message,
          showProgress: true,
        );

  const AppStateView.empty({
    required String message,
    IconData icon = Icons.inbox_outlined,
  }) : this._(icon: icon, message: message);

  const AppStateView.error({
    required String message,
    String? actionLabel,
    VoidCallback? onRetry,
  }) : this._(
          icon: Icons.error_outline,
          message: message,
          actionLabel: actionLabel,
          onAction: onRetry,
          isError: true,
        );

  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foregroundColor =
        isError ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              CircularProgressIndicator(color: colorScheme.primary)
            else if (icon != null)
              Icon(
                icon,
                size: AppTokens.iconSizeXXLarge,
                color: foregroundColor,
              ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppTokens.spacingMedium),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: foregroundColor,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: AppTokens.spacingMedium),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
