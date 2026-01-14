import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import 'product_card_mobile.dart';

class ProductGridMobile extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductTap;

  const ProductGridMobile({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCardMobile(
          product: product,
          onTap: () => onProductTap(product),
        );
      },
    );
  }
}
