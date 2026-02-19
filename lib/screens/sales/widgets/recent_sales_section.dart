import 'package:flutter/material.dart';
import '../../../core/constants/desktop_dimensions.dart';
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
      elevation: DesktopDimensions.cardElevation,
      margin: const EdgeInsets.only(top: DesktopDimensions.spacingMedium),
      shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius)),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              BorderRadius.circular(DesktopDimensions.cardBorderRadius),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesktopDimensions.spacingStandard,
                  vertical: DesktopDimensions.spacingSmall),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(DesktopDimensions.cardBorderRadius),
                  topRight: Radius.circular(DesktopDimensions.cardBorderRadius),
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
                    const Divider(height: DesktopDimensions.dividerThickness),
                itemBuilder: (context, index) {
                  final invoice = recentInvoices[index];
                  final isCancelled = invoice.status == 'CANCELLED';
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesktopDimensions.spacingStandard),
                    leading: CircleAvatar(
                      radius: DesktopDimensions.iconSizeSmall,
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
                            ? colorScheme.onSurface.withOpacity(0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(invoice.invoiceNumber,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(Money(invoice.totalAmount).formatted,
                            style: textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: DesktopDimensions.spacingSmall),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert,
                              size: DesktopDimensions.iconSizeMedium,
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
                                        size: DesktopDimensions.iconSizeSmall),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
                                    Text(loc.printReceipt, style: textTheme.bodyMedium)
                                  ])),
                              PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    const Icon(Icons.edit,
                                        size: DesktopDimensions.iconSizeSmall),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
                                    Text(loc.editItem, style: textTheme.bodyMedium)
                                  ])),
                              PopupMenuItem(
                                  value: 'cancel',
                                  child: Row(children: [
                                    Icon(Icons.cancel,
                                        size: DesktopDimensions.iconSizeSmall,
                                        color: colorScheme.error),
                                    const SizedBox(
                                        width: DesktopDimensions.spacingSmall),
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
