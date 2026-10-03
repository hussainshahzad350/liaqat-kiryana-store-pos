import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_model.dart';
import '../../../widgets/app_state_view.dart';
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

    return Consumer<CustomerController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const AppStateView.loading();
        }

        if (controller.errorMessage != null) {
          return AppStateView.error(
            message: controller.errorMessage!,
            actionLabel: loc.retry,
            onRetry: () {
              controller.clearError();
              controller.refresh();
            },
          );
        }

        if (controller.activeCustomers.isEmpty) {
          return AppStateView.empty(
            message: loc.noCustomersFound,
            icon: Icons.people_outline,
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
