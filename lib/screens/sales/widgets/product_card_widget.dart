import 'package:flutter/material.dart';
import '../../../domain/entities/money.dart';
import '../../../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isRTL = Directionality.of(context) == TextDirection.rtl;

    final String name = (isRTL && product.nameUrdu.trim().isNotEmpty)
        ? product.nameUrdu
        : product.nameEnglish;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: isDark
                    ? colorScheme.surfaceVariant
                    : colorScheme.secondaryContainer,
                child: Center(
                  child: Text(
                    name.substring(0, 1),
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: colorScheme.onSecondaryContainer),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Money(product.salePrice).toString(),
                    style: theme.textTheme.titleSmall
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
