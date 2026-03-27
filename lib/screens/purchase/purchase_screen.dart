import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/error_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../models/product_model.dart';
import '../../bloc/purchase/purchase_bloc.dart';
import '../../bloc/purchase/purchase_event.dart';
import '../../bloc/purchase/purchase_state.dart';
import '../../widgets/loading_overlay.dart';
import 'widgets/purchase_item_list_widget.dart';
import 'widgets/purchase_cart_widget.dart';
import 'dialogs/add_purchase_item_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:liaqat_store/core/res/app_tokens.dart';
import '../../core/repositories/purchase_repository.dart';
import '../../core/repositories/suppliers_repository.dart';
import '../../core/repositories/items_repository.dart';
import '../../domain/entities/money.dart';
import '../../core/routes/app_routes.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    context.read<PurchaseBloc>().add(SubmitPurchase(
      invoiceNumber: _invoiceCtrl.text,
      notes: _notesCtrl.text,
    ));
  }

  void _cancel() {
    if (!context.mounted) return;
    Navigator.maybePop(context);
  }

  void _onProductTapped(Product p) {
    showDialog(
      context: context,
      builder: (_) => AddPurchaseItemDialog(
        product: p,
        onConfirm: (item) {
          if (!context.mounted) return;
          context.read<PurchaseBloc>().add(AddPurchaseItem(item));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyS, control: true):
            SavePurchaseIntent(),
        SingleActivator(LogicalKeyboardKey.keyI, control: true): AddItemIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SavePurchaseIntent: CallbackAction<SavePurchaseIntent>(onInvoke: (_) {
            _savePurchase();
            return null;
          }),
          AddItemIntent: CallbackAction<AddItemIntent>(onInvoke: (_) {
            _addItem();
            return null;
          }),
        },
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingMedium),
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectSupplier,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Supplier',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.cardBorderRadius)),
                              prefixIcon: const Icon(Icons.store),
                            ),
                            child: Text(
                              _selectedSupplier?['name_english'] ??
                                  'Select Supplier',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: _selectedSupplier == null
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.5)
                                        : colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingMedium),
                      Expanded(
                        child: TextField(
                          controller: _invoiceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Supplier Invoice #',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTokens.cardBorderRadius)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacingStandard),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _purchaseDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() => _purchaseDate = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Purchase Date',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.cardBorderRadius)),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                                DateFormat('yyyy-MM-dd').format(_purchaseDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingMedium),
                      Expanded(
                        child: TextField(
                          controller: _notesCtrl,
                          decoration: InputDecoration(
                            labelText: 'Notes',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTokens.cardBorderRadius)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: _cartItems.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: _addItem,
                        icon: Icon(Icons.add_circle_outline,
                            size: AppTokens.iconSizeXXLarge,
                            color: colorScheme.primary),
                        label: Text('Add Items',
                            style: Theme.of(context).textTheme.headlineSmall),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTokens.spacingMedium),
                      itemCount: _cartItems.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: colorScheme.outlineVariant),
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return ListTile(
                          title: Text(item['name'],
                              style: Theme.of(context).textTheme.bodyLarge),
                          subtitle: Text(
                            'Qty: ${item['quantity']} | Batch: ${item['batch_number'] ?? '-'} | Exp: ${item['expiry_date'] ?? '-'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Money(item['total_amount']).formattedNoDecimal,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: colorScheme.error),
                                onPressed: () => setState(
                                    () => _cartItems.removeAt(index)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingMedium),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: AppTokens.iconSizeLarge),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, AppTokens.buttonHeight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.buttonBorderRadius),
                      ),
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _savePurchase,
                    icon: const Icon(Icons.save, size: AppTokens.iconSizeLarge),
                    label: const Text('SAVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      minimumSize: const Size(0, AppTokens.buttonHeight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacingMedium),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.buttonBorderRadius),
                      ),
                      textStyle: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Text(
                    'Total: ${Money(_totalAmount.toInt()).formattedNoDecimal}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
