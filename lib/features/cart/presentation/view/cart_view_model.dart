import 'package:flutter/material.dart';
import '../../../payments/payment_settings.dart';
import '../../../settings/data/firebase_settings_repo.dart';
import '../../domain/entities/cart_item.dart';

/// Handles business logic for the cart page
class CartViewModel extends ChangeNotifier {
  final FirebaseSettingsRepo settingsRepo;

  PaymentSettings? _paymentSettings;
  bool _loadingPaymentSettings = false;
  String _selectedPaymentMethod = '';
  String _deliveryOption = 'delivery';

  CartViewModel({required this.settingsRepo});

  PaymentSettings? get paymentSettings => _paymentSettings;
  bool get loadingPaymentSettings => _loadingPaymentSettings;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  String get deliveryOption => _deliveryOption;

  Future<void> loadPaymentSettings() async {
    _loadingPaymentSettings = true;
    notifyListeners();

    try {
      _paymentSettings = await settingsRepo.getPaymentSettings();
      if (_paymentSettings != null) {
        if (_paymentSettings!.allowCashOnDelivery) {
          _selectedPaymentMethod = 'Cash on Delivery';
        } else if (_paymentSettings!.allowPaystack) {
          _selectedPaymentMethod = 'Paystack';
        }
      }
    } catch (e) {
      // Fallback to default settings
      _paymentSettings = PaymentSettings(
        allowCashOnDelivery: true,
        allowPaystack: true,
        deliveryFeeEnabled: false,
        deliveryFeeAmount: 5.0,
        allowPickup: true,
        lastUpdated: DateTime.now(),
      );
      _selectedPaymentMethod = 'Cash on Delivery';
    } finally {
      _loadingPaymentSettings = false;
      notifyListeners();
    }
  }

  void setDeliveryOption(String option) {
    _deliveryOption = option;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  bool isPaymentMethodAllowed(String method) {
    if (_paymentSettings == null) return true;

    if (method == 'Cash on Delivery') {
      return _paymentSettings!.allowCashOnDelivery;
    } else if (method == 'Paystack') {
      return _paymentSettings!.allowPaystack;
    }
    return false;
  }

  bool get paymentMethodsAvailable {
    if (_paymentSettings == null) return true;
    return _paymentSettings!.allowCashOnDelivery || _paymentSettings!.allowPaystack;
  }

  double calculateDeliveryFee() {
    if (_deliveryOption == 'pickup') return 0.0;
    if (_paymentSettings?.deliveryFeeEnabled == true) {
      return _paymentSettings!.deliveryFeeAmount;
    }
    return 0.0;
  }
}