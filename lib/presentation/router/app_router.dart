import 'package:go_router/go_router.dart';

import '../../domain/cart_controller.dart';
import '../../domain/catalog_repository.dart';
import '../../domain/link_mapper.dart';
import '../screens/cart_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/category_screen.dart';
import '../screens/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/offers_screen.dart';
import '../screens/product_detail_screen.dart';

/// Construye el Router de la App con todas las rutas soportadas.
///
/// Las rutas inexistentes se resuelven con [NotFoundScreen] mediante
/// `errorBuilder`. [initialLocation] permite arrancar en otra ubicación.
GoRouter buildRouter(
  CatalogRepository catalog,
  CartController cart, {
  String initialLocation = '/',
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => HomeScreen(catalog: catalog, cart: cart),
      ),
      GoRoute(
        path: '/categorias',
        builder: (context, state) => CategoriesScreen(catalog: catalog),
      ),
      GoRoute(
        path: '/categorias/:categoriaId',
        builder: (context, state) => CategoryScreen(
          categoryId: state.pathParameters['categoriaId']!,
          catalog: catalog,
        ),
      ),
      GoRoute(
        path: '/productos/:productoId',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['productoId']!,
          catalog: catalog,
          cart: cart,
        ),
      ),
      GoRoute(
        path: '/carrito',
        builder: (context, state) => CartScreen(cart: cart),
      ),
      GoRoute(
        path: '/ofertas',
        builder: (context, state) => OffersScreen(catalog: catalog),
      ),
      GoRoute(
        path: LinkMapper.notFoundLocation,
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
}
