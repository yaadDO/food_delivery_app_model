import '../entities/cart_item.dart';

class CheckoutParams {
  final String userId;
  final List<CartItem> items;
  final String address;
  final String paymentMethod;
  final String deliveryOption;
  final double deliveryFee;
  final String? paymentReference;

  const CheckoutParams({
    required this.userId,
    required this.items,
    required this.address,
    required this.paymentMethod,
    this.deliveryOption = 'delivery',
    this.deliveryFee = 0.0,
    this.paymentReference,
  });
}