import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/domain/repository/catelog_repo.dart';
import 'dart:typed_data';

part 'catalog_states.dart';


class CatalogCubit extends Cubit<CatalogState> {
  final CatalogRepo catalogRepo;

  CatalogCubit(this.catalogRepo) : super(CatalogInitial());

  Future<void> loadCategories() async {
    emit(CatalogLoading());
    try {
      final categories = await catalogRepo.getCategories();
      final allItems = await catalogRepo.getAllCatalogItems();

      // Make sure items are properly assigned to categories
      final updatedCategories = categories.map((category) {
        final categoryItems = allItems.where(
                (item) => item.categoryId == category.id
        ).toList();
        return category.copyWith(items: categoryItems);
      }).toList();

      emit(CatalogDataLoaded(updatedCategories, allItems));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> addCategory(Category category, Uint8List? imageBytes) async {
    try {
      emit(CatalogLoading());
      await catalogRepo.addCategory(category, imageBytes);
      await loadCategories();
    } catch (e) {
      print('Error adding category: $e');
      emit(CatalogError('Failed to add category: $e'));
    }
  }

  Future<void> updateCategory(Category category, Uint8List? imageBytes) async {
    try {
      await catalogRepo.updateCategory(category, imageBytes);
      final currentState = state;
      if (currentState is CatalogDataLoaded) {
        final updatedCategories = currentState.categories.map((c) =>
        c.id == category.id ? category : c).toList();
        emit(CatalogDataLoaded(updatedCategories, currentState.allItems));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await catalogRepo.deleteCategory(categoryId);
      final currentState = state;
      if (currentState is CatalogDataLoaded) {
        final updatedCategories = currentState.categories
            .where((c) => c.id != categoryId).toList();
        emit(CatalogDataLoaded(updatedCategories, currentState.allItems));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> loadItemsForCategory(String categoryId) async {
    try {
      if (state is! CatalogDataLoaded) return;

      final currentState = state as CatalogDataLoaded;
      final items = await catalogRepo.getItemsForCategory(categoryId);

      final updatedCategories = currentState.categories.map((category) {
        if (category.id == categoryId) {
          return category.copyWith(items: items);
        }
        return category;
      }).toList();

      final updatedAllItems = [
        ...currentState.allItems.where((i) => i.categoryId != categoryId),
        ...items
      ];

      emit(CatalogDataLoaded(updatedCategories, updatedAllItems));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> addItem(CatalogItem item, [Uint8List? imageBytes]) async {
    try {
      final newItem = await catalogRepo.addItem(item, imageBytes);
      final currentState = state;
      if (currentState is CatalogDataLoaded) {
        final updatedCategories = currentState.categories.map((category) {
          if (category.id == newItem.categoryId) {
            final updatedItems = List<CatalogItem>.from(category.items)
              ..add(newItem);
            return category.copyWith(items: updatedItems);
          }
          return category;
        }).toList();

        final updatedAllItems = List<CatalogItem>.from(currentState.allItems)
          ..add(newItem);

        emit(CatalogDataLoaded(updatedCategories, updatedAllItems));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> updateItem(CatalogItem item, [Uint8List? imageBytes]) async {
    try {
      await catalogRepo.updateItem(item, imageBytes);
      final currentState = state;
      if (currentState is CatalogDataLoaded) {
        final updatedCategories = currentState.categories.map((category) {
          if (category.id == item.categoryId) {
            final updatedItems = category.items.map((i) =>
            i.id == item.id ? item : i).toList();
            return category.copyWith(items: updatedItems);
          }
          return category;
        }).toList();

        final updatedAllItems = currentState.allItems.map((i) =>
        i.id == item.id ? item : i).toList();
        emit(CatalogDataLoaded(updatedCategories, updatedAllItems));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await catalogRepo.deleteItem(itemId);
      final currentState = state;
      if (currentState is CatalogDataLoaded) {
        final deletedItem = currentState.allItems.firstWhere(
              (item) => item.id == itemId,
          orElse: () => CatalogItem(
            id: '',
            name: '',
            imagePath: '',
            price: 0,
            quantity: 0,
            description: '',
            categoryId: '',
          ),
        );

        final updatedCategories = currentState.categories.map((category) {
          if (category.id == deletedItem.categoryId) {
            final updatedItems = category.items
                .where((i) => i.id != itemId).toList();
            return category.copyWith(items: updatedItems);
          }
          return category;
        }).toList();

        final updatedAllItems = currentState.allItems
            .where((i) => i.id != itemId).toList();

        emit(CatalogDataLoaded(updatedCategories, updatedAllItems));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> loadAllItems() async {
    final currentState = state;
    if (currentState is CatalogDataLoaded) {
      try {
        final items = await catalogRepo.getAllCatalogItems();
        emit(CatalogDataLoaded(currentState.categories, items));
      } catch (e) {
        emit(CatalogError(e.toString()));
      }
    }
  }
}