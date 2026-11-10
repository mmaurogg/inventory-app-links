import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'models/cart_line.dart';
import 'models/product.dart';

/// Carrito en memoria. Conserva su contenido mientras la App permanece abierta.
///
/// Invariante: toda línea tiene `quantity >= 1` y no hay dos líneas con el
/// mismo producto.
class CartController extends ChangeNotifier {
  // LinkedHashMap por defecto: conserva el orden de inserción.
  final Map<String, CartLine> _lines = <String, CartLine>{};

  /// Vista inmutable de las líneas, en orden de inserción.
  List<CartLine> get lines => UnmodifiableListView<CartLine>(_lines.values);

  bool get isEmpty => _lines.isEmpty;

  /// Suma de subtotales usando el precio efectivo de cada producto.
  int get totalCents =>
      _lines.values.fold(0, (sum, line) => sum + line.subtotalCents);

  /// Suma 1 a la cantidad del producto o crea la línea con cantidad 1.
  void add(Product product) {
    final existing = _lines[product.id];
    _lines[product.id] = CartLine(
      product: existing?.product ?? product,
      quantity: (existing?.quantity ?? 0) + 1,
    );
    notifyListeners();
  }

  /// Quita la línea completa. Si el producto no está, no hace nada.
  void remove(String productId) {
    if (_lines.remove(productId) != null) {
      notifyListeners();
    }
  }
}
