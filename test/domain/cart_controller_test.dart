import 'package:glados/glados.dart';
import 'package:inventory_app_links/domain/cart_controller.dart';
import 'package:inventory_app_links/domain/models/product.dart';

/// Configuración común: mínimo 100 iteraciones por propiedad.
final _config = ExploreConfig(numRuns: 100);

/// Generadores reutilizables para las propiedades del carrito (8, 9 y 10).
extension CartGenerators on Any {
  /// Producto con id de un conjunto pequeño (para forzar repeticiones),
  /// precio > 0 y, opcionalmente, precio de oferta con 0 < oferta < precio.
  Generator<Product> get product => combine4(
        intInRange(0, 6),
        intInRange(2, 100000),
        intInRange(1, 100),
        this.bool,
        (int idNumber, int price, int offerPercent, bool hasOffer) {
          final offer = (price * offerPercent) ~/ 100;
          return Product(
            id: 'p$idNumber',
            name: 'Producto $idNumber',
            description: 'Descripción $idNumber',
            priceCents: price,
            categoryId: 'c${idNumber % 3}',
            offerPriceCents: hasOffer && offer > 0 && offer < price
                ? offer
                : null,
          );
        },
      );

  /// Secuencia de productos a agregar para construir un carrito arbitrario.
  Generator<List<Product>> get productSequence => list(product);
}

/// Construye un carrito agregando cada producto en orden.
CartController buildCart(List<Product> products) {
  final cart = CartController();
  products.forEach(cart.add);
  return cart;
}

/// Cantidad por id de producto en el carrito.
Map<String, int> quantities(CartController cart) => {
      for (final line in cart.lines) line.product.id: line.quantity,
    };

/// Operación sobre el carrito: agregar o eliminar un producto.
class _CartOp {
  const _CartOp({required this.isAdd, required this.product});

  final bool isAdd;
  final Product product;

  @override
  String toString() => '${isAdd ? 'add' : 'remove'}(${product.id}, '
      'price: ${product.priceCents}, offer: ${product.offerPriceCents})';
}

/// Generador de secuencias de operaciones agregar/eliminar.
final Generator<List<_CartOp>> _anyOps = any.list(
  any.combine2(
    any.bool,
    any.product,
    (bool isAdd, Product product) => _CartOp(isAdd: isAdd, product: product),
  ),
);

void main() {
  group('CartController', () {
    // Feature: ecommerce-dynamic-links, Property 8: Agregar incrementa la
    // cantidad
    // **Validates: Requirements 4.1**
    Glados2<List<Product>, Product>(
      any.productSequence,
      any.product,
      _config,
    ).test(
      'agregar incrementa en 1 la cantidad del producto y no altera los demás',
      (initial, added) {
        final cart = buildCart(initial);
        final before = quantities(cart);

        cart.add(added);
        final after = quantities(cart);

        expect(after[added.id], (before[added.id] ?? 0) + 1);
        for (final entry in before.entries) {
          if (entry.key != added.id) {
            expect(after[entry.key], entry.value);
          }
        }
        expect(
          after.keys.toSet(),
          {...before.keys, added.id},
        );
      },
    );

    // Feature: ecommerce-dynamic-links, Property 9: Eliminar quita la línea
    // **Validates: Requirements 4.2**
    Glados2<List<Product>, Product>(
      any.productSequence,
      any.product,
      _config,
    ).test(
      'eliminar quita la línea del producto y deja intactas las demás',
      (initial, target) {
        // Garantiza que el producto objetivo tenga línea en el carrito.
        final cart = buildCart([...initial, target]);
        final before = quantities(cart);

        cart.remove(target.id);
        final after = quantities(cart);

        expect(after.containsKey(target.id), isFalse);
        expect(
          after.keys.toSet(),
          before.keys.toSet()..remove(target.id),
        );
        for (final entry in after.entries) {
          expect(entry.value, before[entry.key]);
        }
      },
    );

    // Feature: ecommerce-dynamic-links, Property 10: Total del carrito
    // **Validates: Requirements 4.3, 10.3**
    Glados<List<_CartOp>>(_anyOps, _config).test(
      'totalCents = suma de cantidad × (oferta ?? precio) tras agregar/eliminar',
      (ops) {
        final cart = CartController();
        // Modelo independiente: id -> (producto conservado, cantidad).
        final model = <String, ({Product product, int qty})>{};

        for (final op in ops) {
          if (op.isAdd) {
            cart.add(op.product);
            final current = model[op.product.id];
            model[op.product.id] = (
              product: current?.product ?? op.product,
              qty: (current?.qty ?? 0) + 1,
            );
          } else {
            cart.remove(op.product.id);
            model.remove(op.product.id);
          }
        }

        var expected = 0;
        for (final entry in model.values) {
          final unit =
              entry.product.offerPriceCents ?? entry.product.priceCents;
          expected += entry.qty * unit;
        }

        expect(cart.totalCents, expected);
      },
    );
  });
}
