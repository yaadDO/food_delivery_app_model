import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseOrdersRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getAllOrders() {
    return _firestore.collection('orders').snapshots();
  }

  Future<DocumentSnapshot> getOrderDetails(String orderId) {
    return _firestore.collection('orders').doc(orderId).get();
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }
}