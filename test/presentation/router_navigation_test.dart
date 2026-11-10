import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_app_links/data/in_memory_catalog_repository.dart';
import 'package:inventory_app_links/domain/cart_controller.dart';
import 'package:inventory_app_links/presentation/router/app_router.dart';
import 'package:inventory_app_links/presentation/screens/not_found_screen.dart';

void main() {
  const catalog = InMemoryCatalogRepository();
  late CartController cart;
  late GoRouter router;

  setUp(() {
    cart = CartController();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    String initialLocation = '/',
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    router = buildRouter(catalog, cart, initialLocation: initialLocation);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  // Con `push` el provider no refleja la ubicación; la última coincidencia sí.
  String currentPath() =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  group('Rutas muestran su pantalla (3.1, 8.3)', () {
    testWidgets('/ muestra Home con accesos (3.2)', (tester) async {
      await pumpApp(tester);
      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Ofertas'), findsOneWidget);
      expect(find.text('Carrito'), findsOneWidget);
    });

    testWidgets('/categorias', (tester) async {
      await pumpApp(tester, initialLocation: '/categorias');
      expect(find.text('Categorías'), findsOneWidget);
      expect(find.text('Electrónica'), findsOneWidget);
      expect(find.text('Hogar'), findsOneWidget);
    });

    testWidgets('/categorias/electronica', (tester) async {
      await pumpApp(tester, initialLocation: '/categorias/electronica');
      expect(find.text('Electrónica'), findsOneWidget);
      expect(find.text('Smartwatch'), findsOneWidget);
      expect(find.text('Lámpara de escritorio'), findsNothing);
    });

    testWidgets('/productos/p1', (tester) async {
      await pumpApp(tester, initialLocation: '/productos/p1');
      expect(find.text('Audífonos inalámbricos'), findsWidgets);
    });

    testWidgets('/carrito', (tester) async {
      await pumpApp(tester, initialLocation: '/carrito');
      expect(find.text('Carrito'), findsOneWidget);
    });

    testWidgets('/ofertas', (tester) async {
      await pumpApp(tester, initialLocation: '/ofertas');
      expect(find.text('Ofertas'), findsOneWidget);
      expect(find.text('Audífonos inalámbricos'), findsOneWidget);
      expect(find.text('Smartwatch'), findsNothing);
    });
  });

  group('Navegación por taps (3.3, 3.4)', () {
    testWidgets('categoría navega con el id correcto', (tester) async {
      await pumpApp(tester, initialLocation: '/categorias');
      await tester.tap(find.text('Hogar'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/categorias/hogar');
      expect(find.text('Cafetera de goteo'), findsOneWidget);
    });

    testWidgets('producto navega con el id correcto', (tester) async {
      await pumpApp(tester, initialLocation: '/categorias/moda');
      await tester.tap(find.text('Jeans clásicos'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/productos/p8');
      expect(find.text('Jeans de corte recto en algodón.'), findsOneWidget);
    });

    testWidgets('Home navega a Ofertas desde el acceso', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Ofertas'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/ofertas');
    });
  });

  group('Detalle de producto (3.5)', () {
    testWidgets('producto en oferta muestra todos los datos', (tester) async {
      await pumpApp(tester, initialLocation: '/productos/p1');
      expect(find.text('Audífonos inalámbricos'), findsWidgets);
      expect(
        find.text('Audífonos Bluetooth con cancelación de ruido.'),
        findsOneWidget,
      );
      expect(find.text('Precio: \$199,000.00'), findsOneWidget);
      expect(find.text('Precio de oferta: \$159,000.00'), findsOneWidget);
      expect(find.text('Agregar al carrito'), findsOneWidget);
    });

    testWidgets('producto sin oferta no muestra precio de oferta',
        (tester) async {
      await pumpApp(tester, initialLocation: '/productos/p2');
      expect(find.text('Precio: \$299,000.00'), findsOneWidget);
      expect(find.textContaining('Precio de oferta'), findsNothing);
    });
  });

  group('Not found (3.6, 3.7, 10.4)', () {
    testWidgets('ruta desconocida muestra NotFoundScreen con acción a Home',
        (tester) async {
      await pumpApp(tester, initialLocation: '/ruta-que-no-existe');
      expect(find.byType(NotFoundScreen), findsOneWidget);
      await tester.tap(find.text('Ir al inicio'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/');
      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('producto inexistente', (tester) async {
      await pumpApp(tester, initialLocation: '/productos/no-existe');
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('categoría inexistente', (tester) async {
      await pumpApp(tester, initialLocation: '/categorias/no-existe');
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });

  group('Retroceso (3.8)', () {
    testWidgets('detalle como ubicación inicial: volver lleva a Home',
        (tester) async {
      await pumpApp(tester, initialLocation: '/productos/p1');
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/');
      expect(find.text('Tienda'), findsOneWidget);
    });

    testWidgets('con historial, volver regresa a la pantalla previa',
        (tester) async {
      await pumpApp(tester, initialLocation: '/categorias');
      await tester.tap(find.text('Hogar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/categorias');
    });
  });

  group('Carrito (4.3, 4.4)', () {
    testWidgets('carrito vacío muestra mensaje y acción a Home',
        (tester) async {
      await pumpApp(tester, initialLocation: '/carrito');
      expect(find.text('Tu carrito está vacío'), findsOneWidget);
      await tester.tap(find.text('Ir al inicio'));
      await tester.pumpAndSettle();
      expect(currentPath(), '/');
    });

    testWidgets('agregar desde detalle actualiza carrito y total',
        (tester) async {
      await pumpApp(tester, initialLocation: '/productos/p1');
      await tester.tap(find.text('Agregar al carrito'));
      await tester.pump();
      expect(find.text('Producto agregado al carrito'), findsOneWidget);
      expect(cart.lines.single.product.id, 'p1');

      router.go('/carrito');
      await tester.pumpAndSettle();
      expect(find.text('Tu carrito está vacío'), findsNothing);
      expect(find.text('Audífonos inalámbricos'), findsOneWidget);
      // Precio efectivo (oferta) en el total.
      expect(find.text('Total: \$159,000.00'), findsOneWidget);
    });
  });
}
