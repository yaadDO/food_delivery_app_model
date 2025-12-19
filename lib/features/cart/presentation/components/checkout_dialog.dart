import 'package:flutter/material.dart';
import 'package:food_delivery/features/cart/presentation/components/payment_method_selector.dart';
import '../../../payments/payment_settings.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/models/order_summary.dart';
import 'delivery_option_selector.dart';
import 'order_summary_widget.dart';

class CheckoutResult {
  final String paymentMethod;
  final String deliveryOption;
  final double deliveryFee;

  const CheckoutResult({
    required this.paymentMethod,
    required this.deliveryOption,
    required this.deliveryFee,
  });
}

class CheckoutDialog extends StatefulWidget {
  final List<CartItem> items;
  final String userAddress;
  final PaymentSettings? paymentSettings;
  final Function(CheckoutResult) onConfirm;
  final Function() onCancel;

  const CheckoutDialog({
    super.key,
    required this.items,
    required this.userAddress,
    this.paymentSettings,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  String _selectedPaymentMethod = '';
  String _deliveryOption = 'delivery';
  bool _processingOrder = false;

  @override
  void initState() {
    super.initState();
    _initializePaymentMethod();
  }

  void _initializePaymentMethod() {
    if (widget.paymentSettings != null) {
      if (widget.paymentSettings!.allowCashOnDelivery) {
        _selectedPaymentMethod = 'Cash on Delivery';
      } else if (widget.paymentSettings!.allowPaystack) {
        _selectedPaymentMethod = 'Paystack';
      }
    }
  }

  double _calculateDeliveryFee() {
    if (_deliveryOption == 'pickup') return 0.0;
    if (widget.paymentSettings?.deliveryFeeEnabled == true) {
      return widget.paymentSettings!.deliveryFeeAmount;
    }
    return 0.0;
  }

  OrderSummary _calculateOrderSummary() {
    final deliveryFee = _calculateDeliveryFee();
    return OrderSummary.fromItems(widget.items, deliveryFee);
  }

  @override
  Widget build(BuildContext context) {
    final orderSummary = _calculateOrderSummary();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Confirm Order',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Delivery/Pickup Option
            if (widget.paymentSettings?.allowPickup == true)
              DeliveryOptionSelector(
                selectedOption: _deliveryOption,
                onOptionChanged: (option) {
                  setState(() => _deliveryOption = option);
                },
              ),

            // Address Section
            if (_deliveryOption == 'delivery')
              _buildAddressSection(),

            const SizedBox(height: 16),

            // Payment Method
            PaymentMethodSelector(
              selectedMethod: _selectedPaymentMethod,
              paymentSettings: widget.paymentSettings,
              onMethodChanged: (method) {
                setState(() => _selectedPaymentMethod = method);
              },
            ),

            const SizedBox(height: 20),

            // Order Summary
            OrderSummaryWidget(
              summary: orderSummary,
              deliveryOption: _deliveryOption,
            ),

            // Info Messages
            _buildInfoMessages(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _processingOrder ? null : widget.onCancel,
          child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
        ),
        ElevatedButton(
          onPressed: _processingOrder || _selectedPaymentMethod.isEmpty
              ? null
              : () => _handleConfirm(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: _processingOrder
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text('Confirm Order', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined, color: Theme.of(context).primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Address',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.userAddress,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoMessages() {
    final deliveryFee = _calculateDeliveryFee();

    if (_deliveryOption == 'delivery' && deliveryFee > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delivery fee will be added to your total',
                style: TextStyle(color: Colors.blue[600], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_deliveryOption == 'pickup') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          children: [
            Icon(Icons.storefront, color: Colors.green[600], size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'ll pickup your order at our store location',
                style: TextStyle(color: Colors.green[600], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _handleConfirm() {
    setState(() => _processingOrder = true);

    final result = CheckoutResult(
      paymentMethod: _selectedPaymentMethod,
      deliveryOption: _deliveryOption,
      deliveryFee: _calculateDeliveryFee(),
    );

    widget.onConfirm(result);
  }
}
