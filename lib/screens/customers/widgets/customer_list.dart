import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/customer_model.dart';
import '../controller/customer_controller.dart';
import 'customer_list_tile.dart';

class CustomerList extends StatelessWidget {
  final void Function(Customer) onEdit;
  final void Function(Customer) onDelete;

  const CustomerList({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<CustomerController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: colorScheme.primary));
        }

        if (controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: AppTokens.spacingMedium),
                Text(
                  controller.errorMessage!,
                  style:
                      textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingMedium),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.clearError();
                    controller.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: Text(loc.retry),
                )
              ],
            ),
          );
        }

        if (controller.activeCustomers.isEmpty) {
          return Center(
            child: Text(
              loc.noCustomersFound,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppTokens.spacingLarge),
          itemCount: controller.activeCustomers.length,
          itemBuilder: (context, i) {
            final c = controller.activeCustomers[i];
            final isSelected = controller.selectedIndex == i;

            return Container(
              color: isSelected
                  ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
              child: MouseRegion(
                onEnter: (_) => controller.setSelectedIndex(i),
                child: CustomerListTile(
                  customer: c,
                  onLedger: () => controller.openLedger(c),
                  onEdit: () => onEdit(c),
                  onArchive: () => controller.toggleArchiveStatus(c),
                  onDelete: () => onDelete(c),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
