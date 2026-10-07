import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/res/app_tokens.dart';
import '../../../widgets/app_state_view.dart';
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
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.surfaceRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.surfacePadding),
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
              if (products.isEmpty) {
                return AppStateView.empty(
                    message: loc.noData, icon: Icons.search_off);
              }
              final availableWidth = constraints.maxWidth;
              final crossAxisCount =
                  ((availableWidth + AppTokens.spacingStandard) /
                          (180 + AppTokens.spacingStandard))
                      .floor()
                      .clamp(1, 8);
              final tileWidth = (availableWidth -
                      (crossAxisCount - 1) * AppTokens.spacingStandard) /
                  crossAxisCount;
              final textTheme = Theme.of(context).textTheme;
              final textScaler = MediaQuery.textScalerOf(context);
              final direction = Directionality.of(context);
              final price = TextPainter(
                text: TextSpan(
                    text: '0.00',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
                textDirection: direction,
                textScaler: textScaler,
              )..layout();
              final name = TextPainter(
                text: TextSpan(
                    text: '${loc.item}\n${loc.item}',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    )),
                textDirection: direction,
                textScaler: textScaler,
              )..layout();
              final minimumHeight = 2 * AppTokens.spacingSmall +
                  math.max(AppTokens.iconSizeSmall, price.height) +
                  AppTokens.spacingXSmall +
                  name.height;
              price.dispose();
              name.dispose();

              return GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: AppTokens.spacingSmall,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: math.max(tileWidth * 9 / 16, minimumHeight),
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
