import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/catalogue/domain/entities/catalog_item.dart';
import 'package:food_delivery/features/catalogue/domain/entities/category.dart';
import 'package:food_delivery/features/catalogue/domain/repository/catelog_repo.dart';

part 'catalog_states.dart';

class CatalogCubit extends Cubit<CatalogState> {
  final CatalogRepo catalogRepo;

  CatalogCubit(this.catalogRepo) : super(CatalogInitial());

  Future<void> loadCategories() async {
    emit(CatalogLoading());
    try {
      final categories = await catalogRepo.getCategories();
      emit(CatalogLoaded(categories));
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> addCategory(Category category) async {
    try {
      await catalogRepo.addCategory(category);
      await loadCategories();
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      await catalogRepo.updateCategory(category);
      final currentState = state;
      if (currentState is CatalogLoaded) {
        final updatedCategories = currentState.categories.map((c) =>
        c.id == category.id ? category : c).toList();
        emit(CatalogLoaded(updatedCategories));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await catalogRepo.deleteCategory(categoryId);
      final currentState = state;
      if (currentState is CatalogLoaded) {
        final updatedCategories = currentState.categories
            .where((c) => c.id != categoryId).toList();
        emit(CatalogLoaded(updatedCategories));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> loadItemsForCategory(String categoryId) async {
    final previousState = state; // Capture the state before emitting loading
    emit(CatalogLoading());
    try {
      final items = await catalogRepo.getItemsForCategory(categoryId);
      if (previousState is CatalogLoaded) {
        final updatedCategories = previousState.categories.map((category) {
          return category.id == categoryId
              ? category.copyWith(items: items)
              : category;
        }).toList();
        emit(CatalogLoaded(updatedCategories));
      } else {
        // Handle unexpected state or reload categories
        await loadCategories();
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> addItem(CatalogItem item) async {
    try {
      final newItem = await catalogRepo.addItem(item);
      final currentState = state;
      if (currentState is CatalogLoaded) {
        final updatedCategories = currentState.categories.map((category) {
          if (category.id == newItem.categoryId) {
            return category.copyWith(
                items: [...category.items, newItem]
            );
          }
          return category;
        }).toList();
        emit(CatalogLoaded(updatedCategories));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> updateItem(CatalogItem item) async {
    try {
      await catalogRepo.updateItem(item);
      final currentState = state;
      if (currentState is CatalogLoaded) {
        final updatedCategories = currentState.categories.map((category) {
          if (category.id == item.categoryId) {
            final updatedItems = category.items.map((i) =>
            i.id == item.id ? item : i).toList();
            return category.copyWith(items: updatedItems);
          }
          return category;
        }).toList();
        emit(CatalogLoaded(updatedCategories));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }

  Future<void> deleteItem(String itemId, String categoryId) async {
    try {
      await catalogRepo.deleteItem(itemId);
      final currentState = state;
      if (currentState is CatalogLoaded) {
        final updatedCategories = currentState.categories.map((category) {
          if (category.id == categoryId) {
            final updatedItems = category.items
                .where((i) => i.id != itemId).toList();
            return category.copyWith(items: updatedItems);
          }
          return category;
        }).toList();
        emit(CatalogLoaded(updatedCategories));
      }
    } catch (e) {
      emit(CatalogError(e.toString()));
    }
  }


}