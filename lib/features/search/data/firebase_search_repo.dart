import 'package:food_delivery/features/catalogue/domain/repository/catelog_repo.dart';
import 'package:food_delivery/features/promo/domain/repository/promo_repo.dart';
import 'package:food_delivery/features/search/domain/entities/search_item.dart';
import 'package:food_delivery/features/search/domain/repository/search_repo.dart';


class FirebaseSearchRepo implements SearchRepo {
  final CatalogRepo catalogRepo;
  final PromoRepo promoRepo;

  FirebaseSearchRepo(this.catalogRepo, this.promoRepo);

  @override
  Future<List<SearchItem>> searchItems(String query) async {
    final catalogItems = await catalogRepo.getAllCatalogItems();
    final promoItems = await promoRepo.getAllItems();

    final allItems = [
      ...catalogItems.map(SearchItem.fromCatalog),
      ...promoItems.map(SearchItem.fromPromo),
    ];

    final lowerQuery = query.toLowerCase();
    return allItems.where((item) =>
    item.name.toLowerCase().contains(lowerQuery) ||
        item.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}