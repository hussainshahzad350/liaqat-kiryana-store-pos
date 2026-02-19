import 'package:flutter/material.dart';
import '../../../core/constants/desktop_dimensions.dart';
import '../../../models/product_model.dart';

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
      elevation: DesktopDimensions.cardElevation,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesktopDimensions.cardBorderRadius),
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
              padding: const EdgeInsets.all(DesktopDimensions.spacingSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: DesktopDimensions.iconSizeSmall,
                          color: colorScheme.primary.withOpacity(0.7)),
                      const SizedBox(width: DesktopDimensions.spacingXSmall),
                      Flexible(
                        child: Text(
                          product.salePrice.formatted,
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
                  const SizedBox(height: DesktopDimensions.spacingXSmall),
                  Text(
                    product.nameEnglish,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  if (product.nameUrdu != null && product.nameUrdu!.isNotEmpty)
                    Text(
                      product.nameUrdu!,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'NooriNastaleeq',
                        color: colorScheme.onSurfaceVariant,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
            Positioned(
              top: DesktopDimensions.spacingXSmall,
              right: DesktopDimensions.spacingXSmall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesktopDimensions.spacingXSmall,
                    vertical: DesktopDimensions.spacingXXSmall),
                decoration: BoxDecoration(
                  color: product.isLowStock
                      ? colorScheme.errorContainer
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(
                      DesktopDimensions.smallBorderRadius),
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
