import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/catalog_repository.dart';
import '../widgets/back_or_home_button.dart';

/// Lista de categorías.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({required this.catalog, super.key});

  final CatalogRepository catalog;

  @override
  Widget build(BuildContext context) {
    final categories = catalog.categories();
    return Scaffold(
      appBar: AppBar(
        leading: const BackOrHomeButton(),
        title: const Text('Categorías'),
      ),
      body: ListView(
        children: [
          for (final category in categories)
            ListTile(
              title: Text(category.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/categorias/${category.id}'),
            ),
        ],
      ),
    );
  }
}
