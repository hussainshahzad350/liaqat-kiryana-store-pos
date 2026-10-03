import 'package:flutter/material.dart';

import '../../../core/res/app_layout.dart';
import '../../../core/res/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/invoice_model.dart';
import '../../../models/product_model.dart';
import 'product_card.dart';
import 'recent_sales_section.dart';

/// Search, product selection, and recent-sale presentation for the POS.
class SalesProductPanel extends StatelessWidget {
  const SalesProductPanel({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.products,
    required this.recentInvoices,
    required this.onSearchChanged,
    required this.onProductSelected,
    required this.onPrintInvoice,
    required this.onEditInvoice,
    required this.onCancelInvoice,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<Product> products;
  final List<Invoice> recentInvoices;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Product> onProductSelected;
  final ValueChanged<Invoice> onPrintInvoice;
  final ValueChanged<Invoice> onEditInvoice;
  final void Function(int id, String billNumber) onCancelInvoice;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Column(
      children: [
        Card(
          elevation: AppTokens.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.cardPadding),
            child: Focus(
              onFocusChange: (hasFocus) {
                if (hasFocus) searchFocusNode.requestFocus();
              },
              child: TextField(
                controller: searchController,
                focusNode: searchFocusNode,
                decoration: InputDecoration(
                  hintText: loc.searchItemHint,
                  isDense: true,
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppTokens.cardBorderRadius),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ),
                ),
                onChanged: onSearchChanged,
                onTap: () {
                  if (searchController.text.isNotEmpty) {
                    onSearchChanged(searchController.text);
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingMedium),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount =
                  AppLayout.productGridColumnCount(constraints.maxWidth);

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingMedium,
                  vertical: AppTokens.spacingSmall,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 16 / 9,
                  crossAxisSpacing: AppTokens.spacingStandard,
                  mainAxisSpacing: AppTokens.spacingStandard,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Focus(
                    child: Builder(
                      builder: (context) => ProductCard(
                        product: product,
                        isFocused: Focus.of(context).hasFocus,
                        onTap: () => onProductSelected(product),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        RecentSalesSection(
          recentInvoices: recentInvoices,
          onPrint: onPrintInvoice,
          onEdit: onEditInvoice,
          onCancel: onCancelInvoice,
        ),
      ],
    );
  }
}
