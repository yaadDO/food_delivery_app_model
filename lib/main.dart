import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    //FirebaseApi.initNotifications();
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  runApp(MyApp());
}