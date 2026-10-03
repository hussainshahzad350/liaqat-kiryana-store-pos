import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_state_view.dart';
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

    return Consumer<SupplierController>(
      builder: (context, controller, child) {
        final suppliers = controller.visibleSuppliers;

        if (controller.isLoading) {
          return const AppStateView.loading();
        }

        if (controller.listErrorMessage != null) {
          return AppStateView.error(
            message: controller.listErrorMessage!,
            actionLabel: loc.retry,
            onRetry: () {
              controller.clearError();
              controller.refresh();
            },
          );
        }

        if (suppliers.isEmpty) {
          return AppStateView.empty(
            message: loc.noSuppliersFound,
            icon: Icons.local_shipping_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: AppTokens.spacingLarge),
          itemCount: suppliers.length,
          itemBuilder: (context, i) {
            final s = suppliers[i];
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
