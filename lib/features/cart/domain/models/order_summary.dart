import '../entities/cart_item.dart';

class OrderSummary {
  final double subtotal;
  final double deliveryFee;
  final double total;
  final int itemCount;

  const OrderSummary({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.itemCount,
  });

  factory OrderSummary.fromItems(
      List<CartItem> items,
      double deliveryFee
      ) {
    final subtotal = items.fold(
        0.0,
            (sum, item) => sum + (item.price * item.quantity)
    );
    final total = subtotal + deliveryFee;

    return OrderSummary(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      itemCount: items.length,
    );
  }
}