import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';
import 'package:food_delivery/features/cart/domain/repository/cart_repo.dart';

part 'cart_states.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepo cartRepo;
  List<CartItem> _currentItems = [];

  CartCubit(this.cartRepo) : super(CartInitial());

  Future<void> loadCart(String userId) async {
    emit(CartLoading());
    try {
      final items = await cartRepo.getCartItems(userId);
      _currentItems = items; // Cache items
      emit(CartLoaded(items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  List<CartItem> get currentItems => _currentItems;

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
    if (state is! CartLoaded) return;

    final currentState = state as CartLoaded;
    final updatedItems = currentState.items
        .where((item) => item.itemId != itemId)
        .toList();

    // Update UI immediately
    _currentItems = updatedItems;
    emit(CartLoaded(updatedItems));

    // Sync with Firestore in background
    try {
      await cartRepo.removeFromCart(userId, itemId);
    } catch (e) {
      emit(CartError(e.toString()));
      await loadCart(userId);
    }
  }


  Future<void> updateItemQuantity(
      String userId,
      String itemId,
      int newQuantity
      ) async {
    if (state is! CartLoaded) return;

    final currentState = state as CartLoaded;
    final items = currentState.items;
    final index = items.indexWhere((item) => item.itemId == itemId);

    if (index == -1) return;

    // Create updated list with the new quantity
    final updatedItems = List<CartItem>.from(items);
    updatedItems[index] = updatedItems[index].copyWith(quantity: newQuantity);

    // Update UI immediately (optimistic update)
    _currentItems = updatedItems;
    emit(CartLoaded(updatedItems));

    // Then sync with Firestore in background
    try {
      await cartRepo.updateQuantity(userId, itemId, newQuantity);
    } catch (e) {
      // Revert on error
      emit(CartError('Failed to update quantity: $e'));
      // Optionally reload cart to get correct state
      await loadCart(userId);
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
        String? deliveryOption = 'delivery',
        double deliveryFee = 0.0,
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
        deliveryOption: deliveryOption,
        deliveryFee: deliveryFee,
      );

      await clearCart(userId);
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }
}