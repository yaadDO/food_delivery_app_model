import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/domain/repository/promo_repo.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

class FirebasePromoRepo implements PromoRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  @override
  Future<PromoItem> addItem(PromoItem item, [Uint8List? imageBytes]) async {
    if (imageBytes == null) {
      throw Exception('Image is required');
    }
    try {
      final imagePath = 'promo_images/${_uuid.v4()}.jpg';
      final storageRef = _storage.ref().child(imagePath);
      await storageRef.putData(imageBytes);

      final docRef = _firestore.collection('promo').doc();
      final newItem = item.copyWith(
        id: docRef.id,
        imagePath: imagePath,
      );

      await docRef.set(newItem.toJson());
      return newItem;
    } catch (e) {
      throw Exception('Error adding item: ${e.toString()}');
    }
  }

  @override
  Future<PromoItem> updateItem(PromoItem item, [Uint8List? imageBytes]) async {
    try {
      String imagePath = item.imagePath;

      if (imageBytes != null) {
        if (imagePath.isNotEmpty) {
          await _storage.ref(imagePath).delete();
        }
        imagePath = 'promo_images/${_uuid.v4()}.jpg';
        await _storage.ref(imagePath).putData(imageBytes);
      }
      final updatedItem = item.copyWith(imagePath: imagePath);
      await _firestore.collection('promo').doc(item.id).update(updatedItem.toJson());

      return updatedItem;
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      final doc = await _firestore.collection('promo').doc(itemId).get();
      if (doc.exists) {
        final imagePath = doc['imagePath'] as String?;
        if (imagePath != null && imagePath.isNotEmpty) {
          await _storage.ref(imagePath).delete();
        }
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Error deleting item: $e');
    }
  }

  @override
  Future<List<PromoItem>> getAllItems() async {
    try {
      final snapshot = await _firestore.collection('promo').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PromoItem(
          id: doc.id,
          name: data['name'] ?? '',
          imagePath: data['imagePath'] ?? '',
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