// lib/domain/entities/category.dart
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final List<CatalogItem> items;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.items = const [],
  });


  Category copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<CatalogItem>? items,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      items: items ?? this.items,
    );
  }
}

