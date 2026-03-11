import 'package:flutter/material.dart';
import '../../../core/res/app_tokens.dart';
import '../../../models/product_model.dart';
import '../../../core/utils/rtl_helper.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isFocused;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFocused = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: AppTokens.cardElevation,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardBorderRadius),
        side: BorderSide(
            color: isFocused
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.3),
            width: isFocused ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        hoverColor: colorScheme.primaryContainer.withOpacity(0.3),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: AppTokens.iconSizeSmall,
                          color: colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: AppTokens.spacingXSmall),
                      Flexible(
                        child: Text(
                          product.salePrice.toString(),
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacingXSmall),
                  Text(
                    RTLHelper.getLocalizedName(
                      context: context,
                      nameEnglish: product.nameEnglish,
                      nameUrdu: product.nameUrdu,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: AppTokens.spacingXSmall,
              right: AppTokens.spacingXSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingXSmall,
                    vertical: AppTokens.spacingXXSmall),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                      AppTokens.smallBorderRadius),
                ),
                child: Text(
                  '${product.currentStock}',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: product.isLowStock
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
