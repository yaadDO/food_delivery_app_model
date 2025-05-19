part of 'promo_cubit.dart';

abstract class PromoState {}

class PromoInitial extends PromoState {}

class PromoLoading extends PromoState {}

class PromoLoaded extends PromoState {
  final List<PromoItem> items;
  PromoLoaded(this.items);
}

class PromoError extends PromoState {
  final String message;
  PromoError(this.message);
}