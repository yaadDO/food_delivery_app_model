import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/orders_repo.dart';
import 'order_details_page.dart';

class CartAdmin extends StatelessWidget {
  final FirebaseOrdersRepo ordersRepo = FirebaseOrdersRepo();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> _getUserName(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.exists ? doc.get('name') ?? 'Unknown' : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('All Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRepo.getAllOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final order = snapshot.data!.docs[index];
              final data = order.data() as Map<String, dynamic>;
              final status = data['status'];
              final isDelivered = status == 'Delivered';

              return FutureBuilder<String>(
                future: _getUserName(data['userId']),
                builder: (context, userSnapshot) {
                  final userName = userSnapshot.data ?? 'Loading...';
                  return ListTile(
                    title: Text(userName),
                    subtitle: Text('Total: \$${data['total'].toStringAsFixed(2)}'),
                    trailing: Text(
                      isDelivered ? 'Delivered' : 'Pending',
                      style: TextStyle(
                        color: isDelivered ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailsPage(
                          orderId: order.id,
                          initialStatus: status,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}