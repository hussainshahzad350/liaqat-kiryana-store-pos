import 'package:flutter/material.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../core/res/app_tokens.dart';

class CustomerListTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onLedger;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const CustomerListTile({
    super.key,
    required this.customer,
    required this.onLedger,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    final balance = Money(customer.outstandingBalance);
    final name = isUrdu && (customer.nameUrdu?.isNotEmpty ?? false)
        ? customer.nameUrdu!
        : customer.nameEnglish;

    return Card(
      elevation: AppTokens.cardElevation,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingStandard,
          vertical: AppTokens.spacingSmall,
        ),
        dense: true,
        leading: CircleAvatar(
          radius: AppTokens.iconSizeMedium,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style:
              (isUrdu ? textTheme.titleLarge : textTheme.bodyMedium)?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: isUrdu ? 'NooriNastaleeq' : null,
            height: isUrdu ? 1.2 : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.contactPrimary ?? '',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            if (customer.creditLimit > 0)
              Text(
                '${loc.creditLimit}: ${Money(customer.creditLimit)}',
                style:
                    textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (balance != Money.zero)
              Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingSmall),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingSmall,
                  vertical: AppTokens.spacingXSmall,
                ),
                decoration: BoxDecoration(
                  color: balance > Money.zero
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppTokens.buttonBorderRadius),
                  border: Border.all(
                    color: balance > Money.zero
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
                child: Text(
                  balance.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    color: balance > Money.zero
                        ? colorScheme.error
                        : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              icon: Icon(Icons.receipt_long, color: colorScheme.primary),
              tooltip: loc.viewLedgerTooltip,
              onPressed: onLedger,
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'archive') onArchive();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit,
                          size: AppTokens.iconSizeSmall,
                          color: colorScheme.onSurface),
                      const SizedBox(width: AppTokens.spacingSmall),
                      Text(loc.editAction,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive,
                          size: AppTokens.iconSizeSmall,
                          color: colorScheme.onSurface),
                      const SizedBox(width: AppTokens.spacingSmall),
                      Text(loc.archiveAction,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete,
                          size: AppTokens.iconSizeSmall,
                          color: colorScheme.error),
                      const SizedBox(width: AppTokens.spacingSmall),
                      Text(loc.deleteAction,
                          style: textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
