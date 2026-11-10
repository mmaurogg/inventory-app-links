import 'package:glados/glados.dart';
import 'package:inventory_app_links/data/in_memory_catalog_repository.dart';
import 'package:inventory_app_links/domain/models/category.dart';
import 'package:inventory_app_links/domain/models/product.dart';

/// Configuración común: mínimo 100 iteraciones por propiedad.
final _config = ExploreConfig(numRuns: 100);

const _repository = InMemoryCatalogRepository();

final _products = _repository.products();
final _categories = _repository.categories();

/// Un id que no pertenece al catálogo (ni a productos ni a categorías).
final _knownIds = <String>{
  ..._products.map((p) => p.id),
  ..._categories.map((c) => c.id),
};

extension CatalogGenerators on Any {
  /// Índice arbitrario dentro de un rango amplio; se reduce con módulo.
  Generator<int> get anyIndex => intInRange(0, 10000);

  /// Cadenas arbitrarias que no coinciden con ningún id del catálogo.
  Generator<String> get unknownId =>
      letterOrDigits.map(
        // Si la cadena coincide con un id conocido, se altera para excluirlo.
        (s) => _knownIds.contains(s) ? '${s}_' : s,
      );
}

bool _sameProduct(Product a, Product b) =>
    a.id == b.id &&
    a.name == b.name &&
    a.description == b.description &&
    a.priceCents == b.priceCents &&
    a.categoryId == b.categoryId &&
    a.offerPriceCents == b.offerPriceCents;

bool _sameCategory(Category a, Category b) => a.id == b.id && a.name == b.name;

void main() {
  group('InMemoryCatalogRepository (catálogo semilla)', () {
    // Validates: Requirements 2.1, 2.2
    test('tiene al menos 4 categorías', () {
      expect(_categories.length, greaterThanOrEqualTo(4));
    });

    test('tiene al menos 12 productos', () {
      expect(_products.length, greaterThanOrEqualTo(12));
    });

    test('tiene al menos 4 ofertas con precio menor al regular', () {
      final offers = _products.where(
        (p) =>
            p.offerPriceCents != null && p.offerPriceCents! < p.priceCents,
      );
      expect(offers.length, greaterThanOrEqualTo(4));
    });

    test('todo precio de oferta es menor al precio regular', () {
      for (final p in _products.where((p) => p.isOnOffer)) {
        expect(p.offerPriceCents!, lessThan(p.priceCents), reason: p.id);
      }
    });

    test('los ids de productos son únicos', () {
      final ids = _products.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('los ids de categorías son únicos', () {
      final ids = _categories.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('ningún id contiene "/"', () {
      for (final id in _knownIds) {
        expect(id.contains('/'), isFalse, reason: id);
      }
    });

    test('cada producto referencia un categoryId existente', () {
      final categoryIds = _categories.map((c) => c.id).toSet();
      for (final p in _products) {
        expect(categoryIds.contains(p.categoryId), isTrue, reason: p.id);
      }
    });
  });

  group('InMemoryCatalogRepository (propiedades)', () {
    // Feature: ecommerce-dynamic-links, Property 6: Búsqueda por id existente
    // Validates: Requirements 2.3
    Glados(any.anyIndex, _config).test(
      'Propiedad 6: productById devuelve el producto original',
      (index) {
        final original = _products[index % _products.length];
        final found = _repository.productById(original.id);
        expect(found, isNotNull);
        expect(_sameProduct(found!, original), isTrue);
      },
    );

    // Feature: ecommerce-dynamic-links, Property 6: Búsqueda por id existente
    // Validates: Requirements 2.3
    Glados(any.anyIndex, _config).test(
      'Propiedad 6: categoryById devuelve la categoría original',
      (index) {
        final original = _categories[index % _categories.length];
        final found = _repository.categoryById(original.id);
        expect(found, isNotNull);
        expect(_sameCategory(found!, original), isTrue);
      },
    );

    // Feature: ecommerce-dynamic-links, Property 7: Búsqueda por id inexistente
    // Validates: Requirements 2.4, 3.7
    Glados(any.unknownId, _config).test(
      'Propiedad 7: productById devuelve null para ids inexistentes',
      (id) {
        expect(_repository.productById(id), isNull);
      },
    );

    // Feature: ecommerce-dynamic-links, Property 7: Búsqueda por id inexistente
    // Validates: Requirements 2.4, 3.7
    Glados(any.unknownId, _config).test(
      'Propiedad 7: categoryById devuelve null para ids inexistentes',
      (id) {
        expect(_repository.categoryById(id), isNull);
      },
    );
  });
}
