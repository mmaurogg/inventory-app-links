import 'models/category.dart';
import 'models/product.dart';

/// Contrato de acceso al catálogo.
abstract interface class CatalogRepository {
  List<Category> categories();
  List<Product> products();
  List<Product> offers();
  List<Product> productsByCategory(String categoryId);

  /// Devuelve `null` si el id no existe.
  Product? productById(String id);

  /// Devuelve `null` si el id no existe.
  Category? categoryById(String id);
}
