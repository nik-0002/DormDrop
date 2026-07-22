import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'auth_wrapper.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final String role = userData['role'] ?? 'Unknown Role';
    final String name = userData['name'] ?? 'User';
    final bool isDark = AppColors.isDark(context);

    int calculateDaysLeft(Map<String, dynamic> data) {
      if (data['hasActiveSubscription'] != true) return 0;
      final endTimestamp = data['subscriptionEndDate'] as Timestamp?;
      if (endTimestamp == null) {
        return 30;
      }
      final endDate = endTimestamp.toDate();
      final now = DateTime.now();
      
      final today = DateTime(now.year, now.month, now.day);
      final endDay = DateTime(endDate.year, endDate.month, endDate.day);
      
      final difference = endDay.difference(today).inDays;
      return difference > 0 ? difference : 0;
    }

    final int daysLeft = calculateDaysLeft(userData);
    final String subText = userData['hasActiveSubscription'] == true 
        ? 'Active ($daysLeft days left)' 
        : 'Inactive';

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      color: AppColors.electricCyan,
      backgroundColor: isDark ? const Color(0xFF0B0510) : Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Balancing space for the toggle icon
                  Text(
                    'Your Profile',
                    style: GoogleFonts.dmSans(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900,
                      color: AppColors.textTitle(isDark),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark ? AppColors.electricCyan : Colors.deepPurple[800],
                      size: 28,
                    ),
                    onPressed: () => ThemeProvider.toggleTheme(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              // Header Blob Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: AppColors.bgGradient(isDark),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(60),
                    bottomLeft: Radius.circular(50),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 15, offset: const Offset(5, 5)),
                  ],
                  border: Border.all(color: AppColors.borderMain(isDark), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C1B4D) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: isDark ? AppColors.neonPink.withOpacity(0.5) : Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: isDark ? const Color(0xFF0B0510) : const Color(0xFFF3E7E9),
                        child: Icon(Icons.person, size: 60, color: isDark ? AppColors.electricCyan : Colors.deepPurpleAccent),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      name,
                      style: GoogleFonts.pangolin(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain(isDark),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF200F3A).withOpacity(0.8) : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderMain(isDark), width: 1.5),
                      ),
                      child: Text(
                        'Role: $role',
                        style: GoogleFonts.pangolin(color: AppColors.textMain(isDark), fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Info List
              _buildInfoBlob(
                icon: Icons.badge,
                title: 'College ID',
                subtitle: userData['collegeId'] ?? 'N/A',
                isDark: isDark,
                index: 0,
              ),
              _buildInfoBlob(
                icon: Icons.meeting_room,
                title: 'Room Number',
                subtitle: userData['roomNumber'] ?? 'N/A',
                isDark: isDark,
                index: 1,
              ),
              if (role == 'User')
                _buildInfoBlob(
                  icon: Icons.card_membership,
                  title: 'Subscription',
                  subtitle: subText,
                  isDark: isDark,
                  index: 2,
                ),
              
              const SizedBox(height: 30),
              
              // Log Out Brutalist Blob Button
              GestureDetector(
                onTap: () async {
                  await AuthService().signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthWrapper()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButtonGradient(isDark),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: AppColors.textButton(isDark), size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Log Out',
                        style: GoogleFonts.pangolin(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textButton(isDark),
                        ),
                      ),
                    ],
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

  Widget _buildInfoBlob({required IconData icon, required String title, required String subtitle, required bool isDark, required int index}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: AppColors.blobGradient(isDark, index),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.borderMain(isDark), width: 2),
        boxShadow: [
          BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 8, offset: const Offset(3, 3)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF200F3A) : Colors.white.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isDark ? AppColors.electricCyan : Colors.deepPurpleAccent, size: 28),
        ),
        title: Text(title, style: GoogleFonts.pangolin(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textTitle(isDark))),
        subtitle: Text(subtitle, style: GoogleFonts.pangolin(fontSize: 16, color: AppColors.textSecondary(isDark))),
      ),
    );
  }
}
