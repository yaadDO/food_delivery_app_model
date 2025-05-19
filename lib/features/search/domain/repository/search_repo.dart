import '../entities/search_item.dart';

abstract class SearchRepo {
  Future<List<SearchItem>> searchItems(String query);
}