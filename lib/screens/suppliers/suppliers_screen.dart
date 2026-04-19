import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../core/res/app_tokens.dart';
import 'controller/supplier_controller.dart';
import 'widgets/supplier_search_bar.dart';
import 'widgets/supplier_kpi_section.dart';
import 'widgets/supplier_list.dart';
import 'widgets/supplier_ledger_panel.dart';
import 'widgets/archived_suppliers_overlay.dart';
import 'dialogs/add_supplier_dialog.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<SuppliersRepository>();

    return ChangeNotifierProvider(
      create: (context) {
        final controller = SupplierController(repository);
        controller.init();
        return controller;
      },
      child: const _SuppliersScreenContent(),
    );
  }
}

class _SuppliersScreenContent extends StatelessWidget {
  const _SuppliersScreenContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = context.watch<SupplierController>();
    final repository = context.read<SuppliersRepository>();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingLarge,
              vertical: AppTokens.spacingMedium),
          child: Column(
            children: [
              // Toolbar
              Container(
                margin: const EdgeInsets.only(bottom: AppTokens.spacingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AddSupplierDialog(
                            repository: repository,
                            onSaved: () => controller.refresh(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Supplier'), // Standard fallback
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),

              // KPI Section
              const SupplierKpiSection(),
              const SizedBox(height: AppTokens.spacingMedium),

              // Search Bar
              const SupplierSearchBar(),
              const SizedBox(height: AppTokens.spacingMedium),

              // List
              Expanded(
                child: SupplierList(
                  onEdit: (supplier) {
                    showDialog(
                      context: context,
                      builder: (_) => AddSupplierDialog(
                        supplier: supplier,
                        repository: repository,
                        onSaved: () => controller.refresh(),
                      ),
                    );
                  },
                  onDelete: (supplier) async {
                    // Logic from existing delete logic migrated into a localized dialog explicitly
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Confirm Delete',
                            style: Theme.of(context).textTheme.titleLarge),
                        content: Text(
                            'Are you sure you want to completely delete this supplier?',
                            style: Theme.of(context).textTheme.bodyMedium),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.error,
                              foregroundColor: colorScheme.onError,
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await controller.deleteSupplier(supplier);
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // Overlays
        if (controller.showArchive)
          ArchivedSuppliersOverlay(
            suppliers: controller.archivedSuppliers,
            onClose: () => controller.closeArchiveView(),
            onUnarchive: (supplier) {
              controller.toggleArchiveStatus(supplier);
              controller.closeArchiveView();
            },
            onDelete: (supplier) async {
              await controller.deleteSupplier(supplier);
              controller.refresh();
            },
            onLedger: (supplier) {
              controller.closeArchiveView();
              controller.openLedger(supplier);
            },
          ),

        if (controller.ledgerSupplier != null)
          SupplierLedgerPanel(
            supplier: controller.ledgerSupplier!,
            repository: repository,
            onClose: () => controller.closeLedger(),
            onDataChanged: () {
              controller.refreshLedgerSupplier();
              controller.loadStats();
            },
          ),
      ],
    );
  }
}
