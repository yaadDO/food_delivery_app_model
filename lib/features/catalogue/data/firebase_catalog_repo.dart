import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/domain/repository/catelog_repo.dart';


class FirebaseCatalogRepo implements CatalogRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firestore.collection('categories').get();
      return snapshot.docs.map((doc) {
        return Category(
          id: doc.id,
          name: doc['name'],
          imageUrl: doc['imageUrl'],
          items: [],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  @override
  Future<void> addCategory(Category category) async {
    try {
      await _firestore.collection('categories').add({
        'name': category.name,
        'imageUrl': category.imageUrl,
      });
    } catch (e) {
      throw Exception('Error adding category: $e');
    }
  }

  @override
  Future<void> updateCategory(Category category) async {
    try {
      await _firestore.collection('categories').doc(category.id).update({
        'name': category.name,
        'imageUrl': category.imageUrl,
      });
    } catch (e) {
      throw Exception('Error updating category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      // Delete category
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
        return CatalogItem(
          id: doc.id,
          name: doc['name'],
          imageUrl: doc['imageUrl'],
          price: doc['price'].toDouble(),
          quantity: doc['quantity'] as int,
          description: doc['description'],
          categoryId: doc['categoryId'],
        );
      }).toList();
    } catch (e) {
      throw Exception('Error fetching items: $e');
    }
  }

  @override
  Future<CatalogItem> addItem(CatalogItem item) async {  // Changed return type
    try {
      final docRef = _firestore.collection('items').doc();
      await docRef.set({
        'name': item.name,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
        'categoryId': item.categoryId,
      });
      return item.copyWith(id: docRef.id);  // Return new item with generated ID
    } catch (e) {
      throw Exception('Error adding item: $e');
    }
  }

  @override
  Future<void> updateItem(CatalogItem item) async {
    try {
      await _firestore.collection('items').doc(item.id).update({
        'name': item.name,
        'imageUrl': item.imageUrl,
        'price': item.price,
        'quantity': item.quantity,
        'description': item.description,
        'categoryId': item.categoryId,
      });
    } catch (e) {
      throw Exception('Error updating item: $e');
    }
  }

  @override
  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
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
        imageUrl: doc['imageUrl'],
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