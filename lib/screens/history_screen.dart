import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../theme/theme_provider.dart';

class HistoryScreen extends StatelessWidget {
  final String role;
  
  HistoryScreen({super.key, required this.role});

  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isDark = AppColors.isDark(context);
    
    if (currentUser == null) {
      return Center(
        child: Text(
          'User not authenticated.',
          style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textMain(isDark)),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getHistoryStream(currentUser.uid, role),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history.',
              style: GoogleFonts.pangolin(fontSize: 18, color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.tangerine));
        }

        final List<QueryDocumentSnapshot> orders = snapshot.data!.docs.toList();
        
        // Sort by completedAt descending locally
        orders.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['completedAt'] as Timestamp?;
          final bTime = bData['completedAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (orders.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            color: AppColors.tangerine,
            backgroundColor: isDark ? AppColors.navyDarkest : Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                alignment: Alignment.center,
                child: Text(
                  role == 'User' 
                      ? 'You have not made any orders yet.'
                      : 'You have not completed any deliveries yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pangolin(fontSize: 20, color: AppColors.textMain(isDark), fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          color: AppColors.tangerine,
          backgroundColor: isDark ? AppColors.navyDarkest : Colors.white,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              
              final items = orderData['items'] ?? 'Unknown items';
              final cost = orderData['estimatedCost'] ?? 0;
              final fee = orderData['deliveryFee'] ?? 0;
              final room = orderData['roomNumber'] ?? 'Unknown Room';
              final timestamp = orderData['completedAt'] as Timestamp?;
              
              String formattedDate = 'Unknown date';
              if (timestamp != null) {
                formattedDate = DateFormat('MMM d, yyyy - h:mm a').format(timestamp.toDate());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: AppColors.blobGradient(isDark, index),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(30),
                    topRight: const Radius.circular(40),
                    bottomLeft: const Radius.circular(25),
                    bottomRight: Radius.circular(index % 2 == 0 ? 50 : 20),
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
                          Expanded(
                            child: Text(
                              role == 'User' ? 'Order' : 'Delivery: Room $room',
                              style: GoogleFonts.pangolin(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textTitle(isDark),
                              ),
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
                      const SizedBox(height: 12),
                      Text(
                        items,
                        style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textMain(isDark)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: GoogleFonts.pangolin(color: AppColors.textSecondary(isDark), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryButtonGradient(isDark),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: AppColors.tangerine, width: 1.5),
                            ),
                            child: Text(
                              'Completed',
                              style: GoogleFonts.pangolin(color: AppColors.textMain(isDark), fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
