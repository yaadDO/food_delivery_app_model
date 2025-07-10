//This code defines a FirebaseAuthRepo class that implements an AuthRepo interface for handling user authentication
//provides key authentication operations such as user login, registration, logout, and retrieving the currently logged-in useR
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../domain/entities/app_user.dart';
import '../domain/repository/auth_repo.dart';
import 'package:google_sign_in/google_sign_in.dart';


class FirebaseAuthRepo implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
      await firebaseAuth.signInWithCredential(credential);

      // Check if user exists in Firestore
      DocumentSnapshot userDoc = await firebaseFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // Create new user if doesn't exist
      if (!userDoc.exists) {
        final newUser = AppUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          name: userCredential.user!.displayName ?? 'Google User',
          isAdmin: false,
        );

        await firebaseFirestore
            .collection('users')
            .doc(newUser.uid)
            .set(newUser.toJson());

        return newUser;
      }

      // Return existing user
      final userData = userDoc.data() as Map<String, dynamic>;
      return AppUser(
        uid: userCredential.user!.uid,
        email: userCredential.user!.email!,
        name: userData['name'] ?? 'Google User',
        isAdmin: userData['isAdmin'] ?? false,
      );
    } catch (e) {
      throw Exception('Google Sign-In Failed: $e');
    }
  }

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