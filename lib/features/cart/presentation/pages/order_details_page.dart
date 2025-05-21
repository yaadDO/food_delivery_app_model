import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  void _updateStatus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delivery'),
        content: Text('Mark this order as delivered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ordersRepo.updateOrderStatus(widget.orderId, 'Delivered');
      setState(() {
        _currentStatus = 'Delivered';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as delivered')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order Details')),
      floatingActionButton: _currentStatus != 'Delivered'
          ? FloatingActionButton(
        onPressed: _updateStatus,
        child: Icon(Icons.delivery_dining),
        backgroundColor: Colors.green,
      )
          : null,
      body: FutureBuilder<DocumentSnapshot>(
        future: ordersRepo.getOrderDetails(widget.orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_currentStatus',
                    style: TextStyle(
                      color: _currentStatus == 'Delivered'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 8),
                Text('Payment Method: ${data['paymentMethod']}',
                    style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text('Shipping Address: ${data['address']}',
                    style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Text('Items:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: (data['items'] as List).length,
                    itemBuilder: (context, index) {
                      final item = data['items'][index];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('Quantity: ${item['quantity']}'),
                        trailing: Text('\$${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}