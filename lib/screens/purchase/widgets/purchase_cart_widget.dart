import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../bloc/purchase/purchase_bloc.dart';
import '../../../../bloc/purchase/purchase_event.dart';
import '../../../../bloc/purchase/purchase_state.dart';
import '../dialogs/supplier_selector_dialog.dart';

class PurchaseCartWidget extends StatefulWidget {
  final TextEditingController invoiceCtrl;
  final TextEditingController notesCtrl;
  final DateTime purchaseDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onSave;

  const PurchaseCartWidget({
    super.key,
    required this.invoiceCtrl,
    required this.notesCtrl,
    required this.purchaseDate,
    required this.onDateChanged,
    required this.onSave,
  });

  @override
  State<PurchaseCartWidget> createState() => _PurchaseCartWidgetState();
}

class _PurchaseCartWidgetState extends State<PurchaseCartWidget> {
  void _clearCart(PurchaseState state) {
    if (state.cartItems.isEmpty) return;
    for (int i = state.cartItems.length - 1; i >= 0; i--) {
      context.read<PurchaseBloc>().add(RemovePurchaseItem(i));
    }
  }

  void _openSupplierSelector(PurchaseState state) {
    showDialog(
      context: context,
      builder: (_) => SupplierSelectorDialog(
        suppliers: state.suppliers,
        onSelected: (supplier) {
          if (!context.mounted) return;
          context.read<PurchaseBloc>().add(SelectPurchaseSupplier(supplier['id'] as int));
        },
      ),
    );
  }

  Widget _buildSupplierSelector(BuildContext context, PurchaseState state, AppLocalizations loc) {
    final selectedId = state.selectedSupplierId;
    Map<String, dynamic>? selectedSupp;
    if (selectedId != null) {
      try {
        selectedSupp = state.suppliers.firstWhere((s) => s['id'] == selectedId);
      } catch (_) {}
    }

    if (selectedSupp == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _openSupplierSelector(state),
          icon: const Icon(Icons.person_add),
          label: Text(loc.selectSupplier),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _openSupplierSelector(state),
      borderRadius: BorderRadius.circular(4.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: loc.supplier,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        ),
        child: Row(
          children: [
            const Icon(Icons.business),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                selectedSupp['name_english'] as String? ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                if (!context.mounted) return;
                context.read<PurchaseBloc>().add(const ClearPurchaseSupplier());
              },
              tooltip: loc.clearSelection,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<PurchaseBloc, PurchaseState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1: Supplier header
            _buildSupplierSelector(context, state, loc),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.invoiceCtrl,
                    decoration: InputDecoration(
                      labelText: loc.supplierInvoiceNumber,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: widget.purchaseDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        if (!context.mounted) return;
                        widget.onDateChanged(date);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: loc.purchaseDate,
                        border: const OutlineInputBorder(),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('yyyy-MM-dd').format(widget.purchaseDate)),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: widget.notesCtrl,
              decoration: InputDecoration(
                labelText: loc.notesOptionalLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24.0),

            // SECTION 2: Bill items label + count
            Row(
              children: [
                Text(loc.billItems, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    state.cartItems.length.toString(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Divider(),

            // SECTION 3: Cart items list (Expanded)
            Expanded(
              child: state.cartItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_checkout, 
                            size: 64, 
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            loc.addItemsToStart, 
                            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: state.cartItems.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = state.cartItems[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${item.quantity} × Rs ${item.costPrice.formattedSmart}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Rs ${item.totalAmount.formattedSmart}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                tooltip: loc.remove,
                                onPressed: () {
                                  if (!context.mounted) return;
                                  context.read<PurchaseBloc>().add(RemovePurchaseItem(index));
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            const SizedBox(height: 16.0),

            // SECTION 4: Totals
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.totalItems, style: textTheme.bodyLarge),
                    Text(state.cartItems.length.toString(), style: textTheme.bodyLarge),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.totalPayable, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      state.totalAmount.formatted,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // SECTION 5: Footer
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                      color: state.cartItems.isEmpty ? Colors.transparent : colorScheme.error,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  ),
                  onPressed: state.cartItems.isEmpty ? null : () => _clearCart(state),
                  child: Text(loc.clearAll),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    onPressed: state.status == PurchaseStatus.submitting ? null : widget.onSave,
                    icon: state.status == PurchaseStatus.submitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                        : const Icon(Icons.save),
                    label: Text(loc.savePurchase),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
