import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery/features/cart/domain/entities/cart_item.dart';
import 'package:food_delivery/features/cart/domain/repository/cart_repo.dart';

class FirebaseCartRepo implements CartRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> addToCart(String userId, CartItem item) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(item.itemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        final newQuantity = (snapshot.data()!['quantity'] as int) + 1;
        transaction.update(docRef, {'quantity': newQuantity});
      } else {
        transaction.set(docRef, {
          'itemId': item.itemId,
          'name': item.name,
          'price': item.price,
          'imageUrl': item.imageUrl,
          'quantity': item.quantity,
        });
      }
    });
  }

  @override
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      return snapshot.docs.map((doc) {
        return CartItem(
          itemId: doc.id,
          name: doc['name'],
          price: doc['price'].toDouble(),
          imageUrl: doc['imageUrl'],
          quantity: doc['quantity'] as int,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching cart items: $e');
    }
  }

  @override
  Future<void> removeFromCart(String userId, String itemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(itemId)
          .delete();
    } catch (e) {
      throw Exception('Error removing item from cart: $e');
    }
  }

  @override
  Future<void> updateQuantity(
      String userId, String itemId, int newQuantity) async {
    final docRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        transaction.update(docRef, {'quantity': newQuantity});
      } else {
        throw Exception('Item not found in cart');
      }
    });
  }

  Future<void> clearCart(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      await Future.wait(
        snapshot.docs.map((doc) => doc.reference.delete()),
      );
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }

  @override
  Future<void> confirmPurchase(String userId, List<CartItem> items, String address, String paymentMethod) async {
    try {
      final orderDoc = _firestore.collection('orders').doc();
      await orderDoc.set({
        'userId': userId,
        'items': items.map((item) => {
          'itemId': item.itemId,
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'paymentMethod': paymentMethod,
        }).toList(),
        'total': items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)),
        'timestamp': FieldValue.serverTimestamp(),
        'address': address,
        'status': 'Pending',
        'paymentMethod': paymentMethod,
      });
    } catch (e) {
      throw Exception('Error confirming purchase: $e');
    }
  }
}