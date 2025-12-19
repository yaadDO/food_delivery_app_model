import 'dart:typed_data';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';

abstract class PromoRepo {
  Future<PromoItem> addItem(PromoItem item, [Uint8List? imageBytes]);
  Future<PromoItem> updateItem(PromoItem item, [Uint8List? imageBytes]);
  Future<void> deleteItem(String itemId);
  Future<List<PromoItem>> getAllItems();
}