import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/database_service.dart';
import '../theme/theme_provider.dart';
import 'routing_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isProcessing = false;

  void _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 2));

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _databaseService.updateSubscriptionStatus(currentUser.uid, true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Subscription Active.')),
        );
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoutingScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = AppColors.isDark(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: isDark ? AppColors.electricCyan : Colors.deepPurple, size: 30),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.bgGradient(isDark),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  'DormDrop',
                  style: GoogleFonts.righteous(
                    fontSize: 48,
                    color: AppColors.textTitle(isDark),
                    shadows: isDark 
                      ? [
                          Shadow(color: AppColors.electricCyan, offset: const Offset(3, 3), blurRadius: 10),
                          const Shadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
                        ]
                      : [
                          const Shadow(color: Colors.white, offset: Offset(3, 3), blurRadius: 0),
                          const Shadow(color: Colors.black, offset: Offset(5, 5), blurRadius: 0),
                        ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Subscription Blob
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: AppColors.blobGradient(isDark, 1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(60),
                    ),
                    border: Border.all(color: AppColors.borderMain(isDark), width: 3),
                    boxShadow: [
                      BoxShadow(color: AppColors.shadowMain(isDark), blurRadius: 15, offset: const Offset(5, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1A0B2E) : Colors.white.withOpacity(0.6),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: isDark ? AppColors.neonPink.withOpacity(0.5) : Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Icon(Icons.workspace_premium, size: 60, color: isDark ? AppColors.neonPink : Colors.deepPurpleAccent),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Activate Account',
                        style: GoogleFonts.pangolin(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain(isDark),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'To use DormDrop as a User, you need an active monthly subscription.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.pangolin(fontSize: 18, color: AppColors.textSecondary(isDark)),
                      ),
                      const SizedBox(height: 30),
                      
                      // Payment Neo-Brutalist Button
                      GestureDetector(
                        onTap: _isProcessing ? null : _handlePayment,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
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
                          child: _isProcessing
                              ? Center(
                                  child: SizedBox(
                                    height: 28,
                                    width: 28,
                                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.textButton(isDark)),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payment, color: AppColors.textButton(isDark), size: 28),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Pay ₹30 / Month',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
