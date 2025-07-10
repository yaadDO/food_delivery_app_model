import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';

class SearchItem {
  final String id;
  final String name;
  final String imagePath;
  final double price;
  final String description;
  final bool isPromo;

  SearchItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.description,
    required this.isPromo,
  });

  factory SearchItem.fromCatalog(CatalogItem item) => SearchItem(
    id: item.id,
    name: item.name,
    imagePath: item.imagePath, // Now matches CatalogItem property
    price: item.price,
    description: item.description,
    isPromo: false,
  );

  factory SearchItem.fromPromo(PromoItem item) => SearchItem(
    id: item.id,
    name: item.name,
    imagePath: item.imagePath,
    price: item.price,
    description: item.description,
    isPromo: true,
  );
}