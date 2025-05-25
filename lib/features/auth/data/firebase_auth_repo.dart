//This code defines a FirebaseAuthRepo class that implements an AuthRepo interface for handling user authentication
//provides key authentication operations such as user login, registration, logout, and retrieving the currently logged-in useR
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/entities/app_user.dart';
import '../domain/repository/auth_repo.dart';


class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  @override
  Future<AppUser?> loginWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      DocumentSnapshot userDoc = await firebaseFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Add null checks for document fields
      if (!userDoc.exists) throw Exception('User document not found');

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        name: userData['name'] ?? 'No Name', // Fallback value
        isAdmin: userData['isAdmin'] ?? false,
      );

      return user;
    }
    catch (e) {
      throw Exception('Login Failed: $e');
    }
  }

  @override
  Future<AppUser?> registerWithEmailPassword(String name, String email, String password) async {
    try {
      UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Add isAdmin flag during registration (for testing only)
      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        isAdmin: email == "admin@once.com", // Only for testing
      );

      await firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());

      return user;
    } catch (e) {
      throw Exception('Registration Failed: $e');
    }
  }
  /*Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) return null;

      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final UserCredential userCredential =
      await firebaseAuth.signInWithCredential(credential);

      // Check if new user
      if (userCredential.additionalUserInfo!.isNewUser) {
        await firebaseFirestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName ?? 'No Name',
        });
      }

      return userCredential;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }*/

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    DocumentSnapshot userDoc =
    await firebaseFirestore.collection('users').doc(firebaseUser.uid).get();

    if (!userDoc.exists) return null;

    final userData = userDoc.data() as Map<String, dynamic>? ?? {};

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email!,
      name: userData['name'] ?? 'No Name', // Fallback value
      isAdmin: userData['isAdmin'] ?? false,
    );
  }

  Future<void> storeFCMToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    }
  }
}