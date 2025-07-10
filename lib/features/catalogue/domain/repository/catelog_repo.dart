import '../entities/category.dart';
import '../entities/catalog_item.dart';

import 'dart:typed_data';

abstract class CatalogRepo {
  Future<List<Category>> getCategories(); // Changed from CatalogItem to Category
  Future<void> addCategory(Category category, [Uint8List? imageBytes]); // Added imageBytes
  Future<void> updateCategory(Category category, [Uint8List? imageBytes]); // Added imageBytes
  Future<void> deleteCategory(String categoryId);
  Future<CatalogItem> addItem(CatalogItem item, [Uint8List? imageBytes]);
  Future<void> updateItem(CatalogItem item, [Uint8List? imageBytes]);
  Future<void> deleteItem(String itemId);
  Future<List<CatalogItem>> getItemsForCategory(String categoryId);
  Future<List<CatalogItem>> getAllCatalogItems();
}