import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';
import 'package:food_delivery/features/cart/domain/repository/cart_repo.dart';

part 'cart_states.dart';

/// Cubit for managing cart state and operations
class CartCubit extends Cubit<CartState> {
  final CartRepo cartRepo;
  List<CartItem> _currentItems = [];

  CartCubit(this.cartRepo) : super(CartInitial());

  /// Loads cart items for the given user
  Future<void> loadCart(String userId) async {
    emit(CartLoading());
    try {
      final items = await cartRepo.getCartItems(userId);
      _currentItems = items;
      emit(CartLoaded(items));
    } catch (e) {
      emit(CartError('Failed to load cart: ${e.toString()}'));
    }
  }

  /// Returns the current cart items
  List<CartItem> get currentItems => List.unmodifiable(_currentItems);

  /// Adds an item to the cart
  Future<void> addToCart(String userId, CartItem item) async {
    try {
      await cartRepo.addToCart(userId, item);
      await loadCart(userId); // Reload to get updated state
    } catch (e) {
      emit(CartError('Failed to add item: ${e.toString()}'));
    }
  }

  /// Removes an item from the cart with optimistic UI update
  Future<void> removeFromCart(String userId, String itemId) async {
    if (state is! CartLoaded) return;

    final currentState = state as CartLoaded;
    final updatedItems = currentState.items
        .where((item) => item.itemId != itemId)
        .toList();

    // Optimistic update
    _currentItems = updatedItems;
    emit(CartLoaded(updatedItems));

    // Sync with backend
    try {
      await cartRepo.removeFromCart(userId, itemId);
    } catch (e) {
      emit(CartError('Failed to remove item: ${e.toString()}'));
      await loadCart(userId); // Revert to actual state
    }
  }

  /// Updates item quantity with optimistic UI update
  Future<void> updateItemQuantity(
      String userId,
      String itemId,
      int newQuantity,
      ) async {
    if (state is! CartLoaded) return;

    final currentState = state as CartLoaded;
    final items = currentState.items;
    final index = items.indexWhere((item) => item.itemId == itemId);

    if (index == -1) return;

    // Create updated list
    final updatedItems = List<CartItem>.from(items);
    updatedItems[index] = updatedItems[index].copyWith(quantity: newQuantity);

    // Optimistic update
    _currentItems = updatedItems;
    emit(CartLoaded(updatedItems));

    // Sync with backend
    try {
      await cartRepo.updateQuantity(userId, itemId, newQuantity);
    } catch (e) {
      emit(CartError('Failed to update quantity: ${e.toString()}'));
      await loadCart(userId); // Revert to actual state
    }
  }

  /// Clears all items from the cart
  Future<void> clearCart(String userId) async {
    try {
      await cartRepo.clearCart(userId);
      _currentItems = [];
      emit(CartLoaded([]));
    } catch (e) {
      emit(CartError('Failed to clear cart: ${e.toString()}'));
    }
  }

  /// Confirms purchase and creates an order
  Future<void> confirmPurchase(
      String userId,
      String address,
      String paymentMethod, {
        String? paymentReference,
        String? deliveryOption = 'delivery',
        double deliveryFee = 0.0,
      }) async {
    if (state is! CartLoaded) return;

    try {
      final items = (state as CartLoaded).items;
      if (items.isEmpty) {
        throw Exception('Cart is empty');
      }

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
      emit(CartError('Failed to confirm purchase: ${e.toString()}'));
      rethrow; // Let the UI handle the error
    }
  }
}