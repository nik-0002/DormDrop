import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save user onboarding data
  Future<void> saveUserData({
    required String uid,
    required String role,
    required String name,
    required String collegeId,
    required String roomNumber,
  }) async {
    // Security Check: Ensure user is only saving their own data
    if (_auth.currentUser?.uid != uid) throw Exception("Unauthorized");

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
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    try {
      orderData['userId'] = user.uid; // Force correct UID
      orderData['createdAt'] = FieldValue.serverTimestamp();
      await _db.collection('pending_orders').add(orderData);
    } catch (e) {
      print('Error creating order: $e');
      throw e;
    }
  }

  // Get a stream of pending orders (Limited to 50 latest to prevent lag)
  Stream<QuerySnapshot> getPendingOrdersStream() {
    return _db
        .collection('pending_orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .limit(50)
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
          return false; // Already taken or cancelled
        }

        // Security: Prevent self-delivery
        if (snapshot.get('userId') == deliveryBoyId) {
          throw Exception("You cannot accept your own order.");
        }

        transaction.update(docRef, {
          'status': 'accepted',
          'deliveryBoyId': deliveryBoyId,
          'deliveryBoyName': deliveryBoyData['name'] ?? 'Unknown',
          'deliveryBoyCollegeId': deliveryBoyData['collegeId'] ?? 'Unknown',
          'deliveryBoyRoomNumber': deliveryBoyData['roomNumber'] ?? 'Unknown',
          'acceptedAt': FieldValue.serverTimestamp(),
          'otp': (1000 + Random().nextInt(9000)).toString(), // Generate 4-digit OTP
        });
        
        return true; // Successfully accepted
      });
    } catch (e) {
      print('Error accepting order: $e');
      return false;
    }
  }

  // Complete an order with OTP validation
  Future<bool> completeOrder(String orderId, String enteredOtp) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Unauthorized");

    try {
      final doc = await _db.collection('pending_orders').doc(orderId).get();
      if (!doc.exists) return false;

      // Security: Only assigned delivery boy can complete
      if (doc.get('deliveryBoyId') != user.uid) throw Exception("Unauthorized");

      if (doc.get('otp') == enteredOtp) {
        await _db.collection('pending_orders').doc(orderId).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    } catch (e) {
      print('Error completing order: $e');
      throw e;
    }
  }

  // Submit Rating
  Future<void> submitRating(String orderId, double rating, String review) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Unauthorized");

    try {
      final doc = await _db.collection('pending_orders').doc(orderId).get();
      if (!doc.exists || doc.get('userId') != user.uid) throw Exception("Unauthorized");

      await _db.collection('pending_orders').doc(orderId).update({
        'rating': rating,
        'review': review,
        'ratedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error submitting rating: $e');
      throw e;
    }
  }

  // Get a stream of completed orders (history) with limit for scaling
  Stream<QuerySnapshot> getHistoryStream(String uid, String role, {int limit = 20}) {
    Query query = _db.collection('pending_orders').where('status', isEqualTo: 'completed');

    if (role == 'User') {
      query = query.where('userId', isEqualTo: uid);
    } else {
      query = query.where('deliveryBoyId', isEqualTo: uid);
    }

    return query.orderBy('completedAt', descending: true).limit(limit).snapshots();
  }

  // Cancel an order (User only, if still pending)
  Future<void> cancelOrder(String orderId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Unauthorized");

    try {
      final doc = await _db.collection('pending_orders').doc(orderId).get();
      if (!doc.exists || doc.get('userId') != user.uid) throw Exception("Unauthorized");

      if (doc.get('status') != 'pending') {
        throw Exception("Cannot cancel an order that is already accepted.");
      }

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
    final user = _auth.currentUser;
    if (user == null) throw Exception("Unauthorized");

    try {
      final doc = await _db.collection('pending_orders').doc(orderId).get();
      if (!doc.exists || doc.get('deliveryBoyId') != user.uid) throw Exception("Unauthorized");

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
  Future<void> sendMessage(String orderId, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Simple validation
    if (text.trim().isEmpty || text.length > 500) return;

    try {
      // Security Check: Ensure sender is part of the order
      final orderDoc = await _db.collection('pending_orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception("Order not found");

      final data = orderDoc.data()!;
      if (data['userId'] != user.uid && data['deliveryBoyId'] != user.uid) {
        throw Exception("Unauthorized to send message");
      }

      await _db
          .collection('pending_orders')
          .doc(orderId)
          .collection('messages')
          .add({
        'senderId': user.uid, // Security: Always use the auth UID, not a passed param
        'text': text.trim(),
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
