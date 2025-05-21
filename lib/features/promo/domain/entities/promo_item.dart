class PromoItem {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String description;
  final double? discountPercentage; // New field

  PromoItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.description,
    this.discountPercentage, // Added as optional parameter
  });

  PromoItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
    String? description,
    double? discountPercentage, // Added to copyWith
  }) {
    return PromoItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}