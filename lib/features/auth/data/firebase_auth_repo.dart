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

      AppUser user = AppUser(
        uid: userCredential.user!.uid,
        email: email,
        name: name,
        isAdmin: email == "admin@once.com",
      );

      await firebaseFirestore
          .collection('users')
          .doc(user.uid)
          .set(user.toJson());

      await updateUserFCMToken();

      return user;
    } catch (e) {
      throw Exception('Registration Failed: $e');
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await firebaseAuth.signInWithCredential(credential);

      DocumentSnapshot userDoc = await firebaseFirestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

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

        await updateUserFCMToken();

        return newUser;
      }

      final userData = userDoc.data() as Map<String, dynamic>;

      await updateUserFCMToken();

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
    try {
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdated': FieldValue.delete(),
        });
      }

      await firebaseAuth.signOut();

      await _googleSignIn.signOut();
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  Future<void> cleanupFCMToken(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdated': FieldValue.delete(),
      });
    } catch (e) {
      print('Error cleaning up FCM token: $e');
    }
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
      name: userData['name'] ?? 'No Name',
      isAdmin: userData['isAdmin'] ?? false,
    );
  }

  Future<void> storeFCMToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateUserFCMToken() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return;

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null) {
        await firebaseFirestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdated': FieldValue.serverTimestamp(),
        });
        print('FCM Token updated: $token');
      }

      messaging.onTokenRefresh.listen((newToken) async {
        await firebaseFirestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'fcmTokenUpdated': FieldValue.serverTimestamp(),
        });
        print('FCM Token refreshed: $newToken');
      });

    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
}