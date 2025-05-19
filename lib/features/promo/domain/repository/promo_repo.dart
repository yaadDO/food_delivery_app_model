import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';

abstract class PromoRepo {
  Future<PromoItem> addItem(PromoItem item);
  Future<void> updateItem(PromoItem item);
  Future<void> deleteItem(String itemId);
  Future<List<PromoItem>> getAllItems();
}