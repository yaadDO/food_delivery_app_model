import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/domain/repository/catelog_repo.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:typed_data';

class FirebaseCatalogRepo implements CatalogRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  @override
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>? ?? {};

        // Handle empty image paths
        final imagePath = data['imagePath'] as String? ?? '';

        // Get items for this category
        final items = await getItemsForCategory(doc.id);

        return Category(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Category',
          imagePath: imagePath,
          items: items,
        );
      }));
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  @override
  Future<void> addCategory(Category category, [Uint8List? imageBytes]) async {
    try {
      String? imagePath;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        imagePath = 'categories/${_uuid.v4()}.jpg';
        await _storage.ref(imagePath).putData(imageBytes);
      }

      final docRef = _firestore.collection('categories').doc();
      await docRef.set({
        'name': category.name,
        'imagePath': imagePath ?? '',
      });

      // Update the category with new ID
      category = category.copyWith(id: docRef.id);
    } catch (e) {
      print('Error adding category: $e');
      throw Exception('Error adding category: $e');
    }
  }


  @override
  Future<void> updateCategory(Category category, [Uint8List? imageBytes]) async {
    try {
      String? imagePath = category.imagePath;

      // Upload new image if provided
      if (imageBytes != null) {
        // Delete old image if exists
        if (imagePath != null && imagePath.isNotEmpty) {
          await _storage.ref(imagePath).delete();
        }

        // Upload new image
        imagePath = 'categories/${_uuid.v4()}.jpg';
        await _storage.ref(imagePath).putData(imageBytes);
      }

      await _firestore.collection('categories').doc(category.id).update({
        'name': category.name,
        'imagePath': imagePath,
      });
    } catch (e) {
      throw Exception('Error updating category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      // Get category data first to delete image
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      final imagePath = doc['imagePath'] as String?;

      // Delete image from storage
      if (imagePath != null && imagePath.isNotEmpty) {
        await _storage.ref(imagePath).delete();
      }

      // Delete category document
      await _firestore.collection('categories').doc(categoryId).delete();

      // Delete all items in the category
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      await Future.wait(
        itemsSnapshot.docs.map((doc) => doc.reference.delete()),
      );
    } catch (e) {
      throw Exception('Error deleting category: $e');
    }
  }

  @override
  Future<List<CatalogItem>> getItemsForCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('categoryId', isEqualTo: categoryId)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CatalogItem(
          id: doc.id,
          name: data['name'] as String? ?? '',
          imagePath: data['imagePath'] as String? ?? '', // Add null check
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: data['quantity'] as int? ?? 0,
          description: data['description'] as String? ?? '',
          categoryId: data['categoryId'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching items: $e');
    }
  }

  @override
  Future<CatalogItem> addItem(CatalogItem item, [Uint8List? imageBytes]) async {
    try {
      String? imagePath;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        imagePath = 'items/${Uuid().v4()}.jpg';
        await _storage.ref(imagePath).putData(imageBytes);
      }

      final docRef = _firestore.collection('items').doc();
      await docRef.set({
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
        'categoryId': item.categoryId,
        'imagePath': imagePath ?? '',
      });

      return item.copyWith(
        id: docRef.id,
        imagePath: imagePath ?? item.imagePath,
      );
    } catch (e) {
      throw Exception('Error adding item: $e');
    }
  }

  @override
  Future<void> updateItem(CatalogItem item, [Uint8List? imageBytes]) async {
    try {
      String? imagePath = item.imagePath;

      // Upload new image if provided
      if (imageBytes != null) {
        // Delete old image if exists
        if (imagePath != null && imagePath.isNotEmpty) {
          await _storage.ref(imagePath).delete();
        }

        // Upload new image
        imagePath = 'items/${const Uuid().v4()}.jpg';
        await _storage.ref(imagePath).putData(imageBytes);
      }

      // Update document with new image path
      await _firestore.collection('items').doc(item.id).update({
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
        'categoryId': item.categoryId,
        'imagePath': imagePath, // Update image path
      });
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async { // Remove categoryId parameter
    try {
      // Get item first to delete image
      final doc = await _firestore.collection('items').doc(itemId).get();
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
  Future<List<CatalogItem>> getAllCatalogItems() async {
    try {
      final snapshot = await _firestore.collection('items').get();
      return snapshot.docs.map((doc) => CatalogItem(
        id: doc.id,
        name: doc['name'],
        imagePath: doc['imagePath'] ?? '', // Add this field
        price: doc['price'].toDouble(),
        quantity: doc['quantity'] as int,
        description: doc['description'],
        categoryId: doc['categoryId'],
      )).toList();
    } catch (e) {
      throw Exception('Error fetching all items: $e');
    }
  }
}