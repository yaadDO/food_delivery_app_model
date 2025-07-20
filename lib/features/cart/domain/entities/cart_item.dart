
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
}