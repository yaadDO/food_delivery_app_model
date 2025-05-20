import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';

abstract class CartRepo {
  Future<void> addToCart(String userId, CartItem item);
  Future<List<CartItem>> getCartItems(String userId);
  Future<void> removeFromCart(String userId, String itemId);
  Future<void> updateQuantity(String userId, String itemId, int newQuantity);
  Future<void> clearCart(String userId);
  Future<void> confirmPurchase(String userId, List<CartItem> items, String address);
}