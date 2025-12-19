import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/profile_user.dart';
import '../domain/repository/profile_repo.dart';

class FirebaseProfileRepo implements ProfileRepo {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      final userDoc = await firebaseFirestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        return ProfileUser(
          uid: uid,
          email: userData?['email'] ?? '',
          name: userData?['name'] ?? '',
          bio: userData?['bio'] ?? '',
          phoneNumber: userData?['phoneNumber'] ?? '',
          address: userData?['address'] ?? '',
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateProfile(ProfileUser updatedProfile) async {
    try {
      await firebaseFirestore.collection('users').doc(updatedProfile.uid).update({
        'bio': updatedProfile.bio,
        'phoneNumber': updatedProfile.phoneNumber,
        'address': updatedProfile.address,
        'name': updatedProfile.name,
      });
    } catch (e) {
      throw Exception(e);
    }
  }


  @override
  Future<List<ProfileUser>> fetchUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final users = <ProfileUser>[];
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(
        i,
        i + 10 > uids.length ? uids.length : i + 10,
      );
      final querySnapshot = await firebaseFirestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        users.add(ProfileUser(
          uid: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          bio: data['bio'] ?? '',
          phoneNumber: data['phoneNumber']?.toString() ?? '',
          address: data['address']?.toString() ?? '',
        ));
      }
    }
    return users;
  }
}

