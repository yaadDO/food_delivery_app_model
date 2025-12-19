import 'package:bloc/bloc.dart';
import 'package:food_delivery/features/auth/domain/entities/app_user.dart';
import 'package:food_delivery/features/auth/domain/repository/auth_repo.dart';
import 'package:food_delivery/features/auth/presentation/cubits/auth_states.dart';

import '../../data/firebase_auth_repo.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  AppUser? _currentUser;

  AuthCubit({required this.authRepo}) : super(AuthInitial());

  void checkAuth() async {
    final AppUser? user = await authRepo.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      await (authRepo as FirebaseAuthRepo).storeFCMToken(user.uid);
      emit(Authenticated(user.isAdmin, user));
    } else {
      emit(Unauthenticated());
    }
  }

  AppUser? get currentUser => _currentUser;

  Future<void> login(String email, String pw) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.loginWithEmailPassword(email, pw);

      if (user != null) {
        _currentUser = user;

        await (authRepo as FirebaseAuthRepo).storeFCMToken(user.uid);
        emit(Authenticated(user.isAdmin, user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register(String name, String email, String pw) async {
    try {
      emit(AuthLoading());
      final user = await authRepo.registerWithEmailPassword(name, email, pw);

      if (user != null) {
        _currentUser = user;
        await (authRepo as FirebaseAuthRepo).storeFCMToken(user.uid);
        emit(Authenticated(false, user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      emit(AuthLoading());
      final user = await authRepo.signInWithGoogle();

      if (user != null) {
        _currentUser = user;
        await (authRepo as FirebaseAuthRepo).storeFCMToken(user.uid);
        emit(Authenticated(user.isAdmin, user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      await authRepo.logout();
      _currentUser = null;
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}