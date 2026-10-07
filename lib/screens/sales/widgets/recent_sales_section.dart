import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../widgets/app_state_view.dart';
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
      elevation: 0,
      margin: const EdgeInsets.only(top: AppTokens.relatedGap),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.surfaceRadius)),
      child: ExpansionTile(
        dense: true,
        tilePadding:
            const EdgeInsets.symmetric(horizontal: AppTokens.surfacePadding),
        title: Text(loc.recentSales, style: textTheme.titleSmall),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${recentInvoices.length}', style: textTheme.labelMedium),
          const SizedBox(width: AppTokens.relatedGap),
          const Icon(Icons.unfold_more, size: AppTokens.iconSizeMedium),
        ]),
        children: [
          SizedBox(
            height: 180,
            child: recentInvoices.isEmpty
                ? AppStateView.empty(
                    message: loc.noData, icon: Icons.receipt_long_outlined)
                : ListView.separated(
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
                            style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
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
                                        Flexible(
                                            child: Text(loc.printReceipt,
                                                style: textTheme.bodyMedium))
                                      ])),
                                  PopupMenuItem(
                                      value: 'cancel',
                                      child: Row(children: [
                                        Icon(Icons.cancel,
                                            size: AppTokens.iconSizeSmall,
                                            color: colorScheme.error),
                                        const SizedBox(
                                            width: AppTokens.spacingSmall),
                                        Flexible(
                                            child: Text(loc.cancel,
                                                style: textTheme.bodyMedium
                                                    ?.copyWith(
                                                        color:
                                                            colorScheme.error)))
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
    );
  }
}
