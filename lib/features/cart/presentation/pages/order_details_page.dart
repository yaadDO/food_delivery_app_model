import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
  }

  Future<String> _getImageUrl(String imagePath) async {
    return await _storage.ref(imagePath).getDownloadURL();
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
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return Center(child: Text('Order not found'));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>;

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
                SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return FutureBuilder<String>(
                          future: _getImageUrl(item['imagePath']),
                          builder: (context, imageSnapshot) {
                            return ListTile(
                              leading: imageSnapshot.hasData
                                  ? CachedNetworkImage(
                                imageUrl: imageSnapshot.data!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.error),
                                ),
                              )
                                  : Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[200],
                                child: Icon(Icons.fastfood),
                              ),
                              title: Text(item['name']),
                              subtitle: Text('Quantity: ${item['quantity']}'),
                              trailing: Text('\$${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                            );
                          }
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