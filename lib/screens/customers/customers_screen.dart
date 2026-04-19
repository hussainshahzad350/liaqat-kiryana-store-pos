import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/repositories/customers_repository.dart';
import '../../core/repositories/invoice_repository.dart';
import '../../models/customer_model.dart';
import '../../l10n/app_localizations.dart';
import '../../core/res/app_tokens.dart';
import 'controller/customer_controller.dart';
import 'dialogs/add_customer_dialog.dart';
import 'dialogs/delete_customer_dialog.dart';
import 'widgets/customer_ledger_panel.dart';
import 'widgets/archived_customers_overlay.dart';
import 'widgets/customer_kpi_section.dart';
import 'widgets/customer_search_bar.dart';
import 'widgets/customer_list.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CustomerController(
        context.read<CustomersRepository>(),
      )..init(),
      child: const _CustomersScreenContent(),
    );
  }
}

class _CustomersScreenContent extends StatefulWidget {
  const _CustomersScreenContent();

  @override
  State<_CustomersScreenContent> createState() => _CustomersScreenContentState();
}

class _CustomersScreenContentState extends State<_CustomersScreenContent> {

  void _showAddDialog({Customer? customer}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCustomerDialog(
        customer: customer,
        repository: context.read<CustomersRepository>(),
        onSaved: () => context.read<CustomerController>().refresh(),
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final controller = context.read<CustomerController>();

    // Cannot delete with outstanding balance
    if (customer.outstandingBalance != 0) {
      await showDialog(
        context: context,
        builder: (_) => CannotDeleteDialog(
          onArchive: () => controller.toggleArchiveStatus(customer),
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDeleteDialog(),
    );

    if (confirmed != true) return;

    final success = await controller.deleteCustomer(customer);
    
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.itemDeleted),
          backgroundColor: colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<CustomerController>(
      builder: (context, controller, child) {
        return Stack(
          children: [
            // ── Main content ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingLarge),
              child: Column(
                children: [
                  // Toolbar
                  _buildToolbar(loc, colorScheme),
                  const SizedBox(height: AppTokens.spacingMedium),

                  // KPI cards
                  const CustomerKpiSection(),
                  const SizedBox(height: AppTokens.spacingMedium),

                  // Search bar
                  const CustomerSearchBar(),
                  const SizedBox(height: AppTokens.spacingMedium),

                  // Customer list
                  Expanded(
                    child: Card(
                      elevation: AppTokens.cardElevation,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
                        child: CustomerList(
                          onEdit: (c) => _showAddDialog(customer: c),
                          onDelete: (c) => _deleteCustomer(c),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Ledger overlay ─────────────────────────────────
            if (controller.ledgerCustomer != null)
              CustomerLedgerPanel(
                customer: controller.ledgerCustomer!,
                customersRepository: context.read<CustomersRepository>(),
                invoiceRepository: context.read<InvoiceRepository>(),
                onClose: controller.closeLedger,
                onDataChanged: () {
                  controller.refresh();
                  controller.refreshLedgerCustomer();
                },
              ),

            // ── Archive overlay ────────────────────────────────
            if (controller.showArchive)
              ArchivedCustomersOverlay(
                customers: controller.archivedCustomers,
                onClose: controller.closeArchiveView,
                onUnarchive: (c) {
                  controller.toggleArchiveStatus(c);
                  controller.closeArchiveView();
                },
                onDelete: _deleteCustomer,
                onLedger: (c) {
                  controller.closeArchiveView();
                  controller.openLedger(c);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(AppLocalizations loc, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
        vertical: AppTokens.spacingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Icons.add, size: AppTokens.iconSizeMedium),
            label: Text(loc.addCustomer),
          ),
        ],
      ),
    );
  }
}
