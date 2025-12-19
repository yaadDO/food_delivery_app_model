import '../../domain/entities/app_user.dart';

abstract class AuthState{}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  final bool isAdmin;
  Authenticated(this.isAdmin, this.user);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
