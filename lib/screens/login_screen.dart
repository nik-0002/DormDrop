import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    UserCredential? userCredential = await _authService.signInWithGoogle();
    
    if (userCredential == null) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed or cancelled')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Background
          Container(
            decoration: BoxDecoration(
              gradient: isDark 
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B0510), Color(0xFF1A0B2E), Color(0xFF2C1B4D)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF), Color(0xFF90E0EF)],
                    stops: [0.1, 0.5, 0.9],
                  ),
            ),
          ),
          
          // Floating Decorative Icons
          Positioned(
            top: 150,
            left: 30,
            child: Transform.rotate(
              angle: -math.pi / 12,
              child: Icon(Icons.local_pizza, size: 80, color: isDark ? AppColors.neonPink.withOpacity(0.2) : Colors.white.withOpacity(0.4)),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 40,
            child: Transform.rotate(
              angle: math.pi / 8,
              child: Icon(Icons.inventory_2_outlined, size: 90, color: isDark ? AppColors.electricCyan.withOpacity(0.2) : Colors.white.withOpacity(0.4)),
            ),
          ),
          Positioned(
            top: 350,
            right: -20,
            child: Transform.rotate(
              angle: -math.pi / 6,
              child: Icon(Icons.directions_run_outlined, size: 120, color: isDark ? AppColors.neonPink.withOpacity(0.1) : Colors.white.withOpacity(0.3)),
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),
                  // App Name
                  Text(
                    'DormDrop',
                    style: GoogleFonts.righteous(
                      fontSize: 56,
                      color: AppColors.textTitle(isDark),
                      shadows: isDark
                        ? [
                            Shadow(offset: const Offset(4.0, 4.0), blurRadius: 15, color: AppColors.electricCyan),
                            const Shadow(offset: Offset(2.0, 2.0), blurRadius: 0, color: Colors.black),
                          ]
                        : [
                            const Shadow(offset: Offset(4.0, 4.0), blurRadius: 0, color: Colors.black),
                            const Shadow(offset: Offset(2.0, 2.0), blurRadius: 0, color: Colors.black),
                          ],
                    ),
                  ),
                  const Spacer(),
                  // Center of screen
                  _isLoading
                      ? CircularProgressIndicator(color: isDark ? AppColors.electricCyan : Colors.black)
                      : GestureDetector(
                          onTap: _handleGoogleSignIn,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.neonPink : const Color(0xFFE0FF4F),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? AppColors.electricCyan : Colors.black, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.brutalistShadow(isDark),
                                  offset: const Offset(6, 6),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black : Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.g_mobiledata, color: isDark ? Colors.white : Colors.black, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sign in with Google',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.black : Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
