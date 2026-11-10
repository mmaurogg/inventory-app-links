import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'data/app_links_source.dart';
import 'data/in_memory_catalog_repository.dart';
import 'domain/cart_controller.dart';
import 'domain/catalog_repository.dart';
import 'presentation/link_handler.dart';
import 'presentation/router/app_router.dart';

/// Raíz de la App: crea catálogo, carrito, Router y el [LinkHandler].
class EcommerceApp extends StatefulWidget {
  const EcommerceApp({
    super.key,
    this.catalog,
    this.cart,
    this.linkSource,
    this.initialLocation = '/',
  });

  /// Catálogo a usar; por defecto [InMemoryCatalogRepository].
  final CatalogRepository? catalog;

  /// Carrito a usar; por defecto se crea uno nuevo.
  final CartController? cart;

  /// Fuente de enlaces; por defecto [AppLinksSource].
  final LinkSource? linkSource;

  /// Ubicación inicial del Router.
  final String initialLocation;

  @override
  State<EcommerceApp> createState() => _EcommerceAppState();
}

class _EcommerceAppState extends State<EcommerceApp> {
  late final CatalogRepository _catalog;
  late final CartController _cart;
  late final bool _ownsCart;
  late final GoRouter _router;
  LinkHandler? _linkHandler;

  @override
  void initState() {
    super.initState();
    _catalog = widget.catalog ?? const InMemoryCatalogRepository();
    _ownsCart = widget.cart == null;
    _cart = widget.cart ?? CartController();
    _router = buildRouter(
      _catalog,
      _cart,
      initialLocation: widget.initialLocation,
    );

    // En Web el navegador entrega la URL al Router; no se usa app_links.
    if (!kIsWeb) {
      _linkHandler = LinkHandler(
        source: widget.linkSource ?? AppLinksSource(),
        onNavigate: _router.go,
      );
      _linkHandler!.start();
    }
  }

  @override
  void dispose() {
    _linkHandler?.dispose();
    _router.dispose();
    if (_ownsCart) {
      _cart.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tienda',
      routerConfig: _router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
    );
  }
}
