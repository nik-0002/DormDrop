import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/database_service.dart';
import '../theme/theme_provider.dart';
import 'chat_screen.dart';

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
  int _selectedCategoryIndex = 0;

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
      color: AppColors.tangerine,
      backgroundColor: isDark ? AppColors.navyDarkest : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // SEARCH BAR WITH GLASSMORPHISM
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.searchBarBackground(isDark),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.borderMain(isDark),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.glassmorphismShadow(isDark),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondary(isDark)),
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary(isDark)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      style: GoogleFonts.dmSans(color: AppColors.textMain(isDark)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // CATEGORY CHIPS - HORIZONTAL SCROLL
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    final categories = ['Snacks', 'Drinks', 'Meals', 'Desserts', 'Beverages'];
                    final category = categories[index];
                    final isSelected = index == _selectedCategoryIndex;

                    return Padding(
                      padding: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.categoryChipBackground(isDark, isSelected),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                ? AppColors.tangerine
                                : AppColors.borderMain(isDark),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected ? AppColors.glassmorphismShadow(isDark) : [],
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.dmSans(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                ? Colors.white
                                : AppColors.textMain(isDark),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

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

              // Order Form Card
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.blobGradient(isDark, 0),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    AppColors.claymorphismShadow(isDark),
                    AppColors.claymorphismHighlight(isDark),
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
                            decoration: InputDecoration(
                              hintText: 'List items you need (e.g., 2x Pizza, 1x Coke, 3x Cookies)',
                              hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondary(isDark)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.dmSans(color: AppColors.textMain(isDark)),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please list the items you need';
                              }
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
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Estimated cost (₹)',
                              hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondary(isDark)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.dmSans(color: AppColors.textMain(isDark)),
                            onChanged: (value) {
                              setState(() {
                                if (value.isNotEmpty) {
                                  _deliveryFee = double.parse(value) * 0.1;
                                } else {
                                  _deliveryFee = 0.0;
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the estimated cost';
                              }
                              try {
                                double.parse(value);
                              } catch (e) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Delivery Fee Display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.navyDarkest : Colors.orange[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppColors.tangerine.withOpacity(0.5), width: 1.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Fee (10%):', style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.textMain(isDark), fontWeight: FontWeight.bold)),
                              Text('₹${_deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.dmSans(fontSize: 18, color: AppColors.tangerine, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // SUBMIT ORDER WITH CLAYMORPHISM
                        GestureDetector(
                          onTap: _isSubmitting ? null : _submitOrder,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryButtonGradient(isDark),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: AppColors.borderButton(isDark),
                                width: 2,
                              ),
                              boxShadow: [
                                AppColors.claymorphismShadow(isDark),
                                AppColors.claymorphismHighlight(isDark),
                              ],
                            ),
                            child: _isSubmitting
                              ? Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.textButton(isDark),
                                    ),
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
              const SizedBox(height: 100),
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
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.borderMain(isDark), width: 1.5),
        boxShadow: [
          AppColors.claymorphismShadow(isDark),
          AppColors.claymorphismHighlight(isDark),
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
                color: isDark ? AppColors.navyDarkest : Colors.orange[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.tangerine.withOpacity(0.5), width: 1.5),
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
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      orderId: doc.id,
                      otherUserName: deliveryBoyName,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.tangerine.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.tangerine, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: AppColors.tangerine, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Chat with $deliveryBoyName',
                      style: GoogleFonts.pangolin(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.tangerine,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Timeline
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
                          color: isActive ? AppColors.tangerine : (isDark ? Colors.grey[800] : Colors.grey[300]),
                          border: Border.all(color: isDark ? AppColors.navyLighter : Colors.white, width: 2),
                        ),
                        child: isActive ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                      if (!isLast)
                        Container(
                          width: 4,
                          height: 30,
                          color: isActive ? AppColors.tangerine : (isDark ? Colors.grey[800] : Colors.grey[300]),
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
                    BoxShadow(
                      color: isDark ? Colors.redAccent : Colors.black,
                      offset: const Offset(3, 3),
                    ),
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