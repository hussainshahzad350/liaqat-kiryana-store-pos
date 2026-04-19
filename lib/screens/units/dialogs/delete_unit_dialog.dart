import 'package:flutter/material.dart';
import '../../../../core/repositories/units_repository.dart';
import '../../../../models/unit_model.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';

class DeleteUnitDialog extends StatelessWidget {
  final Unit unit;
  final UnitsRepository repository;
  final VoidCallback onDeleteConfirmed;

  const DeleteUnitDialog({
    super.key,
    required this.unit,
    required this.repository,
    required this.onDeleteConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<int>(
      future: repository.checkUsage(unit.id),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final usageCount = snapshot.data ?? 0;
        final inUse = usageCount > 0;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          surfaceTintColor: colorScheme.surfaceTint,
          title: Row(
            children: [
              Icon(
                inUse ? Icons.warning_amber_rounded : Icons.delete_outline,
                color: inUse ? Colors.orange : colorScheme.error,
              ),
              const SizedBox(width: AppTokens.spacingMedium),
              Text(
                inUse ? 'Soft Delete Warning' : loc.confirm,
                style: textTheme.titleLarge,
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: isLoading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        inUse
                            ? 'The unit "${unit.name}" (${unit.code}) is used by $usageCount products or other units.'
                            : 'Are you sure you want to delete "${unit.name}" (${unit.code})?',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTokens.spacingMedium),
                      if (inUse)
                        Container(
                          padding: const EdgeInsets.all(AppTokens.spacingMedium),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(AppTokens.borderRadiusSmall),
                            border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            'It will be archived instead of deleted to maintain data integrity for current products.',
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
                          ),
                        )
                      else
                        Text(
                          'This action cannot be undone.',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            if (!isLoading)
              ElevatedButton(
                onPressed: () {
                  onDeleteConfirmed();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: inUse ? Colors.orange : colorScheme.error,
                  foregroundColor: inUse ? Colors.white : colorScheme.onError,
                ),
                child: Text(inUse ? 'Archive' : loc.yesDelete),
              ),
          ],
        );
      },
    );
  }
}
