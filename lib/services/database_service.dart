import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save user onboarding data
  Future<void> saveUserData({
    required String uid,
    required String role,
    required String name,
    required String collegeId,
    required String roomNumber,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'role': role,
        'name': name,
        'collegeId': collegeId,
        'roomNumber': roomNumber,
        'hasActiveSubscription': false, // Default for new users
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user data: $e');
      throw e;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Update subscription status
  Future<void> updateSubscriptionStatus(String uid, bool status) async {
    try {
      final Map<String, dynamic> data = {
        'hasActiveSubscription': status,
      };
      if (status) {
        data['subscriptionEndDate'] = Timestamp.fromDate(DateTime.now().add(const Duration(days: 30)));
      } else {
        data['subscriptionEndDate'] = FieldValue.delete();
      }
      await _db.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating subscription: $e');
      throw e;
    }
  }

  // Create a new order
  Future<void> createOrder(Map<String, dynamic> orderData) async {
    try {
      orderData['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('pending_orders').add(orderData);
    } catch (e) {
      print('Error creating order: $e');
      throw e;
    }
  }

  // Get a stream of pending orders
  Stream<QuerySnapshot> getPendingOrdersStream() {
    return _db
        .collection('pending_orders')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Accept an order safely using a transaction
  Future<bool> acceptOrder(String orderId, String deliveryBoyId, Map<String, dynamic> deliveryBoyData) async {
    try {
      final docRef = _db.collection('pending_orders').doc(orderId);
      
      return await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (!snapshot.exists) {
          throw Exception("Order does not exist!");
        }

        if (snapshot.get('status') != 'pending') {
          // Someone else already took it
          return false;
        }

        transaction.update(docRef, {
          'status': 'accepted',
          'deliveryBoyId': deliveryBoyId,
          'deliveryBoyName': deliveryBoyData['name'] ?? 'Unknown',
          'deliveryBoyCollegeId': deliveryBoyData['collegeId'] ?? 'Unknown',
          'deliveryBoyRoomNumber': deliveryBoyData['roomNumber'] ?? 'Unknown',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        
        return true; // Successfully accepted
      });
    } catch (e) {
      print('Error accepting order: $e');
      return false;
    }
  }

  // Complete an order
  Future<void> completeOrder(String orderId) async {
    try {
      await _db.collection('pending_orders').doc(orderId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error completing order: $e');
      throw e;
    }
  }

  // Get a stream of completed orders (history)
  Stream<QuerySnapshot> getHistoryStream(String uid, String role) {
    if (role == 'User') {
      return _db
          .collection('pending_orders')
          .where('status', isEqualTo: 'completed')
          .where('userId', isEqualTo: uid)
          .snapshots();
    } else {
      // Delivery Boy
      return _db
          .collection('pending_orders')
          .where('status', isEqualTo: 'completed')
          .where('deliveryBoyId', isEqualTo: uid)
          .snapshots();
    }
  }

  // Cancel an order (User only, if still pending)
  Future<void> cancelOrder(String orderId) async {
    try {
      await _db.collection('pending_orders').doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling order: $e');
      throw e;
    }
  }

  // Update order status (bought, arrived)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _db.collection('pending_orders').doc(orderId).update({
        'status': newStatus,
        '${newStatus}At': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw e;
    }
  }

  // Get active orders for User Dashboard (not completed, not cancelled)
  Stream<QuerySnapshot> getActiveUserOrdersStream(String uid) {
    return _db
        .collection('pending_orders')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  // Get active deliveries for Delivery Boy (accepted, bought, arrived)
  Stream<QuerySnapshot> getMyActiveDeliveriesStream(String uid) {
    return _db
        .collection('pending_orders')
        .where('deliveryBoyId', isEqualTo: uid)
        .snapshots();
  }

  // --- CHAT METHODS ---

  // Send a message
  Future<void> sendMessage(String orderId, String senderId, String text) async {
    try {
      await _db
          .collection('pending_orders')
          .doc(orderId)
          .collection('messages')
          .add({
        'senderId': senderId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // Get messages stream
  Stream<QuerySnapshot> getMessagesStream(String orderId) {
    return _db
        .collection('pending_orders')
        .doc(orderId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
