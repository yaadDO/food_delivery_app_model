class CatalogItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String description;
  final String categoryId;

  CatalogItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.description,
    required this.categoryId,
  });
  CatalogItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? description,
    String? categoryId,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}