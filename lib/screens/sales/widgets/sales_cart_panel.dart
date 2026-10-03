import 'package:flutter/material.dart';

import '../../../core/res/app_tokens.dart';
import '../../../domain/entities/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/customer_model.dart';
import 'cart_item_row.dart';
import 'customer_section.dart';
import 'sales_totals_section.dart';

/// Customer selection, cart contents, and totals presentation for the POS.
class SalesCartPanel extends StatelessWidget {
  const SalesCartPanel({
    super.key,
    required this.customerSearchController,
    required this.discountController,
    required this.filteredCustomers,
    required this.showCustomerList,
    required this.selectedCustomerId,
    required this.cartItems,
    required this.isRTL,
    required this.subtotal,
    required this.discount,
    required this.previousBalance,
    required this.grandTotal,
    required this.onCustomerSearchChanged,
    required this.onCustomerSearchTap,
    required this.onSelectCustomer,
    required this.onAddCustomer,
    required this.onRemoveCartItem,
    required this.onUpdateCartItem,
    required this.onCheckout,
    required this.onDiscountChanged,
  });

  final TextEditingController customerSearchController;
  final TextEditingController discountController;
  final List<Customer> filteredCustomers;
  final bool showCustomerList;
  final int? selectedCustomerId;
  final List<CartItem> cartItems;
  final bool isRTL;
  final Money subtotal;
  final Money discount;
  final Money previousBalance;
  final Money grandTotal;
  final ValueChanged<String> onCustomerSearchChanged;
  final VoidCallback onCustomerSearchTap;
  final ValueChanged<Customer?> onSelectCustomer;
  final VoidCallback onAddCustomer;
  final ValueChanged<int> onRemoveCartItem;
  final void Function(int index, double quantity, Money price) onUpdateCartItem;
  final VoidCallback onCheckout;
  final ValueChanged<String> onDiscountChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return ColoredBox(
      color: colorScheme.surface,
      child: Column(
        children: [
          CustomerSection(
            searchController: customerSearchController,
            filteredCustomers: filteredCustomers,
            showCustomerList: showCustomerList,
            selectedCustomerId: selectedCustomerId,
            onSearchChanged: onCustomerSearchChanged,
            onSearchTap: onCustomerSearchTap,
            onSelectCustomer: onSelectCustomer,
            onAddCustomer: onAddCustomer,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _CartHeader(loc: loc, colorScheme: colorScheme),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Expanded(
            child: cartItems.isEmpty
                ? _EmptyCart(loc: loc, colorScheme: colorScheme)
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemBuilder: (context, index) => CartItemRow(
                      item: cartItems[index],
                      index: index,
                      isRTL: isRTL,
                      colorScheme: colorScheme,
                      onRemove: onRemoveCartItem,
                      onUpdate: onUpdateCartItem,
                    ),
                  ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          SalesTotalsSection(
            discountController: discountController,
            subtotal: subtotal,
            discount: discount,
            previousBalance: previousBalance,
            grandTotal: grandTotal,
            isCheckoutEnabled: cartItems.isNotEmpty,
            onCheckout: onCheckout,
            onDiscountChanged: onDiscountChanged,
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.loc, required this.colorScheme});

  final AppLocalizations loc;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
        );

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMedium,
      ),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(loc.item, style: labelStyle)),
          SizedBox(
            width: 70,
            child: Text(
              loc.price,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
          SizedBox(
            width: 60,
            child: Text(loc.qty, textAlign: TextAlign.center, style: labelStyle),
          ),
          const SizedBox(width: AppTokens.spacingMedium),
          SizedBox(
            width: 70,
            child: Text(loc.total, textAlign: TextAlign.end, style: labelStyle),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.loc, required this.colorScheme});

  final AppLocalizations loc;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTokens.spacingMedium),
          Text(
            loc.cartEmpty,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
