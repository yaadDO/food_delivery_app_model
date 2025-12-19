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
      final categoriesSnapshot = await _firestore.collection('categories').get();
      final allItems = await getAllCatalogItems();

      return categoriesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final imagePath = data['imagePath'] as String? ?? '';

        final categoryItems = allItems.where(
                (item) => item.categoryId == doc.id
        ).toList();

        return Category(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Category',
          imagePath: imagePath,
          items: categoryItems,
        );
      }).toList();
    } catch (e) {
      print('Error in getCategories: $e');
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
      if (imageBytes != null) {
        if (imagePath != null && imagePath.isNotEmpty) {
          await _storage.ref(imagePath).delete();
        }
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
      final doc = await _firestore.collection('categories').doc(categoryId).get();
      final imagePath = doc['imagePath'] as String?;
      if (imagePath != null && imagePath.isNotEmpty) {
        await _storage.ref(imagePath).delete();
      }

      await _firestore.collection('categories').doc(categoryId).delete();

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
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return CatalogItem(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Item',
          imagePath: data['imagePath'] as String? ?? '',
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
      if (imageBytes != null) {
        if (imagePath != null && imagePath.isNotEmpty) {
          await _storage.ref(imagePath).delete();
        }
        imagePath = 'items/${const Uuid().v4()}.jpg';
        await _storage.ref(imagePath).putData(imageBytes);
      }
      await _firestore.collection('items').doc(item.id).update({
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
        'categoryId': item.categoryId,
        'imagePath': imagePath,
      });
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
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
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return CatalogItem(
          id: doc.id,
          name: data['name'] as String? ?? 'Unnamed Item',
          imagePath: data['imagePath'] as String? ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          quantity: data['quantity'] as int? ?? 0,
          description: data['description'] as String? ?? '',
          categoryId: data['categoryId'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching all items: $e');
    }
  }
}