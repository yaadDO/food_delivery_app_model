class PromoItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String description;
  final double? discountPercentage;
  final String imagePath;

  PromoItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imagePath,
    this.discountPercentage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'description': description,
      'discountPercentage': discountPercentage,
      'imagePath': imagePath,
    };
  }

  // Add fromJson factory constructor for easier deserialization
  factory PromoItem.fromJson(Map<String, dynamic> json) {
    return PromoItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      imagePath: json['imagePath'] ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
    );
  }

  PromoItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    double? price,
    int? quantity,
    String? description,
    double? discountPercentage,
  }) {
    return PromoItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }
}