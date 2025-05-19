class CartItem {
  final String itemId;
  final String name;
  final double price;
  final String imageUrl;
  int quantity;

  CartItem({
    required this.itemId,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
  });
}
