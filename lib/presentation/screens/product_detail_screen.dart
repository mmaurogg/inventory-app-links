import 'package:flutter/material.dart';

import '../../domain/cart_controller.dart';
import '../../domain/catalog_repository.dart';
import '../widgets/back_or_home_button.dart';
import '../widgets/price_format.dart';
import 'not_found_screen.dart';

/// Detalle de producto. Muestra [NotFoundScreen] si el id no existe.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    required this.productId,
    required this.catalog,
    required this.cart,
    super.key,
  });

  final String productId;
  final CatalogRepository catalog;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    final product = catalog.productById(productId);
    if (product == null) {
      return const NotFoundScreen();
    }
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(product.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 16),
          if (product.isOnOffer) ...[
            Text(
              'Precio: ${formatCents(product.priceCents)}',
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
            Text(
              'Precio de oferta: ${formatCents(product.offerPriceCents!)}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else
            Text(
              'Precio: ${formatCents(product.priceCents)}',
              style: theme.textTheme.titleLarge,
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              cart.add(product);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Producto agregado al carrito')),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Agregar al carrito'),
          ),
        ],
      ),
    );
  }
}
