//Handles various user profile operations, including fetching profiles, updating profile information, and toggling follow status
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/profile_user.dart';
import '../../domain/repository/profile_repo.dart';
import 'profile_states.dart';

class ProfileCubit extends Cubit<ProfileState> {
  //his field represents the repository for profile-related operations, such as fetching or updating user profiles.
  final ProfileRepo profileRepo;
  //This field represents the repository for handling image uploads, with separate methods for web and mobile platforms.
  //final StorageRepo storageRepo;

  ProfileCubit({
    required this.profileRepo,
   // required this.storageRepo,
  }) : super(ProfileInitial());

  //Fetches a user profile by their uid
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

  //This method fetches a user profile and directly returns a ProfileUser object or null if the user is not found
  Future<ProfileUser?> getUserProfile(String uid) async {
    final user = await profileRepo.fetchUserProfile(uid);
    return user;
  }

  //Updates the user's profile information
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

