import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';

class Category {
  final String id;
  final String name;
  final String imagePath;
  final List<CatalogItem> items;

  Category({
    required this.id,
    required this.name,
    this.imagePath = '',  // Ensure default empty string
    List<CatalogItem>? items,
  }) : items = items ?? [];

  Category copyWith({
    String? id,
    String? name,
    String? imagePath,
    List<CatalogItem>? items,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      items: items ?? this.items,
    );
  }
}