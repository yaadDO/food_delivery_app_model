import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/domain/repository/promo_repo.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebasePromoRepo implements PromoRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<PromoItem> addItem(PromoItem item, [Uint8List? imageBytes]) async {
    try {
      String? imageUrl = item.imageUrl;

      if (imageBytes != null) {
        final storageRef = _storage
            .ref()
            .child('promo_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putData(imageBytes);
        imageUrl = await storageRef.getDownloadURL();
      }

      final docRef = _firestore.collection('promo').doc();
      final itemWithImage = item.copyWith(imageUrl: imageUrl);
      await docRef.set(itemWithImage.toJson());

      return itemWithImage.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Error adding item: ${e.toString()}');
    }
  }

  @override
  Future<PromoItem> updateItem(PromoItem item, [Uint8List? imageBytes]) async {
    try {
      String? imageUrl = item.imageUrl;

      if (imageBytes != null) {
        final storageRef = _storage
            .ref()
            .child('promo_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putData(imageBytes);
        imageUrl = await storageRef.getDownloadURL();
      }

      final updatedItem = item.copyWith(imageUrl: imageUrl);
      await _firestore.collection('promo').doc(item.id).update(updatedItem.toJson());

      return updatedItem;
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
        final data = doc.data() as Map<String, dynamic>;
        return PromoItem(
          id: doc.id,
          name: data['name'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          price: (data['price'] as num).toDouble(),
          quantity: data['quantity'] as int,
          description: data['description'] ?? '',
          discountPercentage: data['discountPercentage'] != null
              ? (data['discountPercentage'] as num).toDouble()
              : null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all items: $e');
    }
  }
}