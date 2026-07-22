import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';

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
          SnackBar(
            content: Text(
              'Sign in failed or cancelled',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFFFF3B30), // Sharp red for error
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);
    final Size size = MediaQuery.of(context).size;

    // --- COLOR PALETTE FROM APPCOLORS ---
    final Color bgColor = isDark ? AppColors.navyDarkest : const Color(0xFFF4F6F9);
    final Color primaryAccent = AppColors.tangerine;
    final Color secondaryAccent = isDark ? AppColors.navyLighter : const Color(0xFFFF9E00);
    final Color textColorPrimary = AppColors.textTitle(isDark);
    final Color textColorSecondary = AppColors.textSecondary(isDark);
    final Color cardColor = isDark ? AppColors.navyLighter : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // --- BACKGROUND GLOW EFFECTS ---
          Positioned(
            top: size.height * 0.05,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryAccent.withOpacity(isDark ? 0.25 : 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.15,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryAccent.withOpacity(isDark ? 0.2 : 0.15),
              ),
            ),
          ),

          // --- BLUR FILTER FOR GLASSMORPHISM ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Logo / Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryAccent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primaryAccent.withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fastfood_rounded, // Changed to a more generic food icon
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // App Name
                    Text(
                      'DormDrop',
                      style: GoogleFonts.poppins(
                        fontSize: 48,
                        fontWeight: FontWeight.w900, // Made bolder
                        letterSpacing: -1.5,
                        height: 1.1,
                        color: textColorPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      "Lazy and hungry?\nConsider it delivered.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColorSecondary,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 70),

                    // Google Sign In Button
                    _isLoading
                        ? Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              color: cardColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: primaryAccent,
                                strokeWidth: 3,
                              ),
                            ),
                          )
                        : BounceAnimation(
                            onTap: _handleGoogleSignIn,
                            child: Container(
                              width: double.infinity,
                              height: 64,
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16), // Less rounded, more modern tech feel
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.black.withOpacity(0.3)
                                        : Colors.black.withOpacity(0.05),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'G',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : AppColors.tangerine,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: textColorPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                    const SizedBox(height: 50),

                    // Trust / Terms of Service footer
                    Text(
                      'By continuing, you agree to our',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: textColorSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Terms of Service',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColorPrimary,
                          ),
                        ),
                        Text(
                          '  •  ',
                          style: TextStyle(color: textColorSecondary.withOpacity(0.5)),
                        ),
                        Text(
                          'Privacy Policy',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textColorPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGET FOR BUTTON TOUCH UX ---
class BounceAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceAnimation({super.key, required this.child, required this.onTap});

  @override
  State<BounceAnimation> createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<BounceAnimation> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    _scale = 1 - _controller.value;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}