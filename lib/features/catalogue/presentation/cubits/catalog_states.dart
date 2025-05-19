part of 'catalog_cubit.dart';

abstract class CatalogState {}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<Category> categories;

  CatalogLoaded(this.categories);
}

class CatalogError extends CatalogState {
  final String message;

  CatalogError(this.message);
}

