import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/repository/profile_repo.dart';
import 'profile_states.dart';

class ProfileCubit extends Cubit<ProfileState> {
final ProfileRepo profileRepo;


  ProfileCubit({
    required this.profileRepo,
  }) : super(ProfileInitial());

  Future<void> fetchUserProfile(String uid) async {
    try {
      emit(ProfileLoading());
      final user = await profileRepo.fetchUserProfile(uid);
      user != null
          ? emit(ProfileLoaded(user))
          : emit(ProfileError('User not found'));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<ProfileUser?> getUserProfile(String uid) async {
    final user = await profileRepo.fetchUserProfile(uid);
    return user;
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String bio,
    required String phoneNumber,
    required String address,
  }) async {
    emit(ProfileLoading());
    try {
      final currentUser = await profileRepo.fetchUserProfile(uid);
      if (currentUser == null) {
        emit(ProfileError('User not found'));
        return;
      }

      final updatedProfile = currentUser.copyWith(
        newBio: bio,
        newPhoneNumber: phoneNumber,
        newAddress: address,
      );

      await profileRepo.updateProfile(updatedProfile);
      emit(ProfileLoaded(updatedProfile));
    } catch (e) {
      emit(ProfileError('Error updating profile: $e'));
    }
  }
}

