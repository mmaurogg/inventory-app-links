import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog_repository.dart';
import '../widgets/back_or_home_button.dart';
import '../widgets/product_tile.dart';
import 'not_found_screen.dart';

/// Productos de una categoría. Muestra [NotFoundScreen] si no existe.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    required this.categoryId,
    required this.catalog,
    super.key,
  });

  final String categoryId;
  final CatalogRepository catalog;

  @override
  Widget build(BuildContext context) {
    final category = catalog.categoryById(categoryId);
    if (category == null) {
      return const NotFoundScreen();
    }
    final products = catalog.productsByCategory(categoryId);
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: Text(category.name),
      ),
      body: ListView(
        children: [
          for (final product in products)
            ProductTile(
              product: product,
              onTap: () => context.push('/productos/${product.id}'),
            ),
        ],
      ),
    );
  }
}
