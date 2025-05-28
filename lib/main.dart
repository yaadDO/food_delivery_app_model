import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as flutter_stripe;
import 'app.dart';
import 'features/notifications/firebase_api.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  flutter_stripe.Stripe.publishableKey = '';
  flutter_stripe.Stripe.merchantIdentifier = 'merchant.flutter.fooddelivery';
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseApi.initNotifications();
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  runApp(MyApp());
}

//finish stripe payment