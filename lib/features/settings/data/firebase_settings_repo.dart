import 'package:cloud_firestore/cloud_firestore.dart';
import '../../payments/payment_settings.dart';
import '../repo/settings_repo.dart';

class FirebaseSettingsRepo implements SettingsRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<PaymentSettings> getPaymentSettings() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('paymentSettings')
          .get();

      if (doc.exists) {
        return PaymentSettings.fromMap(doc.data()!);
      } else {
        final defaultSettings = PaymentSettings(
          allowCashOnDelivery: true,
          allowPaystack: true,
          deliveryFeeEnabled: false,
          deliveryFeeAmount: 5.0,
          allowPickup: true,
          lastUpdated: DateTime.now(),
        );

        await doc.reference.set(defaultSettings.toMap());
        return defaultSettings;
      }
    } catch (e) {
      throw Exception('Error fetching payment settings: $e');
    }
  }

  @override
  Future<void> updatePaymentSettings(PaymentSettings settings) async {
    try {
      await _firestore
          .collection('settings')
          .doc('paymentSettings')
          .set(settings.copyWith(lastUpdated: DateTime.now()).toMap());
    } catch (e) {
      throw Exception('Error updating payment settings: $e');
    }
  }
}