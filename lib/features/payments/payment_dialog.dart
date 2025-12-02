import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_paystack_plus/flutter_paystack_plus.dart';

class PaystackPaymentDialog extends StatelessWidget {
  final double amount;
  final String userEmail;
  final Function(Map<String, dynamic>) onPaymentComplete;

  const PaystackPaymentDialog({
    super.key,
    required this.amount,
    required this.userEmail,
    required this.onPaymentComplete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Pay with Paystack'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Amount: \$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click "Pay Now" to complete your payment securely.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => _processPayment(context),
          child: const Text('Pay Now'),
        ),
      ],
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    try {
      // For production, store these keys securely (use environment variables or backend)
      const publicKey = 'pk_test_4ffd8832d059db8ef7d652f19ed4ec8225802ec4'; // Required for Web
      const secretKey = 'sk_test_e0fcf076cb8e347af95ff515d35711b2ac1555f4'; // Required for Mobile

      final reference = DateTime.now().millisecondsSinceEpoch.toString();
      final amountInKobo = (amount * 100).toInt(); // Convert to kobo/cents

      // Platform-specific configuration
      if (kIsWeb) {
        // Web implementation
        await FlutterPaystackPlus.openPaystackPopup(
          publicKey: publicKey,
          customerEmail: userEmail,
          amount: amountInKobo.toString(),
          reference: reference,
          currency: 'NGN', // Change to your currency (USD, GHS, etc.)
          onClosed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment was cancelled')),
            );
          },
          onSuccess: () {
            Navigator.pop(context);
            onPaymentComplete({
              'success': true,
              'paymentReference': reference,
              'paymentMethod': 'Paystack',
            });
          },
        );
      } else {
        // Mobile implementation (Android/iOS)
        await FlutterPaystackPlus.openPaystackPopup(
          customerEmail: userEmail,
          context: context, // Required for mobile
          secretKey: secretKey,
          amount: amountInKobo.toString(),
          reference: reference,
          currency: 'ZAR',
          callBackUrl: "https://standard.paystack.co/close", // Use Paystack's close URL or your own
          onClosed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment was cancelled')),
            );
          },
          onSuccess: () {
            Navigator.pop(context);
            onPaymentComplete({
              'success': true,
              'paymentReference': reference,
              'paymentMethod': 'Paystack',
            });
          },
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.toString()}')),
      );
      onPaymentComplete({'success': false});
    }
  }
}