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

  Future<void> processPayment(
      String userId,
      String address,
      String paymentMethod, {
        String? paymentReference,
      }) async {
    try {
      final items = await cartRepo.getCartItems(userId);

      // Validate payment method
      if (paymentMethod.isEmpty) {
        throw Exception('Please select a payment method');
      }

      // Additional validation can be added here if needed
      if (paymentMethod == 'Paystack' && (paymentReference == null || paymentReference.isEmpty)) {
        throw Exception('Payment reference is required for Paystack payments');
      }

      await cartRepo.confirmPurchase(
        userId,
        items,
        address,
        paymentMethod,
        paymentReference: paymentReference,
      );

      await clearCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
      rethrow;
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

  Future<void> confirmPurchase(
      String userId,
      String address,
      String paymentMethod, {
        String? paymentReference,
      }) async {
    try {
      final items = await cartRepo.getCartItems(userId);
      if (paymentMethod.isEmpty) {
        throw Exception('Please select a payment method');
      }

      await cartRepo.confirmPurchase(
        userId,
        items,
        address,
        paymentMethod,
        paymentReference: paymentReference,
      );

      await clearCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }
}