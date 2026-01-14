import 'package:flutter/material.dart';
import '../../../models/product_model.dart';

class ProductCardMobile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCardMobile({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(product.nameEnglish, textAlign: TextAlign.center),
            Text(product.salePrice.toString()),
          ],
        ),
      ),
    );
  }
}
