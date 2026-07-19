import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../utils/fee_calculator.dart';
import '../theme/theme_provider.dart';

class UserDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDashboard({super.key, required this.userData});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemsController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  double _deliveryFee = 0.0;
  bool _isSubmitting = false;

  final DatabaseService _databaseService = DatabaseService();

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          await _databaseService.createOrder({
            'userId': currentUser.uid,
            'userName': widget.userData['name'] ?? 'Unknown',
            'roomNumber': widget.userData['roomNumber'] ?? 'Unknown',
            'items': _itemsController.text.trim(),
            'estimatedCost': double.parse(_costController.text.trim()),
            'deliveryFee': _deliveryFee,
            'status': 'pending',
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order submitted successfully!')),
          );
          
          _itemsController.clear();
          _costController.clear();
          setState(() {
            _deliveryFee = 0.0;
          });
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit order.')),
          );
        } finally {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
            });
          }
        }
      }
    }
  }

  void _cancelOrder(String orderId) async {
    try {
      await _databaseService.cancelOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel order.')),
      );
    }
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: isDark ? AppColors.electricCyan : Colors.deepPurpleAccent,
      backgroundColor: isDark ? const Color(0xFF0B0510) : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // Active Orders Section
              if (currentUser != null)
                StreamBuilder<QuerySnapshot>(
                  stream: _databaseService.getActiveUserOrdersStream(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final activeDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final status = data['status'];
                        return status != 'completed' && status != 'cancelled';
                      }).toList();

                      if (activeDocs.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Active Orders',
                                style: GoogleFonts.dmSans(
                                  fontSize: 24, 
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textTitle(isDark),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...activeDocs.map((doc) => _buildActiveOrderCard(doc, isDark)).toList(),
                            const SizedBox(height: 20),
                          ],
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),

              Center(
                child: Text(
                  'Place a New Order',
                  style: GoogleFonts.dmSans(
                    fontSize: 26, 
                    fontWeight: FontWeight.w900,
                    color: AppColors.textTitle(isDark),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Organic Blob Card
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.blobGradient(isDark, 0),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(60),
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                  border: Border.all(color: AppColors.borderMain(isDark), width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Items Input
                        Container(
                          decoration: BoxDecoration(
                            gradient: isDark 
                              ? const LinearGradient(colors: [Color(0xFF200F3A), Color(0xFF2C1B4D)])
                              : const LinearGradient(colors: [Color(0xFFFFE5D9), Color(0xFFD8F3DC)]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderMain(isDark), width: 1.5),
                          ),
                          child: TextFormField(
                            controller: _itemsController,
                            maxLines: 3,
                            style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textMain(isDark), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Items...',
                              labelStyle: GoogleFonts.pangolin(color: AppColors.textTitle(isDark), fontWeight: FontWeight.bold),
                              hintText: 'e.g. Lays, Coke, Maggi',
                              hintStyle: GoogleFonts.pangolin(color: AppColors.textSecondary(isDark)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Please enter the items';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Cost Input
                        Container(
                          decoration: BoxDecoration(
                            gradient: isDark 
                              ? const LinearGradient(colors: [Color(0xFF2C1B4D), Color(0xFF200F3A)])
                              : const LinearGradient(colors: [Color(0xFFD8F3DC), Color(0xFFFFE5D9)]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderMain(isDark), width: 1.5),
                          ),
                          child: TextFormField(
                            controller: _costController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textMain(isDark), fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Estimated Cost (₹)',
                              labelStyle: GoogleFonts.pangolin(color: AppColors.textTitle(isDark), fontWeight: FontWeight.bold),
                              prefixText: '₹ ',
                              prefixStyle: GoogleFonts.pangolin(color: AppColors.textMain(isDark), fontWeight: FontWeight.bold),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onChanged: (value) {
                              final cost = double.tryParse(value);
                              if (cost != null && cost >= 0) {
                                setState(() {
                                  _deliveryFee = FeeCalculator.calculateFee(cost);
                                });
                              } else {
                                setState(() {
                                  _deliveryFee = 0.0;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Please enter the estimated cost';
                              final cost = double.tryParse(value);
                              if (cost == null) return 'Please enter a valid number';
                              if (cost > 200) return 'Total cost cannot exceed ₹200';
                              if (cost <= 0) return 'Cost must be greater than 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Delivery Fee Text
                        Text(
                          'Delivery Fee: ₹$_deliveryFee',
                          style: GoogleFonts.pangolin(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? AppColors.electricCyan : Colors.deepPurple[800]),
                        ),
                        const SizedBox(height: 32),
                        
                        // Submit Order Blob Button
                        GestureDetector(
                          onTap: _isSubmitting ? null : _submitOrder,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryButtonGradient(isDark),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(40),
                              ),
                              border: Border.all(color: AppColors.borderButton(isDark), width: 3),
                              boxShadow: [
                                BoxShadow(color: AppColors.brutalistShadow(isDark), offset: const Offset(5, 5), blurRadius: 0),
                              ],
                            ),
                            child: _isSubmitting
                                ? Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textButton(isDark)),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      'Submit Order',
                                      style: GoogleFonts.pangolin(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textButton(isDark),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] ?? 'pending';
    final items = data['items'] ?? '';
    final deliveryBoyName = data['deliveryBoyName'];

    final deliveryBoyCollegeId = data['deliveryBoyCollegeId'];
    final deliveryBoyRoom = data['deliveryBoyRoomNumber'];

    int statusIndex = 0;
    if (status == 'accepted') statusIndex = 1;
    if (status == 'bought') statusIndex = 2;
    if (status == 'arrived') statusIndex = 3;

    final steps = [
      'Placed',
      'Accepted',
      'Items Bought',
      'Arrived',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.blobGradient(isDark, 1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.borderMain(isDark), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 10, offset: const Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            items,
            style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textTitle(isDark), fontWeight: FontWeight.bold),
          ),
          if (deliveryBoyName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A0B2E) : Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? AppColors.electricCyan.withOpacity(0.5) : Colors.deepPurpleAccent.withOpacity(0.5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Partner:', style: GoogleFonts.pangolin(fontSize: 14, color: AppColors.textSecondary(isDark), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('$deliveryBoyName', style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textMain(isDark), fontWeight: FontWeight.bold)),
                  Text('College ID: $deliveryBoyCollegeId | Room: $deliveryBoyRoom', style: GoogleFonts.pangolin(fontSize: 14, color: AppColors.textSecondary(isDark))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Vertical Timeline
          Column(
            children: List.generate(4, (index) {
              final isActive = index <= statusIndex;
              final isLast = index == 3;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? (isDark ? AppColors.neonPink : Colors.deepPurpleAccent) : (isDark ? Colors.grey[800] : Colors.grey[300]),
                          border: Border.all(color: isDark ? AppColors.electricCyan : Colors.white, width: 2),
                        ),
                        child: isActive ? Icon(Icons.check, size: 16, color: isDark ? Colors.black : Colors.white) : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 4,
                          height: 30,
                          color: isActive ? (isDark ? AppColors.neonPink : Colors.deepPurpleAccent) : (isDark ? Colors.grey[800] : Colors.grey[300]),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      steps[index],
                      style: GoogleFonts.pangolin(
                        fontSize: 16,
                        color: isActive ? AppColors.textMain(isDark) : AppColors.textSecondary(isDark),
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          
          if (status == 'pending') ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _cancelOrder(doc.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.red[900] : Colors.red[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red, width: 2),
                  boxShadow: [
                    BoxShadow(color: isDark ? Colors.redAccent : Colors.black, offset: const Offset(3, 3)),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Cancel Order',
                    style: GoogleFonts.pangolin(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.red[900],
                    ),
                  ),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
