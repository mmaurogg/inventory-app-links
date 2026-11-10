import 'product.dart';

/// Línea del carrito: un producto con su cantidad.
class CartLine {
  const CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  int get subtotalCents => product.effectivePriceCents * quantity;
}
