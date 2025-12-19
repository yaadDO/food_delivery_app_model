import 'package:flutter/material.dart';
import '../../domain/models/order_summary.dart';

class OrderSummaryWidget extends StatelessWidget {
  final OrderSummary summary;
  final String deliveryOption;

  const OrderSummaryWidget({
    super.key,
    required this.summary,
    this.deliveryOption = 'delivery',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildOrderSummaryRow('Subtotal', '\$${summary.subtotal.toStringAsFixed(2)}'),
          if (summary.deliveryFee > 0 && deliveryOption == 'delivery')
            _buildOrderSummaryRow('Delivery Fee', '\$${summary.deliveryFee.toStringAsFixed(2)}'),
          if (deliveryOption == 'pickup')
            _buildOrderSummaryRow('Pickup', 'Free'),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                '\$${summary.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${summary.itemCount} item${summary.itemCount > 1 ? 's' : ''}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600])),
        ],
      ),
    );
  }
}