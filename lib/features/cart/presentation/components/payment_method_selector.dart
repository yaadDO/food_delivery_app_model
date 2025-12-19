import 'package:flutter/material.dart';
import '../../../payments/payment_settings.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selectedMethod;
  final PaymentSettings? paymentSettings;
  final Function(String) onMethodChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    this.paymentSettings,
    required this.onMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> availableMethods = [];

    if (paymentSettings == null || paymentSettings!.allowCashOnDelivery) {
      availableMethods.add({
        'value': 'Cash on Delivery',
        'title': 'Cash on Delivery',
        'subtitle': 'Pay when your order arrives',
        'icon': Icons.money,
      });
    }

    if (paymentSettings == null || paymentSettings!.allowPaystack) {
      availableMethods.add({
        'value': 'Paystack',
        'title': 'Paystack',
        'subtitle': 'Pay securely with card, bank, etc.',
        'icon': Icons.credit_card,
      });
    }

    if (availableMethods.isEmpty) {
      return Column(
        children: [
          Icon(Icons.error_outline, color: Colors.orange, size: 40),
          const SizedBox(height: 10),
          const Text(
            'No payment methods available. Please contact support.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.orange),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: availableMethods.map((method) {
            final isSelected = selectedMethod == method['value'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant ?? Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              elevation: isSelected ? 2 : 0,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    method['icon'] as IconData,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                title: Text(
                  method['title'] as String,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  method['subtitle'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                      : null,
                ),
                onTap: () => onMethodChanged(method['value'] as String),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}