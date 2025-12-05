import 'package:cloud_firestore/cloud_firestore.dart';
import '../../payments/payment_settings.dart';

abstract class SettingsRepo {
Future<PaymentSettings> getPaymentSettings();
Future<void> updatePaymentSettings(PaymentSettings settings);
}
