import '../entities/category.dart';
import '../entities/catalog_item.dart';

abstract class CatalogRepo {
  Future<List<Category>> getCategories();
  Future<void> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String categoryId);
  Future<CatalogItem> addItem(CatalogItem item);
  Future<void> updateItem(CatalogItem item);
  Future<void> deleteItem(String itemId);
  Future<List<CatalogItem>> getItemsForCategory(String categoryId);
  Future<List<CatalogItem>> getAllCatalogItems();
}