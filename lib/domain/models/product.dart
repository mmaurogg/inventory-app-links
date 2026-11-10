/// Producto del catálogo. Los precios se expresan en centavos.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.categoryId,
    this.offerPriceCents,
  });

  final String id;
  final String name;
  final String description;
  final int priceCents;
  final String categoryId;
  final int? offerPriceCents;

  bool get isOnOffer => offerPriceCents != null;

  /// Precio de oferta cuando existe; precio regular en otro caso.
  int get effectivePriceCents => offerPriceCents ?? priceCents;
}
