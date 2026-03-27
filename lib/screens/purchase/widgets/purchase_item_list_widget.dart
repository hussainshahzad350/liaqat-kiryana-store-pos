import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/product_model.dart';
import '../../../../bloc/purchase/purchase_bloc.dart';
import '../../../../bloc/purchase/purchase_state.dart';

class PurchaseItemListWidget extends StatefulWidget {
  final List<int> cartItemIds;
  final ValueChanged<Product> onProductTapped;

  const PurchaseItemListWidget({
    super.key,
    required this.cartItemIds,
    required this.onProductTapped,
  });

  @override
  State<PurchaseItemListWidget> createState() => _PurchaseItemListWidgetState();
}

class _PurchaseItemListWidgetState extends State<PurchaseItemListWidget> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _query = val.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<PurchaseBloc, PurchaseState>(
      builder: (context, state) {
        final filtered = state.products.where((p) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          final name = p.nameEnglish.toLowerCase();
          final code = (p.itemCode ?? '').toLowerCase();
          return name.contains(q) || code.contains(q);
        }).toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: loc.searchItems,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                ),
              ),
            ),
            
            // List View
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(loc.noItemsFound))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final productId = product.id ?? 0;

                        final bool inCart = widget.cartItemIds.contains(productId);

                        // Badge logic
                        String badgeText;
                        Color badgeColor;
                        Color badgeTextColor;

                        if (product.currentStock <= 0) {
                          badgeText = loc.outOfStock;
                          badgeColor = colorScheme.errorContainer;
                          badgeTextColor = colorScheme.onErrorContainer;
                        } else if (product.isLowStock) {
                          badgeText = loc.lowStock;
                          badgeColor = colorScheme.tertiaryContainer;
                          badgeTextColor = colorScheme.onTertiaryContainer;
                        } else {
                          final fmtStock = (product.currentStock % 1 == 0)
                              ? product.currentStock.toInt().toString()
                              : product.currentStock.toStringAsFixed(2);
                          badgeText = fmtStock;
                          badgeColor = colorScheme.primaryContainer;
                          badgeTextColor = colorScheme.onPrimaryContainer;
                        }

                        return ListTile(
                          tileColor: inCart
                              ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                              : null,
                          title: Text(
                            product.nameEnglish,
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: product.itemCode != null && product.itemCode!.isNotEmpty
                              ? Text(
                                  product.itemCode!,
                                  style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              badgeText,
                              style: textTheme.labelSmall?.copyWith(
                                color: badgeTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => widget.onProductTapped(product),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
