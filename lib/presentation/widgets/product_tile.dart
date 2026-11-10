import 'package:flutter/material.dart';

import '../../domain/models/product.dart';
import 'price_format.dart';

/// Fila de producto con nombre y precio (con precio regular tachado si hay oferta).
class ProductTile extends StatelessWidget {
  const ProductTile({required this.product, required this.onTap, super.key});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective = formatCents(product.effectivePriceCents);

    return ListTile(
      title: Text(product.name),
      subtitle: product.isOnOffer
          ? Row(
              children: [
                Text(
                  formatCents(product.priceCents),
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  effective,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(effective),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
