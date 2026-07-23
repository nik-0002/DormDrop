import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../theme/theme_provider.dart';
import 'chat_screen.dart';
import 'active_delivery_screen.dart';

class DeliveryDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DeliveryDashboard({super.key, required this.userData});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isProcessing = false;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
    }
  }

  void _handleAccept(String orderId, Map<String, dynamic> orderData) async {
    setState(() => _isProcessing = true);
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final success = await _databaseService.acceptOrder(
          orderId,
          currentUser.uid,
          widget.userData,
        );
        if (!success) throw Exception('Order was already taken by someone else.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted successfully!')),
        );
      } catch (e) {
        if (!mounted) return;
        String errorMessage = 'Failed to accept order.';
        if (e.toString().contains('already taken')) {
          errorMessage = 'This order was already taken by someone else.';
        } else if (e.toString().contains('own order')) {
          errorMessage = 'You cannot accept your own order!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  void _updateStatus(String orderId, String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      if (newStatus == 'completed') {
        await _databaseService.completeOrder(orderId);
      } else {
        await _databaseService.updateOrderStatus(orderId, newStatus);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status.')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Delivery Dashboard',
              style: GoogleFonts.dmSans(
                fontSize: 26, 
                fontWeight: FontWeight.w900,
                color: AppColors.textTitle(isDark),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            indicatorColor: AppColors.tangerine,
            labelColor: AppColors.textTitle(isDark),
            unselectedLabelColor: AppColors.textSecondary(isDark),
            labelStyle: GoogleFonts.pangolin(fontSize: 18, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'My Ongoing Deliveries'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildAvailableOrdersTab(isDark),
                _buildMyDeliveriesTab(currentUser.uid, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getPendingOrdersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading orders.', style: GoogleFonts.pangolin(fontSize: 18, color: Colors.redAccent)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.tangerine));
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return _buildEmptyState('No pending orders right now.\nWaiting for students to order...', isDark);
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.tangerine,
          backgroundColor: isDark ? AppColors.navyDarkest : Colors.white,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              return _buildOrderCard(orderDoc, index, isDark, isAvailableTab: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildMyDeliveriesTab(String uid, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getMyActiveDeliveriesStream(uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading your deliveries.', style: GoogleFonts.pangolin(fontSize: 18, color: Colors.redAccent)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.tangerine));
        }

        final allDocs = snapshot.data!.docs;
        final orders = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];
          return status != 'completed' && status != 'cancelled';
        }).toList();

        if (orders.isEmpty) {
          return _buildEmptyState('No ongoing deliveries.', isDark);
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: AppColors.tangerine,
          backgroundColor: isDark ? AppColors.navyDarkest : Colors.white,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderDoc = orders[index];
              return _buildOrderCard(orderDoc, index, isDark, isAvailableTab: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text, bool isDark) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.tangerine,
      backgroundColor: isDark ? AppColors.navyDarkest : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.pangolin(fontSize: 20, color: AppColors.textMain(isDark), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(QueryDocumentSnapshot orderDoc, int index, bool isDark, {required bool isAvailableTab}) {
    final orderData = orderDoc.data() as Map<String, dynamic>;
    final orderId = orderDoc.id;

    final items = orderData['items'] ?? 'Unknown items';
    final cost = orderData['estimatedCost'] ?? 0;
    final fee = orderData['deliveryFee'] ?? 0;
    final room = orderData['roomNumber'] ?? 'Unknown Room';
    final userName = orderData['userName'] ?? 'User';
    final status = orderData['status'] ?? 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: AppColors.blobGradient(isDark, index),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(30),
          topRight: Radius.circular(index % 2 == 0 ? 50 : 20),
          bottomLeft: const Radius.circular(25),
          bottomRight: const Radius.circular(40),
        ),
        border: Border.all(color: AppColors.borderMain(isDark), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 10, offset: const Offset(5, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Room: $room',
                  style: GoogleFonts.pangolin(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textTitle(isDark),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Cost: ₹$cost',
                      style: GoogleFonts.pangolin(fontSize: 16, color: AppColors.textSecondary(isDark)),
                    ),
                    Text(
                      '+ Fee: ₹$fee',
                      style: GoogleFonts.pangolin(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tangerine,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order by: $userName',
              style: GoogleFonts.pangolin(color: AppColors.textSecondary(isDark), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              items,
              style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textMain(isDark)),
            ),
            const SizedBox(height: 20),
            
            if (isAvailableTab)
              _buildActionButton(
                label: 'Accept Order',
                icon: Icons.check_circle_outline,
                isDark: isDark,
                onTap: _isProcessing ? null : () => _handleAccept(orderId, orderData),
              )
            else
              Column(
                children: [
                  _buildProgressButton(orderId, status, isDark, orderData),
                  const SizedBox(height: 12),
                  _buildChatButton(orderId, userName, isDark),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton(String orderId, String userName, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              orderId: orderId,
              otherUserName: userName,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.tangerine.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.tangerine, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, color: AppColors.tangerine, size: 20),
            const SizedBox(width: 8),
            Text(
              'Chat with $userName',
              style: GoogleFonts.pangolin(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.tangerine,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressButton(String orderId, String status, bool isDark, Map<String, dynamic> orderData) {
    if (status == 'accepted') {
      return _buildActionButton(
        label: 'Mark Items Bought',
        icon: Icons.shopping_cart_checkout,
        isDark: isDark,
        onTap: _isProcessing ? null : () => _updateStatus(orderId, 'bought'),
      );
    } else if (status == 'bought') {
      return _buildActionButton(
        label: 'Mark Arrived',
        icon: Icons.run_circle_outlined,
        isDark: isDark,
        onTap: _isProcessing ? null : () => _updateStatus(orderId, 'arrived'),
      );
    } else if (status == 'arrived') {
      return _buildActionButton(
        label: 'Complete Order',
        icon: Icons.done_all,
        isDark: isDark,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveDeliveryScreen(
                orderId: orderId,
                orderData: orderData,
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({required String label, required IconData icon, required bool isDark, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.secondaryButtonGradient(isDark),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(40),
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(15),
          ),
          border: Border.all(color: AppColors.borderButton(isDark), width: 3),
          boxShadow: [
            BoxShadow(color: AppColors.brutalistShadow(isDark), offset: const Offset(5, 5), blurRadius: 0),
          ],
        ),
        child: onTap == null
            ? Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textButton(isDark)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: AppColors.textButton(isDark), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.pangolin(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textButton(isDark),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
