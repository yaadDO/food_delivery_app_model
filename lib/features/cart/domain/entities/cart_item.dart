class CartItem {
  final String itemId;
  final String name;
  final double price;
  final int quantity;
  final String imagePath;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imagePath,
  });

  // Add copyWith for immutable updates
  CartItem copyWith({
    String? itemId,
    String? name,
    double? price,
    int? quantity,
    String? imagePath,
  }) {
    return CartItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}