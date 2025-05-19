import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/promo/domain/entities/promo_item.dart';
import 'package:food_delivery/features/promo/domain/repository/promo_repo.dart';

part 'promo_state.dart';

class PromoCubit extends Cubit<PromoState> {
  final PromoRepo promoRepo;

  PromoCubit(this.promoRepo) : super(PromoInitial());

  Future<void> loadItems() async {
    emit(PromoLoading());
    try {
      final items = await promoRepo.getAllItems();
      emit(PromoLoaded(items));
    } catch (e) {
      emit(PromoError(e.toString()));
    }
  }

  Future<void> addItem(PromoItem item) async {
    try {
      final newItem = await promoRepo.addItem(item);
      final currentState = state;
      if (currentState is PromoLoaded) {
        emit(PromoLoaded([...currentState.items, newItem]));
      }
    } catch (e) {
      emit(PromoError(e.toString()));
    }
  }

  Future<void> updateItem(PromoItem item) async {
    try {
      await promoRepo.updateItem(item);
      final currentState = state;
      if (currentState is PromoLoaded) {
        final updatedItems = currentState.items.map((i) =>
        i.id == item.id ? item : i).toList();
        emit(PromoLoaded(updatedItems));
      }
    } catch (e) {
      emit(PromoError(e.toString()));
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      await promoRepo.deleteItem(itemId);
      final currentState = state;
      if (currentState is PromoLoaded) {
        final updatedItems = currentState.items
            .where((i) => i.id != itemId).toList();
        emit(PromoLoaded(updatedItems));
      }
    } catch (e) {
      emit(PromoError(e.toString()));
    }
  }
}