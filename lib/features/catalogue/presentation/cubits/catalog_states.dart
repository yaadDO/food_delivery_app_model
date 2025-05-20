part of 'catalog_cubit.dart';

abstract class CatalogState {}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogDataLoaded extends CatalogState {
  final List<Category> categories;
  final List<CatalogItem> allItems;

  CatalogDataLoaded(this.categories, this.allItems);
}

class CatalogError extends CatalogState {
  final String message;
  CatalogError(this.message);
}
