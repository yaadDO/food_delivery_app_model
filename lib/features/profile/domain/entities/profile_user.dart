//This class extends the AppUser class and represents a user's profile with additional information such as bio, profile image URL, followers, and following.


import '../../../auth/domain/entities/app_user.dart';

class ProfileUser extends AppUser {
  final String phoneNumber;
  final String address;
  final String bio;

  ProfileUser({
    required super.uid,
    required super.email,
    required super.name,
    required this.bio,
    required this.phoneNumber,
    required this.address,
  });

  ProfileUser copyWith({
    String? newBio,
    String? newPhoneNumber,
    String? newAddress,
    String? newName,
  }) {
    return ProfileUser(
      uid: uid,
      email: email,
      name: newName ?? name,
      bio: newBio ?? bio,
      phoneNumber: newPhoneNumber ?? phoneNumber,
      address: newAddress ?? address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'address': address,
    };
  }

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      uid: json['uid'],
      email: json['email'],
      name: json['name'],
      bio: json['bio'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'] ?? '',
    );
  }
}