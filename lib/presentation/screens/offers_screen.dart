import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog_repository.dart';
import '../widgets/back_or_home_button.dart';
import '../widgets/product_tile.dart';

/// Productos con precio de oferta.
class OffersScreen extends StatelessWidget {
  const OffersScreen({required this.catalog, super.key});

  final CatalogRepository catalog;

  @override
  Widget build(BuildContext context) {
    final offers = catalog.offers();
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Ofertas'),
      ),
      body: ListView(
        children: [
          for (final product in offers)
            ProductTile(
              product: product,
              onTap: () => context.push('/productos/${product.id}'),
            ),
        ],
      ),
    );
  }
}
