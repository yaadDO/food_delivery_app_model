import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../data/orders_repo.dart';

class OrderDetailsPage extends StatefulWidget {
  final String orderId;
  final String initialStatus;

  const OrderDetailsPage({
    required this.orderId,
    required this.initialStatus,
  });

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final FirebaseOrdersRepo ordersRepo = FirebaseOrdersRepo();
  late String _currentStatus;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  Future<String> _getImageUrl(String imagePath) async {
    try {
      return await _storage.ref(imagePath).getDownloadURL();
    } catch (e) {
      print('Error loading image: $e');
      return '';
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      await ordersRepo.updateOrderStatus(widget.orderId, newStatus);
      setState(() {
        _currentStatus = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  void _showStatusUpdateDialog() {
    final statusOptions = [
      'Pending',
      'Delivered'
    ];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statusOptions.map((status) {
            return ListTile(
              leading: _getStatusIcon(status),
              title: Text(status),
              trailing: _currentStatus == status
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _updateStatus(status);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return const Icon(Icons.hourglass_empty, color: Colors.orange);
      case 'Preparing':
        return const Icon(Icons.restaurant, color: Colors.blue);
      case 'Out for Delivery':
        return const Icon(Icons.delivery_dining, color: Colors.purple);
      case 'Delivered':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Preparing':
        return Colors.blue;
      case 'Out for Delivery':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

// Helper method to format date and time
  String _formatOrderDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          if (!_isUpdatingStatus)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _showStatusUpdateDialog,
              tooltip: 'Update Status',
            ),
        ],
      ),
      floatingActionButton: _currentStatus != 'Delivered' && !_isUpdatingStatus
          ? FloatingActionButton.extended(
              onPressed: _showStatusUpdateDialog,
              icon: const Icon(Icons.update),
              label: const Text('Update Status'),
              backgroundColor: Colors.blue,
            )
          : null,
      body: FutureBuilder<DocumentSnapshot>(
        future: ordersRepo.getOrderDetails(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Order not found', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>;
          final paymentReference = data['paymentReference'] as String?;
          final deliveryOption =
              data['deliveryOption'] as String? ?? 'delivery';
          final deliveryFee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
          final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
          final total = (data['total'] as num?)?.toDouble() ?? 0.0;
          final address = data['address'] as String? ?? 'No address provided';
          final paymentMethod = data['paymentMethod'] as String? ?? 'Unknown';
          final userId = data['userId'] as String? ?? 'Unknown User';
          final timestamp = data['timestamp'] as Timestamp?;
          final orderDate = timestamp?.toDate() ?? DateTime.now();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
// Order Status Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Order Status',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            if (_isUpdatingStatus)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentStatus)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(_currentStatus),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _getStatusIcon(_currentStatus),
                              const SizedBox(width: 8),
                              Text(
                                _currentStatus,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(_currentStatus),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

// Delivery/Pickup Information Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Information',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

// Delivery Type
                        Row(
                          children: [
                            Icon(
                              deliveryOption == 'pickup'
                                  ? Icons.storefront
                                  : Icons.delivery_dining,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deliveryOption == 'pickup'
                                        ? 'Store Pickup'
                                        : 'Delivery',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    deliveryOption == 'pickup'
                                        ? 'Customer will pickup at store location'
                                        : 'Order will be delivered to customer',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (deliveryOption == 'delivery') ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),

// Delivery Address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red[400],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Address',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

// Payment Information Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Information',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Icon(
                              paymentMethod == 'Paystack'
                                  ? Icons.credit_card
                                  : Icons.money,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Method',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    paymentMethod,
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (paymentReference != null &&
                            paymentReference.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                color: Colors.green[400],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Reference',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      paymentReference,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],

// Order Date and Time
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Colors.blue[400],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Order Date & Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatOrderDateTime(orderDate),
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

// Order Summary Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

// Subtotal
                        _buildSummaryRow(
                            'Subtotal', '\$${subtotal.toStringAsFixed(2)}'),

// Delivery Fee (only if not pickup or has fee)
                        if (deliveryOption == 'delivery' && deliveryFee > 0)
                          _buildSummaryRow('Delivery Fee',
                              '\$${deliveryFee.toStringAsFixed(2)}'),

                        if (deliveryOption == 'pickup')
                          _buildSummaryRow('Pickup', 'Free'),

                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),

// Total
                        _buildSummaryRow(
                          'Total',
                          '\$${total.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

// Order Items Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Order Items',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${items.length} item${items.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

// Items List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final itemName =
                                item['name'] as String? ?? 'Unknown Item';
                            final itemPrice =
                                (item['price'] as num?)?.toDouble() ?? 0.0;
                            final itemQuantity =
                                (item['quantity'] as num?)?.toInt() ?? 0;
                            final itemTotal = itemPrice * itemQuantity;
                            final imagePath =
                                item['imagePath'] as String? ?? '';

                            return FutureBuilder<String>(
                              future: _getImageUrl(imagePath),
                              builder: (context, imageSnapshot) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[100],
                                    ),
                                    child: imageSnapshot.hasData &&
                                            imageSnapshot.data!.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: CachedNetworkImage(
                                              imageUrl: imageSnapshot.data!,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 1,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Center(
                                                child: Icon(
                                                  Icons.fastfood,
                                                  color: Colors.grey[400],
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: Icon(
                                              Icons.fastfood,
                                              color: Colors.grey[400],
                                              size: 24,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    itemName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        'Price: \$${itemPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Quantity: $itemQuantity',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '\$${itemTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? Colors.green : Colors.black,
              ),
            ),
          ],
        ));
  }
}
