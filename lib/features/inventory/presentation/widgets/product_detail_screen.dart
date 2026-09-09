import 'package:flutter/material.dart';

/// Screen displaying details of a single product.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: Center(
        child: Text('Product ID: $productId'),
        // TODO: Implement product detail with stock info
      ),
    );
  }
}
