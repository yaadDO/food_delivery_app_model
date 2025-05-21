import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';
import 'package:food_delivery/features/cart/domain/repository/cart_repo.dart';

part 'cart_states.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepo cartRepo;
  CartCubit(this.cartRepo) : super(CartInitial());

  Future<void> loadCart(String userId) async {
    emit(CartLoading());
    try {
      final items = await cartRepo.getCartItems(userId);
      emit(CartLoaded(items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> addToCart(String userId, CartItem item) async {
    try {
      await cartRepo.addToCart(userId, item);
      await loadCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> removeFromCart(String userId, String itemId) async {
    try {
      await cartRepo.removeFromCart(userId, itemId);
      await loadCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> updateItemQuantity(
      String userId, String itemId, int newQuantity) async {
    try {
      await cartRepo.updateQuantity(userId, itemId, newQuantity);
      await loadCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> clearCart(String userId) async {
    try {
      await cartRepo.clearCart(userId);
      emit(CartLoaded([]));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  @override
  Future<void> confirmPurchase(String userId, String address, String paymentMethod) async {
    try {
      final items = await cartRepo.getCartItems(userId);
      if (paymentMethod.isEmpty) {
        throw Exception('Please select a payment method');
      }
      await cartRepo.confirmPurchase(userId, items, address, paymentMethod);
      await clearCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }
}