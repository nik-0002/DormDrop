import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'user_dashboard.dart';
import 'delivery_dashboard.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import '../theme/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String role = widget.userData['role'] ?? 'Unknown Role';
    final bool isDark = AppColors.isDark(context);

    final List<Widget> pages = [
      role == 'User' 
          ? UserDashboard(userData: widget.userData)
          : DeliveryDashboard(userData: widget.userData),
      HistoryScreen(role: role),
      ProfileScreen(userData: widget.userData),
    ];

    return Scaffold(
      extendBody: true, // For bottom nav bar transparency effect
      body: Stack(
        children: [
          // Dynamic Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.bgGradient(isDark),
            ),
          ),
          
          // Cosmic dust / Floating shapes (Abstract)
          Positioned(
            top: 100,
            left: 20,
            child: Transform.rotate(
              angle: -math.pi / 8,
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: isDark ? AppColors.tangerine.withOpacity(0.15) : AppColors.navy.withOpacity(0.1), borderRadius: BorderRadius.circular(12))),
            ),
          ),
          Positioned(
            bottom: 300,
            right: 10,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(width: 60, height: 60, decoration: BoxDecoration(color: isDark ? AppColors.tangerine.withOpacity(0.1) : AppColors.navy.withOpacity(0.05), shape: BoxShape.circle)),
            ),
          ),

          // Floating playful icons
          Positioned(
            top: 250,
            right: 30,
            child: Transform.rotate(
              angle: math.pi / 12,
              child: Icon(Icons.rocket_launch, size: 70, color: isDark ? AppColors.tangerine.withOpacity(0.2) : AppColors.navy.withOpacity(0.1)),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 20,
            child: Transform.rotate(
              angle: -math.pi / 10,
              child: Icon(Icons.local_pizza, size: 80, color: isDark ? AppColors.tangerine.withOpacity(0.15) : AppColors.navy.withOpacity(0.1)),
            ),
          ),
          Positioned(
            top: 150,
            right: 120,
            child: Transform.rotate(
              angle: -math.pi / 15,
              child: Icon(Icons.menu_book, size: 60, color: isDark ? AppColors.tangerine.withOpacity(0.15) : AppColors.navy.withOpacity(0.1)),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 50,
            child: Transform.rotate(
              angle: math.pi / 6,
              child: Icon(Icons.directions_run_outlined, size: 90, color: isDark ? AppColors.tangerine.withOpacity(0.2) : AppColors.navy.withOpacity(0.1)),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                // DormDrop Title and Theme Toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Spacing for balance
                      Text(
                        'DormDrop',
                        style: GoogleFonts.righteous(
                          fontSize: 42,
                          color: AppColors.textTitle(isDark),
                          shadows: [
                            Shadow(offset: const Offset(3.0, 3.0), blurRadius: 10, color: AppColors.tangerine.withOpacity(0.5)),
                            Shadow(offset: const Offset(1.5, 1.5), blurRadius: 0, color: isDark ? Colors.black : Colors.white),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => ThemeProvider.toggleTheme(),
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: AppColors.tangerine,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Main Content Area
                Expanded(
                  child: pages[_currentIndex],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.glassHeaderColor(isDark),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: AppColors.borderMain(isDark),
            width: isDark ? 1.5 : 0.5,
          ),
          boxShadow: AppColors.glassmorphismShadow(isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: AppColors.tangerine,
              unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
              selectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.dmSans(),
              items: [
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 0
                          ? AppColors.tangerine.withOpacity(0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: _currentIndex == 0 ? AppColors.glassmorphismShadow(isDark) : [],
                    ),
                    child: const Icon(Icons.dashboard),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 1
                          ? AppColors.tangerine.withOpacity(0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: _currentIndex == 1 ? AppColors.glassmorphismShadow(isDark) : [],
                    ),
                    child: const Icon(Icons.history),
                  ),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentIndex == 2
                          ? AppColors.tangerine.withOpacity(0.15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      boxShadow: _currentIndex == 2 ? AppColors.glassmorphismShadow(isDark) : [],
                    ),
                    child: const Icon(Icons.person),
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
