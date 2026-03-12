import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../models/invoice_model.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';

class RecentSalesSection extends StatelessWidget {
  final List<Invoice> recentInvoices;
  final Function(Invoice) onPrint;
  final Function(Invoice) onEdit;
  final Function(int, String) onCancel;

  const RecentSalesSection({
    super.key,
    required this.recentInvoices,
    required this.onPrint,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: AppTokens.cardElevation,
      margin: const EdgeInsets.only(top: AppTokens.spacingMedium),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(AppTokens.cardBorderRadius)),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(AppTokens.cardBorderRadius),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingStandard,
                  vertical: AppTokens.spacingSmall),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppTokens.cardBorderRadius),
                  topRight: Radius.circular(AppTokens.cardBorderRadius),
                ),
              ),
              width: double.infinity,
              child: Text(loc.recentSales,
                  style: textTheme.titleSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: recentInvoices.length,
                separatorBuilder: (c, i) =>
                    const Divider(height: AppTokens.dividerThickness),
                itemBuilder: (context, index) {
                  final invoice = recentInvoices[index];
                  final isCancelled = invoice.isCancelled;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingStandard),
                    leading: CircleAvatar(
                      radius: AppTokens.iconSizeSmall,
                      backgroundColor: isCancelled
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      child: Text('${index + 1}',
                          style: textTheme.labelSmall?.copyWith(
                              color: isCancelled
                                  ? colorScheme.onErrorContainer
                                  : colorScheme.onPrimaryContainer)),
                    ),
                    title: Text(
                      invoice.customerName ?? loc.walkInCustomer,
                      style: textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                            isCancelled ? TextDecoration.lineThrough : null,
                        color: isCancelled
                            ? colorScheme.onSurface.withValues(alpha: 0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(invoice.invoiceNumber,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Money(invoice.totalAmount).toString(),
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: AppTokens.spacingSmall),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              size: AppTokens.iconSizeMedium,
                              color: colorScheme.onSurfaceVariant),
                          padding: EdgeInsets.zero,
                          onSelected: (value) {
                            if (value == 'print') onPrint(invoice);
                            if (value == 'edit') onEdit(invoice);
                            if (value == 'cancel') {
                              onCancel(invoice.id!, invoice.invoiceNumber);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!isCancelled) ...[
                              PopupMenuItem(
                                  value: 'print',
                                  child: Row(children: [
                                    const Icon(Icons.print,
                                        size: AppTokens.iconSizeSmall),
                                    const SizedBox(
                                        width: AppTokens.spacingSmall),
                                    Text(loc.printReceipt, style: textTheme.bodyMedium)
                                  ])),
                              PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(children: [
                                    Icon(Icons.cancel,
                                        size: AppTokens.iconSizeSmall,
                                        color: colorScheme.error),
                                    const SizedBox(
                                        width: AppTokens.spacingSmall),
                                    Text(loc.cancel,
                                        style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.error))
                                  ])),
                            ] else ...[
                              PopupMenuItem(
                                  enabled: false,
                                  child: Text(loc.cancelled,
                                      style: textTheme.bodyMedium)),
                            ]
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
