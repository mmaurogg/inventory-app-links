import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../domain/cart_controller.dart';
import '../../domain/catalog_repository.dart';

const String _playStoreUrl =
    'https://play.google.com/store/apps/details?id=REEMPLAZAR';
const String _appStoreUrl = 'https://apps.apple.com/app/idREEMPLAZAR';

/// Pantalla de inicio con accesos a categorías, ofertas y carrito.
class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.catalog, required this.cart, super.key});

  final CatalogRepository catalog;
  final CartController cart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tienda')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AccessTile(
            icon: Icons.category,
            label: 'Categorías',
            onTap: () => context.go('/categorias'),
          ),
          _AccessTile(
            icon: Icons.local_offer,
            label: 'Ofertas',
            onTap: () => context.go('/ofertas'),
          ),
          _AccessTile(
            icon: Icons.shopping_cart,
            label: 'Carrito',
            onTap: () => context.go('/carrito'),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 24),
            Text(
              'Descarga la app',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _StoreLink(label: 'Google Play', url: _playStoreUrl),
            const _StoreLink(label: 'App Store', url: _appStoreUrl),
          ],
        ],
      ),
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _StoreLink extends StatelessWidget {
  const _StoreLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: SelectableText(url),
      trailing: IconButton(
        icon: const Icon(Icons.copy),
        tooltip: 'Copiar enlace de $label',
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Clipboard.setData(ClipboardData(text: url));
          messenger.showSnackBar(
            SnackBar(content: Text('Enlace de $label copiado')),
          );
        },
      ),
    );
  }
}
