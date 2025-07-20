class CatalogItem {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final int quantity;
  final String description;
  final String categoryId;

  CatalogItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
    required this.description,
    required this.categoryId,
  });

  CatalogItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    double? price,
    int? quantity,
    String? description,
    String? categoryId,
  }) {
    return CatalogItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}