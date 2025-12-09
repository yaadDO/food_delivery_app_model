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

          // Separate orders into non-delivered and delivered
          List<QueryDocumentSnapshot> nonDelivered = [];
          List<QueryDocumentSnapshot> delivered = [];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['status'] == 'Delivered') {
              delivered.add(doc);
            } else {
              nonDelivered.add(doc);
            }
          }

          // Sort non-delivered by timestamp (newest first)
          nonDelivered.sort((a, b) {
            dynamic aTime = (a.data() as Map<String, dynamic>)['timestamp'];
            dynamic bTime = (b.data() as Map<String, dynamic>)['timestamp'];

            // Handle null or missing timestamps
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return (bTime as Timestamp).compareTo(aTime as Timestamp);
          });

          // Sort delivered by timestamp (newest first)
          delivered.sort((a, b) {
            Timestamp aTime = (a.data() as Map<String, dynamic>)['timestamp'];
            Timestamp bTime = (b.data() as Map<String, dynamic>)['timestamp'];
            return bTime.compareTo(aTime);
          });

          // Combine lists with non-delivered first
          List<QueryDocumentSnapshot> sortedDocs = [...nonDelivered, ...delivered];

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              final order = sortedDocs[index];
              final data = order.data() as Map<String, dynamic>;
              final status = data['status'];
              final isDelivered = status == 'Delivered';
              final paymentReference = data['paymentReference'] as String?;

              return FutureBuilder<String>(
                future: _getUserName(data['userId']),
                builder: (context, userSnapshot) {
                  final userName = userSnapshot.data ?? 'Loading...';
                  return ListTile(
                    title: Text(userName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total: \$${data['total'].toStringAsFixed(2)}'),
                        Text('Payment: ${data['paymentMethod']}'),
                        Text('Type: ${data['deliveryOption'] == 'pickup' ? 'Pickup' : 'Delivery'}'),
                        if (paymentReference != null && paymentReference.isNotEmpty)
                          Text('Ref: $paymentReference',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
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