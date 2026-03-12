import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/entity/stock_activity_entity.dart';
import '../../../core/res/app_tokens.dart';
import '../../../services/pdf_export_service.dart';

class ActivityDetailPanelWidget extends StatelessWidget {
  final StockActivityEntity activity;
  final VoidCallback onCancel;
  final PdfExportService pdfExportService;

  const ActivityDetailPanelWidget({
    super.key,
    required this.activity,
    required this.onCancel,
    required this.pdfExportService,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isCancelled = activity.isCancelled;

    return Column(
      children: [
        // Receipt Header
        Container(
          padding: const EdgeInsets.all(AppTokens.spacingMedium),
          color: colorScheme.surface,
          child: Column(
            children: [
              Icon(
                _getActivityIcon(activity.type),
                size: AppTokens.iconSizeXXLarge,
                color: isCancelled
                    ? colorScheme.onSurface.withValues(alpha: 0.5)
                    : colorScheme.primary,
              ),
              const SizedBox(height: AppTokens.spacingSmall),
              Text(
                activity.type.name.toUpperCase(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                activity.referenceNumber,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppTokens.spacingSmall),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingSmall,
                    vertical: AppTokens.spacingXSmall),
                decoration: BoxDecoration(
                  color: isCancelled
                      ? colorScheme.errorContainer
                      : colorScheme.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppTokens.extraSmallBorderRadius),
                ),
                child: Text(
                  activity.status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isCancelled
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Details List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.spacingMedium),
            children: [
              _buildDetailRow(context, loc.date,
                  DateFormat('yyyy-MM-dd').format(activity.timestamp)),
              _buildDetailRow(context, 
                  loc.time, DateFormat('hh:mm a').format(activity.timestamp)),
              _buildDetailRow(context, loc.customer, activity.user),
              const Divider(),
              _buildDetailRow(context, loc.description, activity.description),
              if (activity.quantityChange != 0)
                _buildDetailRow(context, loc.quantity,
                    '${activity.quantityChange > 0 ? '+' : ''}${activity.quantityChange}'),
              if (activity.financialImpact != null)
                _buildDetailRow(context, 
                    loc.amount, activity.financialImpact!.toString()),
            ],
          ),
        ),

        // Actions Footer
        Container(
          padding: const EdgeInsets.all(AppTokens.spacingMedium),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isCancelled &&
                  (activity.type == ActivityType.purchase ||
                      activity.type == ActivityType.sale))
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel),
                  label: Text(loc.cancel),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error),
                ),
              const SizedBox(height: AppTokens.spacingSmall),
              ElevatedButton.icon(
                onPressed: () async {
                  final locale = Localizations.localeOf(context);
                  try {
                    await pdfExportService.exportActivityPdf(activity,
                        languageCode: locale.languageCode);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.saveAsPdf)),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(loc.errorWithDetails(e.toString())),
                          backgroundColor: colorScheme.error),
                    );
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(loc.saveAsPdf),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant)),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.purchase:
        return Icons.shopping_cart;
      case ActivityType.sale:
        return Icons.sell;
      case ActivityType.adjustment:
        return Icons.tune;
      case ActivityType.returnIn:
        return Icons.keyboard_return;
      case ActivityType.returnOut:
        return Icons.outbound;
    }
  }
}
