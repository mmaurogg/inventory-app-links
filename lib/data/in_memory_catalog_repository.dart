import '../domain/catalog_repository.dart';
import '../domain/models/category.dart';
import '../domain/models/product.dart';

/// Catálogo de ejemplo en memoria. Sin red ni almacenamiento persistente.
class InMemoryCatalogRepository implements CatalogRepository {
  const InMemoryCatalogRepository();

  static const List<Category> _categories = [
    Category(id: 'electronica', name: 'Electrónica'),
    Category(id: 'hogar', name: 'Hogar'),
    Category(id: 'moda', name: 'Moda'),
    Category(id: 'deportes', name: 'Deportes'),
  ];

  static const List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Audífonos inalámbricos',
      description: 'Audífonos Bluetooth con cancelación de ruido.',
      priceCents: 19900000,
      categoryId: 'electronica',
      offerPriceCents: 15900000,
    ),
    Product(
      id: 'p2',
      name: 'Smartwatch',
      description: 'Reloj inteligente con monitor de actividad.',
      priceCents: 29900000,
      categoryId: 'electronica',
    ),
    Product(
      id: 'p3',
      name: 'Altavoz portátil',
      description: 'Altavoz resistente al agua con 12 horas de batería.',
      priceCents: 12900000,
      categoryId: 'electronica',
      offerPriceCents: 9900000,
    ),
    Product(
      id: 'p4',
      name: 'Lámpara de escritorio',
      description: 'Lámpara LED con brillo regulable.',
      priceCents: 8900000,
      categoryId: 'hogar',
    ),
    Product(
      id: 'p5',
      name: 'Juego de sábanas',
      description: 'Sábanas de algodón para cama doble.',
      priceCents: 14900000,
      categoryId: 'hogar',
      offerPriceCents: 11900000,
    ),
    Product(
      id: 'p6',
      name: 'Cafetera de goteo',
      description: 'Cafetera programable de 12 tazas.',
      priceCents: 17900000,
      categoryId: 'hogar',
    ),
    Product(
      id: 'p7',
      name: 'Chaqueta impermeable',
      description: 'Chaqueta ligera para lluvia, unisex.',
      priceCents: 21900000,
      categoryId: 'moda',
      offerPriceCents: 17500000,
    ),
    Product(
      id: 'p8',
      name: 'Jeans clásicos',
      description: 'Jeans de corte recto en algodón.',
      priceCents: 13900000,
      categoryId: 'moda',
    ),
    Product(
      id: 'p9',
      name: 'Zapatillas urbanas',
      description: 'Zapatillas cómodas para uso diario.',
      priceCents: 24900000,
      categoryId: 'moda',
    ),
    Product(
      id: 'p10',
      name: 'Balón de fútbol',
      description: 'Balón oficial talla 5.',
      priceCents: 6900000,
      categoryId: 'deportes',
    ),
    Product(
      id: 'p11',
      name: 'Mat de yoga',
      description: 'Tapete antideslizante de 6 mm.',
      priceCents: 7900000,
      categoryId: 'deportes',
    ),
    Product(
      id: 'p12',
      name: 'Botella térmica',
      description: 'Botella de acero inoxidable de 750 ml.',
      priceCents: 5900000,
      categoryId: 'deportes',
    ),
  ];

  @override
  List<Category> categories() => _categories;

  @override
  List<Product> products() => _products;

  @override
  List<Product> offers() =>
      _products.where((p) => p.isOnOffer).toList(growable: false);

  @override
  List<Product> productsByCategory(String categoryId) => _products
      .where((p) => p.categoryId == categoryId)
      .toList(growable: false);

  @override
  Product? productById(String id) {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Category? categoryById(String id) {
    for (final category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
