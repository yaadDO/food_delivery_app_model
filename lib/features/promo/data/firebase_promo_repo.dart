import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/domain/repository/promo_repo.dart';

class FirebasePromoRepo implements PromoRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<PromoItem> addItem(PromoItem item) async {
    try {
      final docRef = _firestore.collection('promo').doc();
      await docRef.set({
        'name': item.name,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
      });
      print('Item added with ID: ${docRef.id}'); // Debug logging
      return item.copyWith(id: docRef.id);
    } catch (e) {
      print('Firestore error: $e'); // Debug logging
      throw Exception('Error adding item: ${e.toString()}');
    }
  }

  @override
  Future<void> updateItem(PromoItem item) async {
    try {
      await _firestore.collection('promo').doc(item.id).update({
        'name': item.name,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
      });
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('promo').doc(itemId).delete();
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }

  @override
  Future<List<PromoItem>> getAllItems() async {
    try {
      final snapshot = await _firestore.collection('promo').get();
      return snapshot.docs.map((doc) {
        return PromoItem(
          id: doc.id,
          name: doc['name'],
          imageUrl: doc['imageUrl'],
          price: doc['price'].toDouble(),
          quantity: doc['quantity'] as int,
          description: doc['description'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all items: $e');
    }
  }
}