import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/res/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../controller/supplier_controller.dart';
import 'supplier_list_tile.dart';

class SupplierList extends StatelessWidget {
  final Function(dynamic) onEdit;
  final Function(dynamic) onDelete;

  const SupplierList({
    super.key, 
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return Center(child: CircularProgressIndicator(color: colorScheme.primary));
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
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingMedium),
                ElevatedButton.icon(
                  onPressed: () {
                    controller.clearError();
                    controller.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'), // Keeping standard english fallback
                )
              ],
            ),
          );
        }

        if (controller.activeSuppliers.isEmpty) {
          return Center(
            child: Text(
              loc.noSuppliersFound,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppTokens.spacingLarge),
          itemCount: controller.activeSuppliers.length,
          itemBuilder: (context, i) {
            final s = controller.activeSuppliers[i];
            final isSelected = controller.selectedIndex == i;

            return Container(
              color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
              child: MouseRegion(
                onEnter: (_) => controller.setSelectedIndex(i),
                child: SupplierListTile(
                  supplier: s,
                  onLedger: () => controller.openLedger(s),
                  onEdit: () => onEdit(s),
                  onArchive: () => controller.toggleArchiveStatus(s),
                  onDelete: () => onDelete(s),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
